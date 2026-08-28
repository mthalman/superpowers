# Over-Engineering Signals

Use this catalog to generate hypotheses, not findings. Verify present demand,
constraints, and recurring cost before reporting any signal.

## Speculative variation

**Signals**

- An interface has one implementation and no testing seam, external boundary,
  or committed second implementation.
- A factory or registry always selects the same concrete type.
- Generic parameters, hooks, or plugin contracts have no real variation.
- Comments justify extension points only with "might", "someday", or "future".

**Likely cost**

Maintainers must trace abstractions whose substitution never occurs, and simple
changes require synchronized edits across contracts, implementations, and
construction code.

**Possible simplification**

Use the concrete implementation directly. Extract a seam when the second real
case appears or when tests need a boundary around an external dependency.

**Do not flag when**

The seam isolates I/O, time, randomness, a third-party API, a public contract,
or a framework lifecycle; multiple implementations exist outside the immediate
directory; or a committed near-term variant has concrete requirements.

## Indirection without compression

**Signals**

- Wrappers forward arguments and results without enforcing policy, translating
  protocols, or stabilizing an external API.
- A routine operation crosses several layers that each add only a name.
- A facade duplicates the underlying API instead of narrowing it.

**Likely cost**

Debugging and ordinary modifications require extra navigation without reducing
the amount of knowledge a maintainer needs.

**Possible simplification**

Inline pass-through layers or combine adjacent responsibilities that change for
the same reason.

**Do not flag when**

The layer owns a trust boundary, telemetry, compatibility, transaction scope,
retry policy, protocol translation, or a deliberately narrow dependency seam.

## Configuration without a decision

**Signals**

- Options expose values that are constant in every environment.
- A policy engine or rule DSL encodes one stable branch.
- Several flags can create unsupported or untested combinations.
- Configuration mirrors internal implementation details rather than user needs.

**Likely cost**

Every option expands the state space for documentation, validation, testing,
deployment, and incident diagnosis.

**Possible simplification**

Encode the invariant directly. Add configuration only when an identified
operator or consumer needs to make the decision independently. If removing the
option would alter existing invalid-input or startup behavior, keep validation
at the system boundary unless the user explicitly approves that behavior
change.

**Do not flag when**

Deployments demonstrably differ, gradual rollout is required, regulated
operators must control the value, or the option is part of a supported public
contract.

## Framework for a single operation

**Signals**

- Builders, command buses, visitor hierarchies, middleware pipelines, or event
  systems serve one small, stable flow.
- Registration and dispatch code is larger than the behavior it coordinates.
- Extension requires learning a local framework rather than the language or
  platform's ordinary idioms.

**Likely cost**

The local framework creates its own lifecycle, terminology, debugging model,
and failure modes.

**Possible simplification**

Use a direct function call, data structure, or small composition of ordinary
language features.

**Do not flag when**

The framework is already the repository convention, independent extensions are
active, ordering and middleware are real requirements, or external consumers
depend on the contract.

## Premature deduplication

**Signals**

- Two short blocks from different domains are unified through parameters,
  callbacks, conditionals, or subclass hooks.
- The shared abstraction requires more exceptions than common behavior.
- Callers pass constants or no-op callbacks to recover their original behavior.

**Likely cost**

Unrelated concepts become coupled, so a change for one consumer risks or
complicates every other consumer.

**Possible simplification**

Keep small duplication until the shared concept and variation stabilize. Share
only the proven invariant.

**Do not flag when**

The duplicated knowledge represents one business rule that must change
atomically, or three or more stable instances demonstrate a coherent
abstraction.

## Type-system ceremony

**Signals**

- Deep generic signatures preserve no meaningful type relationship for callers.
- Type wrappers or marker interfaces add no invariant, domain meaning, or
  dispatch behavior.
- A type-safe builder exists to construct one fixed shape.

**Likely cost**

Compiler errors, signatures, and navigation become harder while invalid states
remain possible or no real variation is modeled.

**Possible simplification**

Use concrete types, a small record, or a direct constructor. Retain types that
make invalid states unrepresentable or encode important domain distinctions.

**Do not flag when**

The types enforce a real invariant, preserve inference at a public API, prevent
category errors, or support several verified shapes.

## Defensive machinery for impossible states

**Signals**

- Internal layers repeatedly validate guarantees already established at a
  trusted boundary.
- Recovery branches cannot occur under the verified control flow.
- Retries, fallbacks, or caches address no observed or documented failure mode.

**Likely cost**

Extra branches obscure actual failure behavior and create untested paths that
can hide defects.

**Possible simplification**

Validate once at the correct boundary, express internal invariants, and fail
clearly when an impossible state indicates a programming error.

**Do not flag when**

Inputs cross trust boundaries, corruption is possible, distributed guarantees
are weaker than local types imply, or defense in depth is required by the
system's risk model.

## Dependency disproportion

**Signals**

- A package or service is introduced for a trivial operation already supported
  by the platform.
- Only a tiny portion of a broad dependency is used.
- The dependency adds configuration, transitive packages, runtime services, or
  upgrade obligations disproportionate to its benefit.

**Likely cost**

The solution inherits supply-chain, compatibility, deployment, and maintenance
work unrelated to the core need.

**Possible simplification**

Use a standard-library feature or a small local implementation when its edge
cases are genuinely bounded.

**Do not flag when**

The operation is deceptively specialized, security-sensitive, standards-heavy,
or better delegated to a mature implementation.

## Abstraction inversion

**Signals**

- Consumers must understand and configure internals the abstraction claims to
  hide.
- Adding a common case requires changes at every layer.
- The abstraction's API is more general than the underlying capability but
  still leaks its limitations.

**Likely cost**

The abstraction increases both conceptual surface area and change
coordination while failing to provide isolation.

**Possible simplification**

Expose the actual capability directly or redesign the boundary around consumer
needs rather than implementation mechanisms.

**Do not flag when**

The leaked detail is intentionally part of a low-level API and callers require
that control.
