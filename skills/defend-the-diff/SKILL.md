---
name: defend-the-diff
description: Interrogate an existing code change through focused questions, evidence-backed answers, and independent judgment so the change is explainable, correct, justified, and defensible. Invoke explicitly when a user asks to defend a diff, justify code changes, run an explainability review, or challenge whether maintainers can understand a change without adding tutorial-style comments.
disable-model-invocation: true
---
# Defend the Diff

Test whether an existing change can withstand informed scrutiny. A defensible
change matches its stated purpose, has rationale supported by evidence, and has
enough durable explanation for a competent maintainer. It need not teach the
subsystem to a beginner.

This is a question-driven explainability and justification review, not a
replacement for `code-review`. Trace downstream impact when a unit changes a
contract or shared behavior. If current source does not establish historical
motivation, inspect history and record `unknown` when evidence remains
insufficient.

Use three isolated role contexts: a questioner identifies material questions, a
defender answers with repository evidence and self-assessment, and an
independent judge verifies answers and changed behavior. Agents remain read-only.
Do not edit until the user approves a proposal. Do not simulate all roles in one
context. If isolated contexts are unavailable, report `BLOCKED`.

## Role briefs and references

Open `references/questioner.md` when dispatching the questioner or its second
pass. Open `references/defender.md` when dispatching the defender or requesting
revisions. Open `references/judge.md` when dispatching the judge or verifying
revisions. Open `references/coordinator-details.md` when you need detailed
continuity, remedy, iteration, and report-template guidance.

## Agent continuity

Prefer persistent isolated contexts for each role. Retain context identifiers
and continue them for follow-ups. If isolated agents are only one-shot, launch a
fresh isolated replacement with the role's original brief and complete
accumulated packet. This fallback is supported, not blocked; disclose lost
continuity. Report `BLOCKED` only when isolated role contexts are unavailable.

## Inputs

Establish change scope, user-specified semantic units, original prompt, explicit
review directions, local instructions, relevant diff, and surrounding code,
tests, and documentation. If scope cannot be inferred safely, ask before
dispatching agents.

## Workflow

### 1. Build a change inventory

Start with semantic units explicitly identified by the user. Preserve their
boundaries and wording unless a unit combines unrelated decisions; then retain it
as a parent and split labeled subunits. Inventory the rest of the diff as `C1`,
`C2`, and so on. A unit is one behavior, contract, invariant, data-flow change,
or tightly coupled implementation decision. Do not equate files or hunks with
semantic units.

For each unit record origin, paths/symbols, old/new behavior, stated purpose,
governing callers/tests/docs/contracts, and whether it needs questioning. Assess
every unit. Question hidden rationale, surprising implementation, implicit
contracts, boundary cases, and user-directed concerns. Mark obvious units
`clear from code` with a reason. Group or exclude formatting, generated,
vendored, and mechanical changes only when the exclusion is recorded.

### 2. Dispatch the questioner

Use `references/questioner.md` as the complete role brief. Provide prompt,
directions, inventory, diff, immediate code context, and repository conventions.
Do not provide author's rationale or future defender research. Require every
unit to be covered by material questions or `clear from code`. A unit may
produce multiple independently tracked questions. Reject quiz questions,
tutorial requests, style preferences, and questions answered by ordinary code
reading.

### 3. Dispatch the defender

Use `references/defender.md` as the complete role brief. Provide the same scope,
prompt, inventory, diff, every question, and access to surrounding code, tests,
history, and authorized docs. Require direct answers with cited evidence,
fact/inference separation, and defender self-assessment. If repository evidence
cannot establish a claim, answer `unknown`. If there are no material questions,
skip the defender for now and send the coverage packet to the judge.

### 4. Dispatch the independent judge

Use `references/judge.md` as the complete role brief. Provide the complete
packet: scope, prompt, inventory, diff, questions, `clear from code` decisions,
answers, self-assessments, and repository access. The judge audits inventory and
question coverage before grading. If it finds an omitted unit or material
question marked clear, add the question, return it to the defender, and have the
judge assess the answer. The judge verifies material claims against evidence.

### 5. Return answers to the questioner

Continue the questioner context, or use the one-shot fallback with the full
packet. The questioner classifies every defender answer as resolved, partially
resolved, unresolved, over-explained, or withdrawn. This second pass judges
explainability; runtime correctness belongs to the judge.

### 6. Reconcile the panel

Build a ledger per question: ID, unit, defender answer and self-assessment,
questioner judgment, judge judgment, evidence, and coordinator disposition.
Dispositions are `accepted`, `clarify response`, `change proposed`, `blocked`,
and `not required`. Agreement is not proof; resolve contradictions with cited
evidence. Return every `clarify response` to the defender, then have questioner
and judge reassess. If a material gap remains, convert it to `change proposed`
or `blocked`.

### 7. Choose the right remedy

Prefer durable remedies: simplify/remove code; encode constraints in structure,
naming, types, assertions, or tests; update public or architectural docs; add a
concise comment only when important rationale cannot be expressed reliably in
code; or make no change for ordinary subsystem knowledge. Use `code-commenting`
for inline or doc comment proposals.

### 8. Request approval and iterate

Present exact proposed changes with locations, evidence, and why each is the
smallest durable remedy. Explicitly ask for approval before editing. After
approval, apply only approved edits, run the smallest covering validation,
rebuild affected units, rerun the full panel for affected units and changed
explanations/behavior, and update the ledger.

Claim defensible only when semantic-unit coverage is complete and every material
question is `accepted` or `not required`.

## Report

```markdown
## Scope
<Change range, prompt directions, and exclusions>

## Change coverage
| Unit | Origin | Behavior or decision | Coverage |
|---|---|---|---|
| C1 | user-specified / coordinator-derived | ... | questioned / clear from code / excluded |

## Question ledger
| ID | Unit | Question | Defender | Questioner | Judge | Evidence | Disposition |
|---|---|---|---|---|---|---|---|

## Proposed changes
1. <Location, exact remedy, evidence, and why this remedy is appropriate>

## Final status
DEFENSIBLE | CHANGES PROPOSED | BLOCKED

<Short rationale and remaining uncertainty>
```

Omit **Proposed changes** when no change is warranted. The report must cover all
semantic units, preserve user-specified unit boundaries, include defender
self-assessments, questioner second-pass classifications, judge verdicts,
propose rather than apply changes, and request approval before editing.
