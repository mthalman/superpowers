---
name: tdd
description: Apply test-driven development to an approved software design by creating compile-valid interface or API stubs and executable tests before implementation begins. Use when the user provides a design, contract, API proposal, state model, or acceptance criteria and asks for TDD, test-driven development, tests first, an executable specification, outside-in development, interface scaffolding, or a red test suite. Do not use while choosing among competing designs, for test planning without code, or when the user wants implementation rather than the initial TDD red phase.
---

# Test-Driven Development

Start test-driven development from a selected design by translating it into the
smallest production skeleton and test suite that make its contracts executable.
Preserve the design's implementation freedom: expose only the chosen
boundaries, test observable behavior, and stop after establishing the initial
red state.

## Boundaries

Use this skill after the design is settled enough to encode. If the user still
needs to compare interface shapes, use `arena` first. If they only want a
validation plan rather than code, use `validation-scenarios`.

This workflow creates:

- public types, interfaces, signatures, schemas, or endpoints required by the
  design;
- the minimum concrete seam needed for tests to construct or invoke the
  designed subject;
- tests that express the required behavior and currently fail for the intended
  missing behavior.

It does not implement the behavior, broaden the design, or add speculative
extension points.

## 1. Establish the design authority

Identify the design artifact and the decisions it makes:

- callers and public entry points;
- inputs, outputs, errors, and side effects;
- invariants and state transitions;
- dependency boundaries and ownership;
- compatibility constraints and acceptance criteria;
- intentionally deferred or unspecified behavior.

Inspect existing code, tests, build configuration, and repository conventions
before adding files. Reuse the project's test framework, naming, fixture, and
module patterns.

Treat contradictions and missing product decisions as design gaps. Ask about a
gap when different answers would change the public contract or expected
behavior. Do not silently complete a consequential design on the user's
behalf.

## 2. Build a contract matrix

Convert the design into a concise implementation checklist before editing:

| Contract | Production surface | Observable example | Test level |
|---|---|---|---|
| C1 | Type, method, endpoint, or event | Input and expected result | Unit, contract, integration |

Include:

- the common success path;
- meaningful boundaries and invalid inputs;
- specified errors and externally visible side effects;
- state transitions, ordering, retries, or idempotency when the design defines
  them;
- compatibility behavior the design promises to preserve.

Exclude cases that merely restate language typing, duplicate another example,
or assume behavior absent from the design.

## 3. Stub the production contract

Create the least production code needed for callers and tests to compile:

- declare the designed public types and signatures exactly;
- preserve the repository's module and dependency direction;
- add a concrete shell or adapter only when the test framework needs an
  invocable subject;
- make unimplemented execution fail explicitly using the language's idiomatic
  unsupported or not-implemented mechanism.

Do not return plausible zero values, empty collections, successful results, or
no-op side effects. Those placeholders can make tests pass accidentally and
hide the missing behavior.

Keep stubs free of branching business logic. Constructors may retain
dependencies when required to expose the designed seam, but they must not
perform the behavior under test.

## 4. Write tests from the design

Write tests against public behavior rather than the stub's current structure.
For each contract:

1. Arrange inputs and collaborators named by the design.
2. Invoke the public surface as a real caller would.
3. Assert the specified output, error, state transition, or side effect.
4. Make failures identify the violated contract.

Prefer concrete values that reveal the rule being specified. Use
parameterization for meaningful equivalence classes or boundaries, not to
compress unrelated behaviors into one opaque test.

Mock only at designed dependency boundaries. Do not mock the subject under
test, private helpers, or incidental call sequences unless ordering itself is
part of the contract. A test should survive a valid internal refactor.

When multiple implementations must share one contract, create a reusable
contract-test suite parameterized by a subject factory. Add only the minimal
placeholder factory or shell needed to demonstrate the initial red state.

## 5. Prove the starting state

Run the narrowest existing commands that establish both conditions:

1. Production stubs compile or type-check, so failures are not caused by
   misspelled names, broken imports, or malformed signatures.
2. The new tests execute and fail because behavior is unimplemented or differs
   from the designed expectation.

Classify every new-test result:

- **red as intended**: reaches the subject and fails on missing behavior;
- **invalid red**: cannot compile, import, discover, arrange, or invoke;
- **unexpected green**: passes without the designed behavior being
  implemented.

Fix invalid reds. Strengthen or correct unexpected greens. Do not implement
production behavior to turn intended reds green.

If the repository cannot run tests because a required tool or environment is
unavailable, preserve the compile-valid scaffold where possible and report the
exact unverified condition.

## 6. Check design fidelity

Before handing off, compare the files to the original design:

- every designed public contract has a production declaration;
- every required behavior has at least one discriminating test;
- every test expectation traces to the design or stated acceptance criteria;
- no test freezes an unspecified implementation detail;
- no production stub contains behavior intended for the implementation phase;
- no invented API, configuration option, or abstraction expanded the design.

Resolve mismatches in the scaffold or expose them as design questions. Do not
call an assumption a requirement.

## Handoff

Report:

```markdown
## Contract scaffold

<Production surfaces created and where they live>

## Executable specification

| Contract | Tests | Initial state |
|---|---|---|
| C1 | test name(s) | red as intended |

## Design gaps

<Unresolved or deferred decisions, or "None">

## Implementation boundary

<What remains deliberately unimplemented>
```

Keep the red suite in place. The next implementation step should make one
behavior pass at a time without changing the agreed contract.
