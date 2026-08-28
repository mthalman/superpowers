---
name: defend-the-diff
description: Interrogate an existing code change through focused questions, evidence-backed answers, and independent judgment so the change is explainable, correct, justified, and defensible. Invoke explicitly when a user asks to defend a diff, justify code changes, run an explainability review, or challenge whether maintainers can understand a change without adding tutorial-style comments.
disable-model-invocation: true
---

# Defend the Diff

Test whether a change can withstand informed scrutiny. A defensible change has
behavior that matches its stated purpose, rationale supported by evidence, and
enough durable explanation for a competent maintainer. It does not need to
teach the subsystem to a beginner.

Use three isolated agents:

1. a questioner identifies material questions;
2. a change defender answers with repository evidence and evaluates its own
   answers;
3. an independent judge verifies the answers and the changed behavior.

The coordinator inventories the change, routes the exchange, reconciles the
judgments, and proposes improvements. Agents remain read-only. Do not edit the
change until the user approves a proposal.

This is a question-driven explainability and justification review, not a
replacement for `code-review`'s broad defect search. Trace downstream impact
when a unit changes a contract or shared behavior. When current source does not
establish historical motivation, inspect repository history and record the
answer as unknown if the available evidence remains insufficient.

If the host cannot provide isolated agent contexts, report `BLOCKED`. Do not
simulate all roles in one context because independence is part of the evidence.

### Agent continuity

Each panel role may receive a later follow-up: the questioner assesses answers,
the defender may revise or answer coverage gaps, and the judge may verify those
revisions. Create each role in the host's persistent or multi-turn agent mode.
Retain the role's context identifier and use the host's continuation mechanism
for follow-up turns. Do not choose a one-shot execution mode for a role when a
persistent mode is available.

If the host provides isolated agents but only as one-shot contexts, launch a
replacement for each follow-up with that role's original brief and the complete
accumulated packet. This is a supported fallback, not a blocked review. Disclose
which roles lost continuity. Report `BLOCKED` only when isolated contexts are
unavailable.

## Inputs

Establish:

- the change scope: working tree, commit, range, pull request, or named paths;
- any semantic change units explicitly identified by the user;
- the original user prompt and any explicit review directions;
- the repository's local instructions;
- the relevant diff and surrounding implementation, tests, and documentation.

If the scope cannot be inferred safely, ask for it before dispatching agents.

## 1. Build a change inventory

Start with any semantic change units explicitly identified by the user. Preserve
their stated boundaries and wording unless a unit combines unrelated decisions;
if it does, retain the user-specified unit as a parent and split it into labeled
subunits. Then divide any uncovered part of the diff into additional semantic
change units, labeled `C1`, `C2`, and so on. A unit is one behavior, contract,
invariant, data-flow change, or tightly coupled implementation decision. Do not
equate files or hunks with semantic units.

Record which units were user-specified and which were coordinator-derived. A
user-specified unit controls review emphasis, not coverage: still inventory the
rest of the diff, and do not silently expand or narrow the requested unit.

For each unit record:

- paths and symbols;
- old and new behavior;
- stated purpose or prompt requirement;
- callers, tests, documentation, or contracts likely to govern it;
- whether it needs questioning.

Assess every unit. Question a unit when understanding it depends on hidden
rationale, a surprising implementation, an implicit contract, a boundary case,
or a direction called out by the user. Mark an obvious unit `clear from code`
with a short reason instead of manufacturing a question.

Formatting-only edits, generated artifacts, vendored code, and mechanical
renames may be grouped or excluded, but record the exclusion. A dependency,
schema, generated-source, or lockfile change is relevant when it changes
behavior or compatibility.

## 2. Dispatch the questioner

Read `references/questioner.md` and use it as the complete role brief for an
isolated general-purpose agent. Follow **Agent continuity** because the
questioner has a second-pass role in step 5.

Give the questioner:

- the original prompt and explicit review directions;
- the semantic change inventory;
- the diff and access to the changed code's immediate context;
- repository conventions needed to act like an engineer familiar with the
  repository but new to this subsystem.

Do not give it the author's rationale, historical explanation, or the
defender's future research. Preserving that information gap prevents the
questioner from adopting unsupported explanations before examining the change.

Require coverage of every change unit as either one or more material questions
or `clear from code`. Do not cap questions per unit: ask separate questions for
distinct material gaps rather than combining unrelated rationale, contract, and
boundary concerns into one prompt. Reject quiz questions, requests for general
subsystem tutorials, style preferences, and questions already answered directly
by ordinary code reading.

## 3. Dispatch the defender

Read `references/defender.md` and use it as the complete role brief for a
second isolated general-purpose agent. Follow **Agent continuity** because the
defender may need to answer coverage gaps or revise an explanation.

Give the defender:

- the same scope, prompt, inventory, and diff;
- every questioner question;
- access to surrounding code, tests, history, and authorized documentation.

Require a direct answer to every question. Each answer must cite evidence,
distinguish fact from inference, and include the defender's self-assessment.
Polished intent is not evidence. If the repository cannot establish a claim,
the answer must say `unknown` rather than inventing a rationale.

If the questioner found no material questions, skip the defender for now and send
the coverage packet directly to the independent judge.

## 4. Dispatch the independent judge

Read `references/judge.md` and use it as the complete role brief for a third
isolated general-purpose agent. Follow **Agent continuity** because the judge
may need to assess additional or revised answers.

Give the judge the complete review packet: scope, prompt, inventory, diff,
questions, `clear from code` decisions, answers, self-assessments, and access to
the repository. Keep the judge independent from the defender.

Require the judge to audit the inventory and question coverage before grading
answers. If it identifies an omitted semantic unit or a material question
incorrectly marked clear, add that question to the ledger, return it to the
defender, and have the judge assess the resulting answer. Then verify every
material claim against source, tests, history, or documentation rather than
scoring rhetoric.

## 5. Return answers to the questioner

Continue the original questioner context with the defender's answers using the
host's continuation mechanism.

If the host has isolated agents but no persistent mode, use two one-shot
questioner contexts: launch a replacement for the second pass with the original
questioner brief, original packet, first-pass questions, and defender answers.
Disclose in the report that questioner continuity was unavailable.

The questioner judges whether a competent repository engineer can rely on each
answer:

- Does the answer resolve the actual question?
- Can the engineer now form an accurate maintenance model?
- Is any essential rationale still hidden?
- Would the proposed explanation demand inappropriate handholding?

The questioner does not independently certify runtime correctness; that belongs
to the independent judge.

## 6. Reconcile the panel

Build a ledger with one row per question:

- question ID and change unit;
- defender answer and self-assessment;
- questioner judgment;
- independent judgment;
- evidence;
- coordinator disposition.

Use these dispositions:

- `accepted`: evidence supports the answer and a maintainer can understand the
  change;
- `clarify response`: the code is defensible but the answer was incomplete;
- `change proposed`: code, tests, comments, or documentation should change;
- `blocked`: a material claim cannot be verified with available evidence;
- `not required`: the question asks for tutorial material or knowledge a
  competent repository engineer is expected to have.

Agreement is not proof. Resolve contradictions by checking the cited evidence.
Do not average incompatible judgments or treat confidence as correctness.

Return every `clarify response` disposition to the defender for a revised
answer, then have both the questioner and independent judge assess it again. If a
material gap remains after revision, convert the disposition to `change
proposed` or `blocked`; do not leave it in an intermediate state.

## 7. Choose the right remedy

When a gap is real, prefer the most durable remedy:

1. simplify or remove unnecessary code;
2. encode the constraint in structure, naming, types, assertions, or tests;
3. update public or architectural documentation when the contract extends
   beyond the local implementation;
4. add or revise a concise comment only when important rationale cannot be
   expressed reliably in code;
5. make no change when the requested explanation is ordinary subsystem
   knowledge or tutorial material.

Use `code-commenting` for any inline comment or doc comment proposal. Follow the
repository's existing documentation conventions for standalone documentation
proposals.

Do not add narration, line-by-line explanations, speculative rationale,
defensive essays, or comments that will drift away from enforceable behavior.
Do not refactor merely because the questioner prefers a different style.

## 8. Request approval and iterate

Present the exact proposed changes with locations, evidence, and why each is
the smallest durable remedy. Explicitly ask the user to approve or reject the
proposal before editing.

After approved changes:

1. apply only the approved edits;
2. run the smallest existing validation that covers them;
3. rebuild the affected change units;
4. rerun the full panel for affected units and any units whose explanation or
   behavior changed;
5. update the ledger and final status.

Claim the change is defensible only when coverage is complete and every
material question is `accepted` or `not required`.

## Report

Use this structure:

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

Omit **Proposed changes** when no change is warranted. Keep full evidence in
the ledger, but make the final status concise.
