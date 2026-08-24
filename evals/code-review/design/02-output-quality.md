# Dimension 2 — Severity & Output Quality

> **Question:** Are reviews well-formed, severities calibrated, and verdicts
> consistent with the findings?

This dimension is **about the artifact**, not whether the review is right.
A review can detect every bug and still violate format rules; another can
miss bugs but be perfectly structured. We measure each independently.

**v1 status:** Severity scoring is implemented as part of the detection
harness (see `01-detection-quality.md` § Severity calibration). Other checks
are designed here; no separate harness yet.

## Checks

### 1. Format conformance (hard fail)

Parse the review and verify the structure required by `SKILL.md` § Review
Output Format:

- Title `## 🤖 Code Review` present.
- `### Holistic Assessment` section present.
- `**Motivation**`, `**Approach**`, `**Summary**` lines present.
- Summary line begins with one of: `✅ LGTM`, `⚠️ Needs Human Review`,
  `⚠️ Needs Changes`, `❌ Reject`, `⏸️ Review Incomplete` (or clear text
  `Review Incomplete` fallback).
- `### Detailed Findings` section present (may be empty if LGTM or Review
  Incomplete).
- Each finding starts with `#### ` then one of `❌`, `⚠️`, `💡`.

A review that cannot be parsed is itself a failure — log as `unparseable`.

### 2. Verdict-vs-severity consistency (hard fail)

Rules from `SKILL.md` § Verdict Rules:

| Violation | Rule |
|-----------|------|
| `LGTM` with any `⚠️` or `❌` finding | Verdict cannot be LGTM if any non-suggestion findings exist. |
| `Needs Changes` with **only** `💡` findings | Suggestions are non-blocking and must never drive a merge-blocking verdict. |
| `Reject` without an `❌` finding | Reject requires a fundamental defect. |
| `Needs Human Review` without a verified human decision point | Must name the verified issue whose blocking status depends on policy, product intent, risk acceptance, or another human decision; not uncertainty about whether an issue exists. |
| `Review Incomplete` without missing material evidence and attempted verification | Incomplete is a non-approval outcome for evidence insufficiency only; it must state the missing material evidence and the attempted verification path, must not imply approval, and must not be used as a speculative finding severity. |

Only entries parsed from `### Detailed Findings` count as findings for this
check. Entries under `### Unresolved Questions` are excluded from finding
counts and verdict consistency.

`Review Incomplete` may appear alongside verified findings, but the incomplete
status is caused by material evidence that could not be obtained after attempted
investigation. It is not a finding severity, does not participate in
severity-consistency scoring, and must parse as `review_incomplete`. Incomplete
outcomes are evaluated for the required missing-evidence statement and
attempted-verification content by output-quality checks.

For detection fixtures with `expected_verdict_at_least`, `review_incomplete`
does not satisfy any approval or blocking verdict floor because it does not
establish the expected finding severity. The detection harness scores it below
`LGTM` for floor purposes, so any required floor such as `needs_changes`
produces `Verdict.Scored=true` and `Verdict.Violation=true`.

### 3. Finding evidence traceability (manual / structured hard fail)

Every finding must identify evidence establishing both:

- the claimed behavior (what code path, control flow, data flow, runtime
  behavior, contract, or convention makes the behavior happen), and
- the impact (why that behavior can cause the stated correctness, safety,
  security, performance, compatibility, or maintainability consequence).

Accepted evidence includes static code/control/data-flow analysis, observed
test or runtime behavior, repository history/conventions, and authoritative
reference documentation. A file location alone is insufficient when the causal
claim depends on behavior elsewhere; it anchors the finding but does not prove
the behavior or impact.

This remains an output-quality check, not a detection-correctness check:
Dimension 1 determines whether the claimed issue is actually correct, while this
rubric asks whether the review made the evidence trail explicit.

Automation is manual/heuristic unless the fixture or review provides structured
evidence fields. A semantic parser cannot reliably prove that prose establishes
behavior and impact. When structured evidence fields exist, score them directly;
otherwise emit a manual/heuristic result against this rubric:

- behavior evidence names the concrete code path, control/data flow, runtime
  behavior, contract, convention, repository evidence, or authoritative
  documentation that makes the claimed behavior happen, with citations;
- impact evidence connects that behavior to the stated correctness, safety,
  security, performance, compatibility, or maintainability consequence;
- a file/line reference alone anchors the claim but does not satisfy either
  behavior or impact evidence when the causal claim depends on surrounding code
  or runtime context.

`### Unresolved Questions` entries are not findings. They must be parsed
separately, excluded from finding counts, and excluded from actionability,
severity, and verdict-consistency calculations. Each question must identify
what is unknown and how to verify it. Any question whose answer could affect
severity or verdict is a hard fail; material uncertainty means the review is
incomplete, not approved-with-a-question.

### 4. Finding actionability (soft / heuristic)

For each finding, check the body for:

- a file reference (path or `path:line`),
- "why it matters" content (verb-based phrasing — `because`, `causes`,
  `risks`, `breaks`, `leaks`, `races`, `corrupts`, etc.),
- a fix direction or decision point (`should`, `consider`, `replace with`,
  `prefer`, `need to decide`, etc.),
- absence of pure praise / non-actionable commentary.

Reported as a per-review **actionability score** 0..1, not pass/fail.

### 5. No-praise rule

`SKILL.md` § Severity Classification:
> "Only surface actionable findings. Do not include positive confirmations,
> 'looks good' notes, or commentary praising correct code."

Heuristic: flag findings whose body matches `^\s*(looks good|nice|great|
well done|correctly|good job)` etc.

### 6. Severity calibration (cross-references Dimension 1)

For TPs in the detection harness, compute `severity_delta`. See
`01-detection-quality.md`.

## Fixtures

`fixtures/output/` will hold **labeled review markdown files** — the
artifacts to score against. Format:

```
fixtures/output/<case-id>/
├── review.md           # the review to grade
└── expected.json       # what to assert
```

`expected.json` example:

```json
{
  "case_id": "lgtm-with-warning-violation",
  "should_parse": true,
  "expected_violations": ["lgtm_with_warning"],
  "expected_findings_count": 1,
  "expected_unresolved_questions_count": 0,
  "expected_verdict": "lgtm"
}
```

For output-quality fixtures, `expected_verdict` may be `lgtm`,
`needs_human_review`, `needs_changes`, `reject`, `review_incomplete`, or
`unknown`. `review_incomplete` means the summary should use the incomplete
outcome and the prose must identify both missing material evidence and the
attempted verification path. Detection fixtures that use
`expected_verdict_at_least` floors rank the parser's `review_incomplete` value
below approval outcomes so it cannot satisfy the floor.

## Harness sketch (deferred to v2)

```powershell
./harness/Score-Output.ps1 -Fixtures ./fixtures/output -OutDir ./results/output
```

- Walk fixtures.
- For each: parse `review.md` via the shared parser
  (`harness/lib/Parse-Review.psm1`).
- Run the six checks above, using structured evidence fields where available
  and otherwise emitting manual/heuristic evidence-traceability results.
- Diff against `expected.json`.
- Aggregate.

The parser library is built in v1 for detection scoring, but the output-quality
harness is not just a parser wrapper: evidence traceability, incomplete-outcome
validity, and human-decision-point checks require rubric scoring and/or
structured fixture annotations.

## Known failure modes

- **Verdict-icon mojibake.** Adapters may strip emoji. Parser must accept
  both `⚠️` and the literal string `Warning`/`Needs Changes` as fallback.
- **Headers as decoration.** A review with all the right headers but empty
  sections will pass format checks. The actionability heuristic partially
  catches this; full validation requires content checks deferred to v2.
- **Multi-finding headings.** A single `####` heading may discuss multiple
  related issues. The parser keeps them as one finding by default; cases
  testing finding-count should be authored carefully.
