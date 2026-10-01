# Scenario Techniques

Detailed techniques for modeling changes, choosing proportional scenarios, reconciling coverage, and challenging a validation plan.

## Workflow

### 1. Establish the change scope

Identify the diff, pull request, commit range, files, or described behavior in
scope. If the scope cannot be inferred safely, ask before continuing.

Read enough surrounding evidence to understand the change rather than treating
the diff as a complete specification:

- requirements, issue, or acceptance criteria;
- old and new behavior;
- affected callers, data flows, contracts, and dependencies;
- existing tests and validation instructions;
- relevant environments, feature flags, migrations, or rollout constraints.

Separate verified behavior from inferred intent. Record unresolved ambiguities
because a scenario cannot prove correctness against an unknown expectation.

### 2. Build a change model

Divide the work into semantic change units. A unit is one changed behavior,
contract, state transition, data transformation, side effect, or operational
property. Do not equate files or diff hunks with behaviors.

For each unit, record:

- the prior behavior and intended new behavior;
- inputs, outputs, side effects, and observable errors;
- invariants that must remain true;
- interaction points with callers, dependencies, persistence, or operators;
- the consequence if the behavior is wrong.

Group mechanical edits that have the same validation consequence. Keep
independent behaviors separate even when they appear in one file.

### 3. State the assurance claims

Write falsifiable claims that the validation must support. Claims make the plan
traceable and prevent a long checklist from masquerading as coverage.

Good:

> A page with exactly `page_size` remaining records returns every record once
> and reports no next page.

Weak:

> Pagination works.

Include claims only for properties implicated by the change. Consider:

- intended success behavior;
- rejected or degraded inputs;
- boundaries and state transitions;
- preserved behavior and backward compatibility;
- integrations and externally visible side effects;
- concurrency, retries, idempotency, or ordering;
- security and authorization boundaries;
- performance or resource limits;
- deployment, configuration, migration, rollback, and observability.

### 4. Design the smallest convincing scenario set

Choose scenarios by risk and information value, not by filling every category.
A scenario earns its place when its result would materially change confidence
in one or more assurance claims.

Use these techniques where relevant:

- representative equivalence classes instead of many redundant examples;
- exact boundaries plus one value on either side;
- state transitions, including repeat, retry, interruption, and recovery;
- interaction checks at changed contracts and dependency boundaries;
- compatibility checks across old data, clients, configuration, or partial
  rollout states;
- end-to-end or production-like checks for behavior mocks cannot establish;
- focused manual observation for visual, hardware, timing, or operator
  workflows.

Prefer one scenario that distinguishes several plausible failures over several
scenarios that all prove the same thing. Avoid combinatorial explosion: combine
dimensions only when their interaction creates a credible failure mode. For
high-impact or irreversible behavior, require stronger and more independent
evidence than for a local, reversible change.

Every scenario must be executable by someone who did not author the change.
Specify:

1. the assurance claim and risk it covers;
2. setup, initial state, and important data;
3. action or stimulus;
4. observable expected results, including side effects and absences;
5. why failure would matter;
6. the best validation mode: automated, manual, or hybrid;
7. priority: `must`, `should`, or `could`.

Do not use vague outcomes such as "works," "looks right," or "no errors."
Name the UI state, response, persisted value, emitted event, metric, log, timing
threshold, or other evidence to observe.

### 5. Reconcile existing coverage

Map each scenario to the assurance claims and inspect existing tests, CI checks,
manual runbooks, or release gates when available.

Classify coverage as:

- `existing`: current evidence covers the scenario adequately;
- `extend`: existing coverage is close but misses a material condition or
  observation;
- `new`: no suitable coverage exists;
- `manual-only`: automation is impractical or would not establish the behavior;
- `blocked`: a requirement, environment, data set, or observable is missing.

Do not recommend new automation when existing coverage already gives equivalent
evidence. Do not label a scenario automated merely because it could be
automated; identify the concrete layer or harness only when repository evidence
supports that choice.

### 6. Challenge the plan

Before reporting, ask:

- Does every changed behavior and material invariant map to a scenario?
- Which realistic failure could still pass all proposed scenarios?
- Did the plan check only the happy path or only implementation-level behavior?
- Are expected results derived from requirements and contracts rather than the
  changed implementation itself?
- Does any scenario duplicate another without adding evidence?
- Are manual prerequisites and observations repeatable?
- Is the plan proportionate to likelihood, impact, reversibility, and detection
  difficulty?

Resolve material gaps by adding or strengthening scenarios. If a gap cannot be
resolved, expose it under **Assurance gaps** instead of claiming full coverage.
