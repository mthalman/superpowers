---
name: code-review
description: Use when analyzing code changes for correctness, performance, safety, and quality. Provides review criteria, severity classification, and output format for code reviews. Use standalone when reviewing any code changes, diffs, or patches. Triggers on "review my code", "check this for bugs", "audit this change", "is this safe to merge", "what could go wrong", "look at my changes", or requests to evaluate code quality or find risks.
---
# Code Review

Review code changes for correctness, performance, safety, and quality. Be polite,
skeptical, and evidence-first. Build an evidence model before generating hypotheses:
establish contracts, invariants, data flows, execution context, repository
conventions, tests, runtime evidence, and authoritative reference documentation.
A concern becomes a finding only when evidence establishes behavior and impact.

Open `references/review-checklist.md` when Step 4 needs a catalog of issue
classes. Open `references/review-rubric.md` when you need full workflow text,
failure modes, severity examples, verdict calibration, re-review guidance, or
longer output examples.

## Review

**Context modes:** In PR mode, complete all steps including Step 3. In standalone
mode, skip Step 3 because there is no author narrative.

### Step 0: Understand the Codebase (Prerequisite)

Orient before analyzing. Identify touched components, domain concepts,
relationships, callers, dependencies, data/control flow, and surrounding code.
This evidence base drives risk-directed research and later hypotheses.

### Step 1: Gather Code Context

Before reading PR narrative or review comments, collect the diff, changed files,
full source files, callers, related utilities, tests, runtime behavior, recent
history, execution context, data producers, and authoritative docs. Build a risk
map from contract changes, context shifts, trust boundaries, concurrency, error
paths, and undocumented assumptions. Deepen risk-directed research until enough
contracts and invariants are established to test specific hypotheses.

### Step 2: Form an Evidence-Informed Independent Assessment

Using only Steps 0-1 evidence, state what changed, what contracts apply, where
risk is concentrated, whether the verified need is real, and whether the
approach fits. Generate hypotheses from concrete discrepancies between the
change and evidence model. Verify each hypothesis by stating what would prove or
disprove it and gathering that evidence. Keep an internal evidence ledger; a
hypothesis is not a finding until behavior and impact are verified.

### Step 3: Incorporate PR Narrative and Reconcile

Now read the PR description, linked issues, existing review comments, and author
context as claims to verify. Reconcile conflicts with the independent assessment
and update conclusions only when new evidence supports it.

### Step 4: Detailed Analysis

Prioritize correctness, performance, safety, race conditions, resources,
incorrect assumptions, design problems, and test gaps. Compare changed paths,
callers, inputs, and downstream effects against established contracts. Every
finding must cite evidence for the causal claim and impact. Avoid style trivia,
duplicate pile-on, CI-caught issues, theoretical concerns, and suggestions that
ignore existing style. If material evidence is missing, keep investigating; if
it cannot be obtained, the review is incomplete rather than speculative.

### Step 5: Grill Your Assessment

Before output, challenge each finding, missed-risk area, and verdict. Resolve
questions in the evidence ledger. If a question reveals a gap, investigate via
code/data-flow, tests/runtime behavior, repository evidence, or authoritative
docs. Unsupported candidates must be removed. Questions are not findings and
must not affect severity or verdict; only non-material unresolved questions may
appear in output.

## Severity Classification

| Severity | When to use | Examples |
|----------|-------------|---------|
| ❌ **Error** | Verified merge-blocking defect with severe impact | Bugs, security vulnerabilities, data corruption, missing critical error handling |
| ⚠️ **Warning** | Verified merge-blocking issue, or verified issue whose blocking status requires human policy/product/intent judgment | Performance regressions, missing validation, inconsistency with established patterns |
| 💡 **Suggestion** | Non-blocking advisory concern or improvement | Readability improvements, minor optimizations, naming clarity |

Use severities only for verified findings. Choose the higher supported level
when impact falls between levels. Suggestions are non-blocking and cannot drive a
blocking verdict. Do not include praise or positive confirmations as findings.

## Pre-Output Checklist

Do not write the review until:

- material questions about correctness, safety, and verdict have evidence-backed
  answers, or the outcome is `Review Incomplete`;
- Step 5 has written internal answers and revealed gaps were investigated;
- every finding is verified and traceable with file:line, observed behavior,
  tests, repository evidence, or authoritative documentation;
- unresolved concerns are non-material, have verification paths, and must not
  affect severity or verdict;
- the verdict is independent of diff cleanliness, author reputation, and PR
  framing.

## Review Output Format

Output only holistic assessment, verified findings, and non-material unresolved
questions. If material evidence cannot be obtained, use `⏸️ Review Incomplete`
with missing evidence and attempted verification path.

```markdown
## 🤖 Code Review

### Holistic Assessment

**Motivation**: <1-2 sentences on whether the change is justified and the problem is real>

**Approach**: <1-2 sentences on whether the approach is sound>

**Summary**: <✅ LGTM / ⚠️ Needs Human Review / ⚠️ Needs Changes / ❌ Reject / ⏸️ Review Incomplete>. <2-3 sentence outcome based only on verified findings and evidence sufficiency.>

---

### Detailed Findings

#### ⚠️/❌/💡 <Category> — <Brief description>

<Explanation with specifics. Reference code, line numbers, evidence.>

### Unresolved Questions

Questions are not findings and must not affect severity or verdict. Include only non-material questions.

#### Question
<What remains unknown?>

#### Why it matters
<Why resolving it could matter if the concern is real.>

#### How to verify
<Concrete path that would resolve it.>
```

Omit unresolved questions when none exist.

### Verdict Rules

1. Base the verdict only on verified findings. Speculation, missing evidence,
   and unresolved hypotheses cannot change severity or verdict.
2. **LGTM**: no verified warning or error findings, only non-material unresolved
   questions, and sufficient independent evidence.
3. **Needs Changes**: verified merge-blocking warning or error can be corrected
   incrementally before merge.
4. **Needs Human Review**: evidence verifies a real issue, but blocking depends
   on product intent, policy, risk acceptance, or another human decision. Do not
   use it for uncertainty.
5. **Reject**: a verified fundamental defect makes the approach unsafe or
   nonviable and requires replacement.
6. **Review Incomplete**: material evidence required for correctness, safety, or
   approval cannot be obtained after attempted investigation. Do not imply
   approval or disguise the gap as a finding.
7. Suggestions are non-blocking; `Needs Changes` with only suggestions is
   invalid.
8. Unresolved questions must be non-material and must not affect severity or
   verdict.
9. Correct code can still be incomplete if it treats symptoms, misses affected
   instances, or fails the verified need.
