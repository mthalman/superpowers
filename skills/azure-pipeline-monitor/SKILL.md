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

## Running it (do this in the background)

Because the script blocks until the run finishes, launch it as a **background /
detached process with a long initial wait** and let the completion notification tell
you when it's done — don't sit in a foreground call for hours, and don't re-implement
polling yourself. Capture stdout (the JSON result) to a file; progress goes to stderr.

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

When the process completes, read `result.json` and report the outcome to the user.

## How the cadence adapts

The script samples up to `-HistorySamples` (default 10) past **completed** runs of the
same pipeline definition to estimate a median duration — deliberately including
canceled/failed runs because some definitions rarely produce a clean `succeeded`, and a
rough estimate is enough. For a single record it samples those past runs' timelines for
the same record name.

The poll interval is then `clamp(timeRemainingToExpectedFinish / 5, MinInterval,
MaxInterval)`:

- Far from the expected finish → polls slowly (caps at `MaxInterval`).
- Approaching the expected finish → polls progressively faster.
- Past the estimate or already overdue → polls at `MinInterval` (default 15s).

`MaxInterval` is **auto-scaled to the estimate** by default: `expected / 10`, clamped to
120s–600s. So a 10-minute job keeps a tight 120s ceiling and stays responsive, while a
3-hour run is allowed an ~18-minute ceiling and isn't polled excessively early on. The
ceiling exists mainly to bound how late a finish is noticed when the estimate runs
*high* — scaling it keeps that worst-case latency proportional to the run's length.

This keeps API traffic low early and responsiveness high near the end, and it degrades
gracefully when the estimate is wrong: an underestimate just means frequent polling
sooner; an overestimate means slower early polling. When no history exists, it waits at a
120s ceiling until the target nears completion. Override with `-MinIntervalSeconds`, a
fixed `-MaxIntervalSeconds` (disables the auto-scaling), or force a single fixed interval
with `-PollSeconds`.

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
| `timedOut` | `true` if the safety timeout was hit before completion |
| `url` | Link back to the run |

Report `result` (and `failures` when it didn't succeed) to the user, and link `url`.

A safety timeout (default `max(2× expected, 60)` minutes, capped at 600) prevents an
unbounded wait; raise it with `-TimeoutMinutes` for very long pipelines. A `timedOut`
result is not a pipeline failure — it means the watcher gave up waiting, so consider
re-running with a larger `-TimeoutMinutes`.

## Interpreting results

- `succeededWithIssues` and `partiallySucceeded` are **not** outright failures; report
  them as such rather than calling the run "failed".
- When `result` is `failed`/`canceled`, surface the `failures` list so the user knows
  which jobs/tasks broke without opening the portal.
- For record mode, `failures` lists failed descendants **under that record**, so it's
  scoped to the job/stage the user cared about.

## Anti-patterns

- **Don't poll the pipeline yourself in a loop of agent tool calls.** Hand control to
  the script — that's the entire point. One launch, one JSON answer.
- **Don't run it in a blocking foreground call for a long pipeline.** Background/detach
  it and wait for the completion notification.
- **Don't treat `succeededWithIssues`/`partiallySucceeded` as failure.**
- **Don't invent a build id or org/project.** Parse them from the URL or ask.
- **Don't add `&view=results` parsing logic** — pass the raw URL; the script handles
  query strings.
