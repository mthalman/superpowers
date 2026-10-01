---
name: azure-pipeline-monitor
description: "Monitor an Azure DevOps (ADO) pipeline run to completion — the whole run or a single stage/job — using a blocking poller that estimates expected duration from past runs, adapts its polling cadence, holds control until a final outcome is reached, and returns a structured JSON result. Use this whenever the user wants to watch, wait on, track, poll, or be told the outcome of an ADO/Azure Pipelines build or release, asks 'tell me when this pipeline/job finishes', 'is this build done yet', 'wait for buildId NNN', or pastes a dev.azure.com/_build/results URL and wants its result. Prefer this over ad-hoc repeated status checks by the agent."
---

# Azure Pipeline Monitor

Watch an Azure DevOps pipeline run until it reaches a final outcome, then return
a structured result. The bundled script `scripts/Watch-AdoPipeline.ps1` performs
one blocking wait and returns one JSON answer. Use it instead of repeated agent
polling.

## When to Use This

Use when the user wants to know the final result of an Azure DevOps pipeline run,
asks you to wait for a build, cares about a specific stage or job, or pastes a
`dev.azure.com/.../_build/results?buildId=...` URL.

Whole-run vs. single-job is decided by context: if the user names a stage or
job, pass `-RecordName`; otherwise monitor the whole run.

## Prerequisites and Authentication

Requires PowerShell 7+ (`pwsh`).

Authentication resolves in this order:

1. `-Pat <token>` parameter, or `AZURE_DEVOPS_PAT`, `AZURE_DEVOPS_EXT_PAT`, or
   `SYSTEM_ACCESSTOKEN` environment variable as a Basic auth PAT.
2. Otherwise `az account get-access-token` from an authenticated `az login`
   session. The script auto-refreshes this token for multi-hour runs.

If neither is available, the script fails fast with guidance.

## Determine the Target

Establish these before launching:

1. **Organization, project, build id.** Prefer passing the whole run URL as
   `-BuildUrl`; the script parses `dev.azure.com/{org}/{project}` and
   `{org}.visualstudio.com/{project}` forms. Otherwise pass `-Organization`,
   `-Project`, and `-BuildId` separately.
2. **Scope.** Monitor the whole run by default. For one timeline record, pass
   `-RecordName` and optionally `-RecordType Stage|Phase|Job|Task` to
   disambiguate duplicate names.

If you cannot determine the build id or org/project from context, ask the user
rather than guessing.

## Single Blocking Invocation Rule

Launch `scripts/Watch-AdoPipeline.ps1` once as a synchronous command with a
modest `initial_wait` of about 30-60 seconds, redirecting stdout to a result JSON
file and stderr to a progress log. If startup is invalid, it exits within that
initial wait. If the build is still running, the runtime can background the
process and notify you on completion.

Open `references/commands.md` when you need full command examples, parameters,
record-mode syntax, or detached-run guidance.

Do not tail the progress log while waiting. Read the result JSON once after the
completion notification and report the outcome.

## Polling Cadence and Timeout

The script estimates duration from past runs, polls slowly early, polls faster
near the expected finish, and uses a floor interval once overdue. It falls back
to fixed cadence when no history exists.

Open `references/output-fields.md` when you need the full output field table,
polling knobs, or timeout tuning details.

## Output Contract

The script writes one JSON object to stdout. Report `result` and link `url`.
When the run did not cleanly succeed, surface the relevant list:

- `failures` for `failed` or `canceled` runs.
- `issues` for `partiallySucceeded` or `succeededWithIssues` runs.

Include whether the watcher timed out. A `timedOut` result is not a pipeline
failure; it means the watcher gave up waiting.

## Interpreting Results

- `succeeded`: report success.
- `succeededWithIssues` or `partiallySucceeded`: do not call this failed. Report
  it as partial and use `issues` to identify affected jobs or tasks.
- `failed` or `canceled`: surface `failures` so the user knows which jobs or
  tasks broke.
- `timedOut`: explain that the watcher timed out before completion and consider
  re-running with a larger `-TimeoutMinutes`.
- In record mode, `failures` and `issues` are scoped to descendants under the
  selected stage, phase, job, or task.

## Anti-Patterns

- Do not poll the pipeline yourself in a loop of agent tool calls.
- Do not tail `watch.log` or stderr while waiting.
- Do not default to detached background launch; reserve it for runs likely to
  outlive the session.
- Do not treat `succeededWithIssues` or `partiallySucceeded` as failure.
- Do not invent a build id, organization, or project.
- Do not add `&view=results` parsing logic; pass the raw URL and let the script
  handle query strings.
