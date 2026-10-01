# Azure Pipeline Monitor Output Fields

This reference covers the JSON output fields, adaptive polling controls, and timeout tuning.

## Output Fields

The script writes one JSON object to stdout.

| Field | Meaning |
|---|---|
| `kind` | `build` for a whole run or `record` for a single stage/job/task. |
| `status` | Final state, for example `completed`. `unknown` or `inProgress` appears only if it timed out. |
| `result` | `succeeded`, `succeededWithIssues`, `failed`, `canceled`, `partiallySucceeded`, or `null` if not finished. |
| `startTime` | Actual start time of the monitored target. |
| `finishTime` | Actual finish time of the monitored target. |
| `durationMinutes` | Actual duration of the monitored target. |
| `expectedDurationMinutes` | Duration estimate used by the watcher. |
| `estimateSamples` | Number of past samples behind the estimate. |
| `failures` | Failed or canceled leaf records for quick diagnosis. |
| `failureCount` | Count of failed or canceled leaf records. |
| `issues` | Leaf records that finished `partiallySucceeded` or `succeededWithIssues`. |
| `issueCount` | Count of issue records. |
| `timedOut` | `true` if the safety timeout was hit before completion. |
| `url` | Link back to the run. |

Report `result` and link `url`. When it did not cleanly succeed, surface
`failures` for `failed` or `canceled`, and `issues` for `partiallySucceeded` or
`succeededWithIssues`.

## Polling Cadence

The script handles polling itself: it estimates the run's duration from past
runs of the same pipeline, polls slowly early on, polls faster as the expected
finish nears, and uses a floor interval once overdue. The default floor is 15
seconds. It degrades gracefully when the estimate is wrong and falls back to a
fixed cadence when no history exists.

Tuning knobs:

- `-MinIntervalSeconds` bounds the lower polling interval.
- `-MaxIntervalSeconds` bounds the upper polling interval.
- `-PollSeconds` forces one fixed interval.
- `-HistorySamples` controls how many past runs feed the estimate.

## Timeout Tuning

A safety timeout prevents an unbounded wait. The default is `max(2× expected,
60)` minutes, capped at 600. Raise it with `-TimeoutMinutes` for very long
pipelines.

A `timedOut` result is not a pipeline failure. It means the watcher stopped
waiting before the target reached a final state. Consider re-running with a
larger `-TimeoutMinutes` when the user still wants the final result.
