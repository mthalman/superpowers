---
name: show-me-your-work
description: Keep a compact, reviewable decision trail for long-running, multi-phase, experimental, or unattended work. Use only when the user explicitly asks to show the work, keep a decision log, or produce an audit trail. Do not invoke automatically for routine or complex tasks.
disable-model-invocation: true
compatibility: Requires PowerShell 7 or later for the bundled logging helper.
---

# Show Me Your Work

Keep one append-only decision log for work whose history matters. The log lets a
reviewer understand consequential choices without reading the full transcript
or rerunning the task.

## Decide whether a log is warranted

Use a log for:

- long-running or unattended work;
- repeated experiments;
- migrations with several workstreams;
- many delegated units;
- explicit requests for an audit trail.

Do not log routine file reads, formatting, or obvious implementation steps.

## Storage

Prefer the host's persistent session-artifacts directory. If the host does not
provide one, use a location outside the repository.

If the host restricts writes to the workspace and exposes no persistent
artifact storage, ask the user for a durable path before starting the log. Do
not substitute an in-memory trail for the promised append-only artifact.

Do not add or commit a decision log to the repository unless the user asks for
it as a deliverable. If the user requests a repository-local working log,
verify its exact path is ignored before writing. Never commit it without
explicit approval.

## Format

Use one TSV row per decision or checkpoint:

| Column | Meaning |
|---|---|
| `ts` | UTC ISO 8601 timestamp |
| `phase` | Phase or workstream |
| `decision` | Concrete action or choice |
| `why` | Plain-language reason |
| `evidence` | Resolvable path, URL, command result, or artifact |
| `result` | Verified outcome, `open`, `reverted`, or `inconclusive` |

Keep every cell on one line. Evidence is a pointer, not a paragraph.

Resolve this skill's installed directory, then use its bundled
`scripts/Add-DecisionLogEntry.ps1` to create the header and append normalized
rows. Do not resolve the script relative to the user's working directory.

```powershell
$logger = Join-Path <skill-root> 'scripts' 'Add-DecisionLogEntry.ps1'
pwsh -File $logger `
  -Path <log-path> `
  -Phase <phase> `
  -Decision <decision> `
  -Why <reason> `
  -Evidence <path-or-reference> `
  -Result <result>
```

The helper neutralizes spreadsheet formulas in user-generated cells.

## Logging rules

- Log decision points, pivots, reverts, blockers, completed units, and quality
  gates.
- Keep the log append-only. Add a superseding row when an earlier decision is
  wrong.
- Record failed attempts when they changed the direction of the work.
- Point to reproducible evidence when possible.
- Use `inconclusive` when evidence does not establish an outcome.
- Never invent a tidy history after the work is complete.

## Audit before handoff

Before presenting the trail:

1. Confirm every row maps to a real action.
2. Resolve every evidence pointer that should still exist.
3. Add consequential pivots or abandoned approaches that are missing.
4. Remove padding that does not help a reviewer.
5. Preserve unresolved questions as unresolved.

If the host exposes session events, compare the log with the current session
only. Do not search unrelated sessions or workspaces. If no session evidence is
available, say that transcript reconciliation was unavailable.

When the host supports independent read-only review, an optional reviewer may
inspect the trail for high-risk work. Do not require a different model or treat
reviewer agreement as proof.

## Report

Return:

- the log path;
- phases covered;
- open or inconclusive decisions;
- evidence gaps;
- any rows the reviewer should inspect first.
