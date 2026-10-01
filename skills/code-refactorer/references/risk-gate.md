# Risk Gate

Use this reference when the compact appropriateness gate is not enough to decide
whether a refactor is safe, proportionate, or worth doing.

## What to inspect before editing

- **Caller count.** Search for references to the target function or class. High
  caller counts amplify blast radius, especially when public signatures might
  change.
- **Test coverage.** Check for existing tests. No tests plus many callers means
  characterization tests and migration planning come before code changes.
- **Code age and stability.** Check git history. Code untouched for a long time
  with no bug-fix commits is likely battle-tested; treat apparent mess as
  potentially intentional.
- **Behavioral coupling signals.** Look for state machine patterns, status-field
  updates in sequence, multiple external service calls with specific ordering,
  different retry or backoff strategies for different calls, and logging between
  operations. These patterns often encode implicit coordination.
- **Performance-critical indicators.** Look for tight loops over large data sets,
  performance or SLA comments, benchmark tests, deliberate allocation avoidance,
  and early exits that skip work.

## Gate responses

| Code signal | Recommended response |
|---|---|
| Behavioral coupling plus long stability | Do not refactor by default. Add documentation explaining the structure. |
| Many callers plus no coverage | Strategy only. Start with characterization tests and phased migration. |
| Performance-critical hot path | Quantify first. Estimate `per-call overhead × call volume` before recommending extraction. |
| Recent code, few dependents, experimental branch | Lightweight refactoring only: naming, deduplication of active pain points, or simple local cleanup. |
| Adequate tests, moderate caller count, clear structural issues | Proceed with the standard refactoring workflow. |

After the gate decision, enumerate 3-4 candidate approaches, including **do
nothing** and **document only**, with one-sentence acceptance or rejection
rationale. For the recommended approach, state branch points such as:

- "If [condition X changes], switch to [alternative approach]."
- "If this must be done despite the recommendation against it, then
  [contingency protocol]."

When recommending no refactor, include a mandatory-case contingency such as a
shadow-mode implementation with gradual rollout. When recommending limited
changes, state what would justify deeper refactoring later.

## High-blast-radius code

Treat high-caller, low-coverage code as a migration problem rather than a simple
refactor:

1. Write characterization tests that capture current behavior before changing
   code.
2. Extract internal helpers without changing the public interface.
3. Create a clean interface that delegates to the existing implementation.
4. Migrate callers one by one with per-change verification.

Never change a public method signature when many callers exist and test coverage
is low. Add a new method and deprecate the old one instead.

## Performance-critical hot paths

Quantify before proposing. For each change, reason about
`per-call overhead × call volume`.

Prefer zero-overhead improvements first: cache repeated lookups, eliminate
redundant allocations, and extract constants. Do not extract helper functions
inside tight loops without benchmarking because function-call overhead matters
when multiplied across millions of iterations. Preserve early-exit patterns that
skip computation; they are performance features, not code smells. Guard clauses
that reorder checks may change performance characteristics, so verify data
distributions before recommending them.

Use conditional recommendations, for example: "If benchmarks show >X% headroom,
also consider Y."

## Behavioral coupling

Before changing coupled code, ask why one statement precedes another, why retry
strategies differ, and why a log sits between external calls.

- Different retry/backoff strategies are often tuned to specific failure modes,
  not inconsistent.
- Statement ordering between external calls may prevent race conditions or
  implement implicit locking through database status updates.
- Strategic log placement may serve as audit checkpoints or debugging
  correlation points.

Default to documentation and comments that explain behavioral encoding, not code
changes. If changes are necessary, propose only conservative edits such as names
or constants while preserving ordering, timing, and control flow.

## Request-driven branch points

- **Function too long:** extract cohesive clusters, especially statements
  preceded by a comment or blank line, into methods named after intent.
- **Duplicated code:** extract shared logic. For near-duplicates with the same
  control flow but different names, types, or constants, parameterize the
  varying parts. See the "Unify Near-Duplicate Code" section in
  [the refactoring catalog](refactoring-catalog.md) for detailed examples.
- **Hard to understand:** rename variables and methods, extract well-named
  helpers, replace magic numbers with constants, and simplify nested conditionals
  with guard clauses or early returns.
- **Class does too much:** identify cohesive responsibilities, extract classes,
  and reconnect with composition.
- **Cannot test:** break hidden dependencies with interfaces, dependency
  injection, or pure-function extraction from side-effectful code.
- **Simplify conditionals:** use guard clauses, named predicates, and
  polymorphism only when type-based branches repeat.
- **Cross-file consolidation:** run the cross-file discovery workflow before
  proposing a shared abstraction.
- **More object-oriented or design patterns:** first identify a concrete problem
  such as switch/map dispatch, separated data and behavior, copy-pasted
  cross-cutting concerns, or complex state-dependent conditionals.
- **General cleanup:** prioritize dead-code removal, naming improvements, method
  extraction, duplication reduction, then conditional simplification.

For detailed before/after examples of each refactoring type, see
[the refactoring catalog](refactoring-catalog.md).
