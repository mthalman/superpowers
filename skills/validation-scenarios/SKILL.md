---
name: validation-scenarios
description: Examine a proposed or completed change and design a proportional set of risk-based validation scenarios that provides reasonable assurance the change is correct. Use when the user asks for a validation plan, manual QA workflow, release checks, smoke scenarios, confidence-building checks, or "how should we validate/test these changes?" Use this even when the result may later inform automated tests, but the immediate need is scenario coverage rather than test-case implementation or a code-review verdict.
---
# Validation Scenarios

Turn a proposed or completed change into a small, defensible set of observations
that would give reasonable assurance it is correct. A validation scenario may
become an automated test, a manual workflow, a build check, a production-like
rehearsal, or a release observation. Do not write test code unless the user asks
for it.

Use this skill to plan validation before implementation, after implementation,
before merge or release, when existing automation only partly covers a change, or
when a manual/environment-dependent workflow needs repeatable checks. Use
`code-review` for a merge verdict and `blast-radius` only when explicitly asked
to prove what could break.

Open `references/scenario-techniques.md` when selecting boundary, state,
integration, compatibility, manual, hybrid, or proportionality techniques, or
when you need the detailed challenge checklist.

## Workflow

### 1. Establish the change scope

Identify the diff, PR, commit range, files, or described behavior. If scope
cannot be inferred safely, ask before continuing. Read enough surrounding
evidence to understand requirements, old and new behavior, affected callers,
data flows, contracts, dependencies, existing tests, environments, flags,
migrations, and rollout constraints. Separate verified behavior from inferred
intent.

### 2. Build a change model

Divide the work into semantic change units: changed behaviors, contracts, state
transitions, data transformations, side effects, or operational properties. Do
not equate files or hunks with behaviors. For each unit record prior behavior,
intended behavior, inputs, outputs, side effects, observable errors, preserved
invariants, interaction points, and the consequence if wrong. Group mechanical
edits only when they share the same validation consequence.

### 3. State assurance claims

Write falsifiable claims the validation must support. Claims should cover only
properties implicated by the change: success behavior, rejected/degraded inputs,
boundaries, state transitions, preserved behavior, integrations, side effects,
concurrency, retries, idempotency, ordering, security, performance, deployment,
configuration, migration, rollback, or observability. Example: "A page with
exactly `page_size` remaining records returns every record once and reports no
next page." Do not use vague claims such as "pagination works."

### 4. Design the smallest convincing scenario set

Choose scenarios by risk and information value. A scenario earns its place when
its result would materially change confidence in one or more assurance claims.
Avoid full Cartesian products; combine dimensions only when their interaction is
a credible failure mode. High-impact, irreversible, or hard-to-detect behavior
requires stronger and more independent evidence than local reversible changes.

Every scenario must be executable by someone who did not author the change and
must include:

1. assurance claim and risk covered;
2. setup, initial state, and important data;
3. action or stimulus;
4. specific expected observations, including side effects and absences;
5. why failure would matter;
6. validation mode: `automated`, `manual`, or `hybrid`;
7. priority: `must`, `should`, or `could`.

Do not use outcomes like "works," "looks right," or "no errors." Name the UI
state, response, persisted value, emitted event, metric, log, timing threshold,
or other evidence to observe.

### 5. Reconcile existing coverage

Map each scenario to assurance claims and inspect existing tests, CI checks,
manual runbooks, or release gates when available. Classify coverage as:

- `existing`: current evidence covers the scenario adequately;
- `extend`: close coverage misses a material condition or observation;
- `new`: no suitable coverage exists;
- `manual-only`: automation is impractical or insufficient;
- `blocked`: requirement, environment, data set, or observable is missing.

Do not recommend new automation when existing coverage gives equivalent evidence.
Do not label a scenario automated merely because automation is possible; name the
concrete layer or harness only when repository evidence supports it.

### 6. Challenge proportionality and confidence

Check that every changed behavior and material invariant maps to a scenario,
expected results come from requirements or contracts rather than the new
implementation, duplicate scenarios add distinct evidence, manual checks are
repeatable, and the plan is proportionate to likelihood, impact, reversibility,
and detection difficulty. Resolve material assurance gaps by strengthening the
set. If a gap cannot be resolved, report it as an assurance gap or confidence
limit instead of claiming full coverage.

## Report

Use this structure:

```markdown
## Change model

| Unit | Intended behavior | Preserved invariants | Main risk |
|---|---|---|---|
| C1 | ... | ... | ... |

## Assurance claims

- A1: <falsifiable claim>

## Validation scenarios

### V1: <behavior-oriented title>

- **Claims:** A1
- **Priority:** must | should | could
- **Mode:** automated | manual | hybrid
- **Coverage:** existing | extend | new | manual-only | blocked
- **Risk:** <failure this detects and why it matters>
- **Setup:** <initial state, environment, and data>
- **Action:** <stimulus>
- **Expected observations:** <specific visible and hidden outcomes>
- **Suggested layer:** <existing harness, component boundary, workflow, or environment when known>

## Coverage summary

| Change unit | Claims | Scenarios | Remaining confidence limit |
|---|---|---|---|
| C1 | A1 | V1 | none / ... |

## Assurance gaps

- <Unknown requirement, unavailable environment, unobservable effect, or residual risk. Omit this section when none.>
```

Order scenarios by priority and execution dependency. Keep the report concise
enough to use as a validation checklist, but preserve setup and observations for
repeatability. If evidence is incomplete, state the resulting confidence limit.
The goal is reasonable assurance, not proof that finite validation excludes every
defect.
