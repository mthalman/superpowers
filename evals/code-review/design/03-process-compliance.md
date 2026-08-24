# Dimension 3 — Process Compliance

> **Question:** Did the agent actually follow the 7-step process in
> `SKILL.md`, or did it shortcut to "produce a review" and skip the
> calibration steps?

This dimension is hard to automate perfectly: transcripts are fuzzy, and
"intent" can be faked with section headers. We measure coarse violations only
when the transcript or structured event stream makes the chronology observable.

**v1 status:** Designed, not automated. A `Score-Process.ps1` would be a
straightforward addition once we have transcript fixtures.

## What we can check from a transcript

The adapter may optionally emit a structured **transcript log** alongside the
review (path declared in the adapter response). Format: JSONL of timestamped
events. Plain tool/agent events are useful, but temporal checks are strongest
when adapters also emit process events with stable IDs:

```jsonl
{"t": 0.0,  "kind": "tool_call", "tool_call_id": "tool-1", "tool": "read", "args": {"path": "diff.patch"}}
{"t": 1.2,  "kind": "tool_call", "tool_call_id": "tool-2", "tool": "read", "args": {"path": "src/fetch.ts"}}
{"t": 4.0,  "kind": "evidence_orientation", "scope": ["diff.patch", "src/fetch.ts", "src/routes.ts"], "evidence_refs": ["tool-1", "tool-2", "file:src/fetch.ts:1-120"], "summary": "Mapped request URL flow before considering candidate findings."}
{"t": 6.5,  "kind": "risk_map", "risks": [{"risk_id": "risk-ssrf", "area": "network fetch", "why": "User-controlled URL reaches an outbound request boundary."}], "evidence_refs": ["file:src/fetch.ts:40-55"]}
{"t": 9.0,  "kind": "risk_deepening", "risk_id": "risk-ssrf", "tool_refs": ["tool-3"], "evidence_refs": ["file:src/routes.ts:10-30", "file:src/fetch.ts:40-55"], "summary": "Checked callers and found no host allowlist before fetch."}
{"t": 12.0, "kind": "hypothesis_generated", "candidate_id": "cand-ssrf", "source": "internal", "basis": "Risk map shows untrusted URL crossing network boundary without validation.", "basis_refs": ["risk:risk-ssrf", "file:src/routes.ts:10-30", "file:src/fetch.ts:40-55"]}
{"t": 18.0, "kind": "verification", "candidate_id": "cand-ssrf", "outcome": "verified", "evidence_refs": ["file:src/routes.ts:10-30", "file:src/fetch.ts:44", "doc:fetch-security-guidance"], "summary": "Confirmed no caller validates host and fetch accepts attacker URL."}
{"t": 32.0, "kind": "subagent_launch", "subagent_id": "model-critique-1", "purpose": "external-model critique"}
{"t": 49.0, "kind": "internal_grill_complete", "candidate_ids": ["cand-ssrf"], "question_count": 8, "material_gaps": [], "ledger_ref": "internal-ledger:step6"}
{"t": 67.0, "kind": "final_review", "text": "## 🤖 Code Review\n..."}
```

Proposed fields:

- `evidence_orientation`: `scope`, `evidence_refs`, `summary`.
- `risk_map`: `risks[]` with `risk_id`, `area`, `why`, plus `evidence_refs`.
- `risk_deepening`: `risk_id`, `tool_refs`, `evidence_refs`, `summary`.
- `hypothesis_generated`: `candidate_id`, `source`, `basis`,
  `basis_refs`.
- `verification`: `candidate_id`, `outcome`
  (`verified` / `rejected` / `inconclusive`), `evidence_refs`, `summary`.
- `internal_grill_complete`: reviewed `candidate_ids`, `question_count`,
  `material_gaps`, and optional `ledger_ref`.

Equivalent strong chronology can come from detailed timestamped tool traces and
agent notes, but absent structured events should be treated as manual or
unscorable, not guessed from final-output sections.

## Evidence-first discovery requirement

The process requires evidence-first discovery before hypothesis validation. The
reviewer must first build a broad evidence orientation across relevant
contracts, data/control flow, tests, execution context, repository
history/conventions, and authoritative documentation. It should then deepen
research in high-risk areas and derive candidate findings from gaps,
contradictions, or unsafe interactions in that evidence model. Verification is
still required after candidate generation, but late verification is not a
substitute for evidence-driven discovery.

## Checks (ordered by signal-to-noise)

### Hard fails (only with structured events or equally strong chronology)

1. **Narrative anchoring** — in PR mode, `pr.md` or equivalent PR narrative is
   read before any independent evidence orientation or assessment. Reading the
   description first violates Step 2 when the chronology is observable.
2. **Hypothesis-first research** — `hypothesis_generated` events, candidate
   finding lists, or model-generated concerns appear before broad
   `evidence_orientation` and risk-directed `risk_map` / `risk_deepening`
   events across the relevant contracts, data/control flow, tests, execution
   context, repository history/conventions, and authoritative docs. This is a
   hard fail only when structured events or equally strong chronology prove the
   order; otherwise it is manual/unscorable.
3. **Late-only verification** — `verification` or equivalent research is used
   only after candidates exist, with no earlier evidence orientation or risk
   map from which candidates were derived. This is hard only when structured
   events or equally strong chronology prove the order; otherwise
   manual/unscorable.
4. **Unsupported candidate survives synthesis** — a final finding is traceable
   to a speculative candidate, including a model-generated concern from Step 5,
   and no `verification` event with outcome `verified` and concrete
   `evidence_refs` exists before final synthesis. This is hard only when the
   candidate/finding link and missing verification are observable.
5. **Multi-model critique skipped without disclosure** — transcript events or
   adapter metadata show Step 5 was required and skipped, but the final output
   does not document the skip and reason (for example, "Multi-model review
   skipped: ..."). Silent skips are not permitted. Do not require a
   `Multi-Model` section when the critique actually ran.
6. **Required internal grill not completed** — a structured event contract for
   the run requires `internal_grill_complete`, but no such event exists before
   final synthesis, or the event records material gaps that are neither resolved
   nor reflected as `Review Incomplete`. Without structured events or an
   equally strong ledger chronology, grill completion is manual/unscorable.

### Soft signals (lower confidence)

7. **No surrounding-file reads** — the transcript shows reads of the diff and
   changed files but no reads of callers, helpers, tests, contracts, or docs.
   Often correlates with diff-only review.
8. **Coverage-via-confirmation** — output contains one confirmed bug and little
   other evidence of risk-directed exploration, especially when Step 5 was
   skipped with disclosure.
9. **Cleanliness bias** — LGTM verdict with no recorded reads beyond the diff
   itself.

Soft signals are not proof of process failure. If evidence orientation/order,
risk deepening, hypothesis timing, grill completion, or PR narrative
reconciliation is not observable in a transcript, structured event stream, or
equally strong chronology, mark it manual/unscorable rather than inferring from
missing output sections.

## Dimension boundaries

The following are **Dimension 2 output-quality checks**, not process hard fails:

- an unresolved question or evidence gap affects severity, `Needs Human Review`,
  approval, or any other verdict;
- a final finding lacks traceable behavior evidence or impact evidence;
- required final structure, unresolved-question separation, verdict
  consistency, and `Review Incomplete` formatting/validity.

Dimension 3 may use structured process events to determine whether a candidate
was verified before final synthesis, but it should not duplicate Dimension 2's
final-output rubric.

## Output-only fallback checks

When no transcript or structured event stream is available, process compliance
has no reliable temporal signal. Do not require final-output sections for
Independent Assessment, Multi-Model Critique, Grill/Self-Critique, or PR
narrative reconciliation; `SKILL.md` treats those as internal ledger content or
process steps, not mandatory review-output sections.

Output fallback delegates required final structure, evidence traceability,
unresolved questions, verdict consistency, and incomplete-outcome validity to
Dimension 2. The only process/output observable is skip disclosure: if the
adapter output or metadata says the required multi-model critique was skipped,
the final review must disclose the skip and reason. Without evidence that a skip
occurred, absence of a `Multi-Model` section is not a violation.

## Fixtures

`fixtures/process/` holds transcript + review pairs with labeled violations:

```
fixtures/process/<case-id>/
├── transcript.jsonl
├── review.md
└── expected.json    # which violations should fire or be manual/unscorable
```

Initial corpus targets:

- `narrative-anchoring-pr-first/` — PR narrative read before independent
  evidence orientation.
- `hypothesis-first-before-orientation/` — candidate findings generated before
  broad evidence orientation and risk-directed deepening.
- `late-only-verification/` — evidence gathered only after a candidate list,
  solely to validate those candidates.
- `unsupported-model-concern-survives/` — Step 5 concern appears as a final
  finding without independent verification.
- `multi-model-silent-skip/` — structured transcript or adapter metadata shows
  required Step 5 was skipped, but final output gives no skip reason.
- `internal-grill-not-completed/` — structured event contract lacks
  `internal_grill_complete` before final synthesis.
- `clean-baseline/` — all observable process steps respected.

Output-only cases such as verdict shaped by a question or findings without
behavior/impact evidence belong in Dimension 2 fixtures.

## Why we don't try to grade "quality of thinking"

Inferring whether a Step 2 assessment is *actually* independent (vs. written
after the fact) from final prose is unreliable. We measure ordering and
presence only when they are observable in transcripts or structured events, and
accept that determined shortcutting can game any automated check. Manual spot
audits of a sampled subset cover the rest.

## Known failure modes of this dimension

- **Some adapters don't expose transcripts.** Most process checks become
  manual/unscorable; output-only fallback is intentionally narrow.
- **Headers can be faked.** A review that prints "Independent Assessment" or
  "Grill" does not prove those steps happened. Final-output headers are not
  process evidence.
- **Standalone vs PR mode** — `SKILL.md` Step 3 doesn't apply in standalone
  mode. The checker must read fixture mode or PR-narrative presence to switch
  modes.
