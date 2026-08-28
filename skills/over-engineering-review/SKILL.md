---
name: over-engineering-review
description: Use when evaluating code, a diff, API, or design for unnecessary complexity, speculative abstraction, premature extensibility, excessive indirection, needless configurability, or YAGNI violations. Produces an evidence-based, read-only assessment with simpler adequate alternatives while preserving justified complexity. Triggers on "is this over-engineered?", "too many abstractions", "can this be simpler?", "is this design too complex?", "review this for YAGNI", or requests to challenge architecture ceremony. Do not use for a general correctness review or when the user has already decided to refactor.
---

# Over-Engineering Review

Evaluate whether a solution carries more structural and operational complexity
than its verified requirements justify. Treat complexity as a cost, but not as a
defect by itself: concurrency, compatibility, security, domain rules, and
established variation can make a complex design the simplest adequate one.

This is a read-only assessment. Recommend a simpler design when the evidence
supports one, but do not edit code unless the user separately asks for
implementation.

## Boundaries

- Use `code-review` for broad correctness, security, performance, and merge
  readiness. Mention a correctness defect only when it is direct evidence of
  the complexity cost being assessed.
- Use `code-refactorer` after the user decides to change the implementation.
  This skill determines whether simplification is warranted and what must be
  preserved; it does not perform the refactoring.
- Use `why` when the main question is historical motivation. Consult history
  here only to verify a claimed constraint or understand whether variation is
  real.

## Review Workflow

### 1. Establish the target and need

Identify whether the target is a change, an existing subsystem, or a proposed
design. Then establish:

- the concrete behavior or problem it must address;
- current callers, implementations, variants, and configuration values;
- compatibility, security, performance, operational, and framework constraints;
- tests or documentation that encode non-obvious requirements.

Do not infer excess from code shape alone. Without the need and constraints,
you cannot distinguish ceremony from load-bearing design.

### 2. Inventory the complexity

Map the concepts a maintainer must understand and the mechanisms introduced to
support them:

- layers, wrappers, adapters, factories, registries, and indirection;
- interfaces, generic parameters, extension points, callbacks, and policies;
- configuration, feature flags, dependencies, and generated artifacts;
- state, lifecycle, concurrency, caching, retries, and failure modes;
- cross-file navigation and the number of places required for one ordinary
  change.

Read `references/signals.md` when the target contains several interacting
abstractions or when you need calibrated examples of common signals.

### 3. Test each suspected excess

For each mechanism, answer these questions with repository or requirement
evidence:

1. **Demand:** Which verified requirement needs it today or in a committed,
   near-term path?
2. **Variation:** Which real implementations or behaviors vary behind it?
3. **Compression:** Does it remove repeated knowledge, or merely redistribute
   simple logic across more names and files?
4. **Locality:** Does it make an ordinary change easier to reason about, or
   force maintainers to navigate more layers?
5. **Constraint:** Does it enforce an invariant, isolate an external system,
   preserve compatibility, or satisfy a framework contract?
6. **Cost:** What recurring burden does it create in comprehension, testing,
   configuration, debugging, or future changes?

A mechanism is not over-engineered merely because one question has a weak
answer. Retain a finding only when the evidence shows recurring cost without a
proportionate present constraint or benefit.

### 4. Construct the simplest adequate counterfactual

Describe the smallest design that still satisfies every verified requirement.
Keep security boundaries, concurrency guarantees, public compatibility,
observability, and required framework integration intact.

Preserve externally observable behavior by default, including validation and
failure behavior that may look redundant after structural simplification. If
removing that behavior would make the design simpler, present it as a separate
behavior change that requires explicit approval; do not smuggle it into a
structural recommendation.

The counterfactual is the check against vague "this feels complex" criticism.
If the proposed simplification cannot preserve the known constraints, discard
the finding. Prefer a small structural sketch over a full rewrite.

### 5. Challenge the assessment

Before reporting a finding, try to disprove it:

- Search for callers, implementations, configuration values, and tests you may
  have missed.
- Check whether the abstraction is the repository's required integration seam.
- Check whether apparent duplication belongs to different bounded contexts.
- Check whether history or documentation identifies a compatibility or
  operational constraint.
- Compare the total concepts and change steps in the current design with the
  counterfactual. Fewer lines alone are not evidence of lower complexity.

If material evidence is unavailable, mark the review incomplete rather than
turning uncertainty into a finding.

### 6. Report only material results

Rank findings by recurring cost:

- **High:** The design imposes broad, repeated coordination or makes routine
  changes materially harder across the subsystem.
- **Medium:** A contained mechanism adds meaningful navigation, testing, or
  configuration burden without current benefit.
- **Low:** Local ceremony has a concrete but small maintenance cost.

Do not report naming taste, file-count preferences, or hypothetical future
confusion. Multiple symptoms caused by the same abstraction belong in one
finding.

## False-Positive Controls

Do not recommend removing complexity that is justified by evidence, including:

- multiple active implementations or committed near-term variants;
- public API or data-format compatibility;
- security boundaries, validation, auditing, or privacy controls;
- concurrency, transaction, retry, idempotency, or failure-recovery guarantees;
- performance behavior supported by realistic measurements;
- framework-required lifecycle or integration seams;
- generated code or uniform repository conventions that tooling depends on;
- domain distinctions that only look duplicated syntactically.

Avoid replacing explicit, testable structure with clever compression. Shorter
code can be harder to understand and less safe to change.

## Output Format

```markdown
## Over-Engineering Assessment

**Verdict:** Proportionate | Mixed | Over-engineered | Review incomplete
**Confidence:** High | Medium | Low

<Two or three sentences describing the verified need, the current approach,
and the overall complexity tradeoff.>

### Findings

#### <High | Medium | Low> - <mechanism and concrete cost>

**Location:** <file:line, symbol, or design element>
**Excess mechanism:** <what exists beyond the verified need>
**Evidence:** <callers, variants, configuration, tests, or requirements checked>
**Recurring cost:** <specific comprehension, change, test, or operational burden>
**Simpler adequate design:** <smallest alternative that preserves all constraints>
**Preserve:** <load-bearing behavior the simplification must retain>
**Confidence:** <High | Medium | Low> - <brief basis>

### Evidence gaps

<Only material missing evidence and the concrete way to obtain it.>
```

Omit `Findings` when the design is proportionate. Omit `Evidence gaps` when the
evidence is sufficient. A clean assessment should stay short; do not invent
findings to demonstrate thoroughness.
