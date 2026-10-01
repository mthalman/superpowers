# Azure Pipeline Monitor Commands

This reference covers full command examples, parameters, record-mode syntax, and detached-run guidance.

## Whole Run

```powershell
pwsh -NoProfile -File <skill>/scripts/Watch-AdoPipeline.ps1 `
  -BuildUrl 'https://dev.azure.com/dnceng/internal/_build/results?buildId=3003258' `
  1> result.json 2> watch.log
```

## Single Job Within the Run

```powershell
pwsh -NoProfile -File <skill>/scripts/Watch-AdoPipeline.ps1 `
  -BuildUrl 'https://dev.azure.com/dnceng/internal/_build/results?buildId=3003258' `
  -RecordName 'Windows_Pgo_x64' -RecordType Job `
  1> result.json 2> watch.log
```

## Separate Organization, Project, and Build Id

```powershell
pwsh -NoProfile -File <skill>/scripts/Watch-AdoPipeline.ps1 `
  -Organization 'dnceng' `
  -Project 'internal' `
  -BuildId 3003258 `
  1> result.json 2> watch.log
```

## Authentication with Explicit PAT

```powershell
pwsh -NoProfile -File <skill>/scripts/Watch-AdoPipeline.ps1 `
  -BuildUrl 'https://dev.azure.com/dnceng/internal/_build/results?buildId=3003258' `
  -Pat $env:AZURE_DEVOPS_PAT `
  1> result.json 2> watch.log
```

## Parameters

| Parameter | Use |
|---|---|
| `-BuildUrl` | Parse organization, project, and build id from a run URL. |
| `-Organization` | Organization name when not using `-BuildUrl`. |
| `-Project` | Project name when not using `-BuildUrl`. |
| `-BuildId` | Build/run id when not using `-BuildUrl`. |
| `-RecordName` | Stage, phase, job, or task name to monitor. |
| `-RecordType` | Optional disambiguator: `Stage`, `Phase`, `Job`, or `Task`. |
| `-Pat` | Explicit PAT. Overrides environment and Azure CLI auth. |
| `-TimeoutMinutes` | Safety timeout for the watcher. |
| `-MinIntervalSeconds` | Lower bound for adaptive polling interval. |
| `-MaxIntervalSeconds` | Upper bound for adaptive polling interval. |
| `-PollSeconds` | Force a fixed polling interval. |
| `-HistorySamples` | Number of past runs used for duration estimate. |

## Launch Shape

Run the watcher as a synchronous command with a modest `initial_wait` of about
30-60 seconds. This surfaces startup failures immediately. If the watcher is
still running after the initial wait, the runtime can background it and notify
when the process exits.

When the completion notification arrives, read `result.json` once and report the
outcome. The notification carries the exit status, so there is no reason to poll
the shell or read the progress log while you wait. `watch.log` is stderr
progress/debug output for post-mortems only.

## Detached Runs

For a pipeline so long that the session might shut down before it finishes, run
it fully detached so it survives. This severs the exit status from the launch, so
prefer the synchronous shape whenever the wait fits within the session.
