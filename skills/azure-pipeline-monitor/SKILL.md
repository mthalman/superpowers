---
name: azure-pipeline-monitor
description: "Monitor an Azure DevOps (ADO) pipeline run to completion — the whole run or a single stage/job — using a blocking poller that estimates expected duration from past runs, adapts its polling cadence, holds control until a final outcome is reached, and returns a structured JSON result. Use this whenever the user wants to watch, wait on, track, poll, or be told the outcome of an ADO/Azure Pipelines build or release, asks 'tell me when this pipeline/job finishes', 'is this build done yet', 'wait for buildId NNN', or pastes a dev.azure.com/_build/results URL and wants its result. Prefer this over ad-hoc repeated status checks by the agent."
---

# Azure Pipeline Monitor

Watch an Azure DevOps pipeline run until it reaches a final outcome, then return a
structured result. The work is done by a single blocking PowerShell script,
`scripts/Watch-AdoPipeline.ps1`, which **keeps control until the outcome is known** so
the agent does not have to poll repeatedly. This matters because manual agent-driven
polling wastes turns, drifts in timing, and loses context across long waits — a build
can run for hours. The script instead sleeps efficiently inside one process and hands
back a single JSON answer.

## When to use this

- The user wants to know the final result of a pipeline run ("did it pass?", "tell me
  when it's done", "wait for this build").
- The user cares about one specific stage or job inside a larger run rather than the
  whole thing (e.g. just the `Windows_Pgo_x64` job).
- The user pastes a `dev.azure.com/.../_build/results?buildId=...` URL.

Whole-run vs. single-job is decided by **context**: if the user names a stage/job, pass
`-RecordName`; otherwise monitor the whole run.

## Prerequisites

- **PowerShell 7+ (`pwsh`)** — the script is cross-platform.
- **Authentication**, resolved in this order:
  1. `-Pat <token>` parameter, or env var `AZURE_DEVOPS_PAT` / `AZURE_DEVOPS_EXT_PAT` /
     `SYSTEM_ACCESSTOKEN` (used as a Basic auth PAT).
  2. Otherwise an `az account get-access-token` Bearer token — so an authenticated
     `az login` session just works. The script auto-refreshes this token, which is
     essential for multi-hour runs.

If neither is available the script fails fast with guidance.

## Determining the target

From the user's context, establish:

1. **Organization, project, build id** — easiest via the run URL. Pass the whole URL as
   `-BuildUrl` and the script parses all three. Both `dev.azure.com/{org}/{project}` and
   `{org}.visualstudio.com/{project}` forms are supported. Alternatively pass
   `-Organization`, `-Project`, and `-BuildId` separately.
2. **Scope** — whole run (default) or a single timeline record via `-RecordName`
   (optionally `-RecordType Stage|Phase|Job|Task` to disambiguate duplicate names).

If you cannot determine the build id or org/project from context, ask the user rather
than guessing.

## Running it (launch once, then wait for the notification)

The script blocks until the run finishes, so the goal is to launch it **once** and then
stop — let the runtime tell you when it's done rather than watching it.

Run it as a **synchronous command with a modest `initial_wait` (about 30–60s)**, capturing
stdout (the JSON result) to a file. This launch shape does exactly what you want with no
babysitting:

- If something is wrong at startup (bad auth, unknown build, malformed URL) the script
  exits non-zero **within** that initial wait, so you see the failure immediately.
- If it's still running when the wait elapses, the runtime **auto-backgrounds it and
  sends a completion notification** when it finishes. That notification carries the exit
  status — everything you need — so there is no reason to poll the shell or read the
  progress log while you wait.

```powershell
# Whole run
pwsh -NoProfile -File <skill>/scripts/Watch-AdoPipeline.ps1 `
  -BuildUrl 'https://dev.azure.com/dnceng/internal/_build/results?buildId=3003258' `
  1> result.json 2> watch.log
```

```powershell
# A single job within the run
pwsh -NoProfile -File <skill>/scripts/Watch-AdoPipeline.ps1 `
  -BuildUrl 'https://dev.azure.com/dnceng/internal/_build/results?buildId=3003258' `
  -RecordName 'Windows_Pgo_x64' -RecordType Job `
  1> result.json 2> watch.log
```

When the completion notification arrives, read `result.json` **once** and report the
outcome. The `watch.log` (stderr) is progress/debug output for post-mortems only — don't
tail it while waiting; it tells you nothing the notification and `result.json` won't.

For a pipeline so long that the session might be shut down before it finishes, run it
fully detached instead so it survives — but that severs the exit status from the launch,
so prefer the synchronous shape above whenever the wait fits within the session.

## Polling cadence

The script handles polling itself — estimating the run's duration from past runs of the
same pipeline and polling slowly early on, faster as the expected finish nears, and at a
floor (default 15s) once it's overdue. It degrades gracefully when the estimate is wrong
and falls back to a fixed cadence when no history exists, so you don't need to pick
timings. Just launch it and trust it.

You rarely need to tune this, but the knobs are there if you do: `-MinIntervalSeconds`
and `-MaxIntervalSeconds` bound the interval, `-PollSeconds` forces a single fixed
interval, and `-HistorySamples` controls how many past runs feed the estimate.

## Output

The script writes one JSON object to **stdout**. Key fields:

| Field | Meaning |
|---|---|
| `kind` | `build` (whole run) or `record` (single stage/job) |
| `status` | Final state, e.g. `completed`. `unknown`/`inProgress` only if it timed out. |
| `result` | `succeeded`, `succeededWithIssues`, `failed`, `canceled`, `partiallySucceeded`, or `null` if not finished |
| `startTime` / `finishTime` / `durationMinutes` | Actual timing of the target |
| `expectedDurationMinutes` / `estimateSamples` | The estimate used and how many past samples it came from |
| `failures` / `failureCount` | Failed/canceled leaf records (jobs/tasks) for quick diagnosis |
| `issues` / `issueCount` | Leaf records that finished `partiallySucceeded`/`succeededWithIssues` — these explain *why* an overall result is partial without being outright failures |
| `timedOut` | `true` if the safety timeout was hit before completion |
| `url` | Link back to the run |

Report `result` to the user and link `url`. When it didn't cleanly succeed, surface the
relevant list: `failures` for a `failed`/`canceled` run, or `issues` for a
`partiallySucceeded`/`succeededWithIssues` run.

A safety timeout (default `max(2× expected, 60)` minutes, capped at 600) prevents an
unbounded wait; raise it with `-TimeoutMinutes` for very long pipelines. A `timedOut`
result is not a pipeline failure — it means the watcher gave up waiting, so consider
re-running with a larger `-TimeoutMinutes`.

## Interpreting results

- `succeededWithIssues` and `partiallySucceeded` are **not** outright failures; report
  them as such rather than calling the run "failed". Consult the `issues` list to tell the
  user *which* job(s) had problems — a partial result with an empty `failures` list is
  expected, and `issues` is where the explanation lives.
- When `result` is `failed`/`canceled`, surface the `failures` list so the user knows
  which jobs/tasks broke without opening the portal.
- For record mode, `failures` and `issues` list descendants **under that record**, so
  they're scoped to the job/stage the user cared about.

## Anti-patterns

- **Don't poll the pipeline yourself in a loop of agent tool calls.** Hand control to
  the script — that's the entire point. One launch, one JSON answer.
- **Don't tail the progress log (`watch.log` / stderr) while waiting.** It's debug output
  for post-mortems; it carries nothing the completion notification and `result.json`
  won't give you. Launch once, then wait quietly for the notification.
- **Don't default to a detached background launch.** Prefer the synchronous launch with a
  modest `initial_wait` — startup errors surface immediately and the runtime still
  notifies you on completion. Reserve full detach for runs long enough to outlive the
  session.
- **Don't treat `succeededWithIssues`/`partiallySucceeded` as failure.**
- **Don't invent a build id or org/project.** Parse them from the URL or ask.
- **Don't add `&view=results` parsing logic** — pass the raw URL; the script handles
  query strings.
