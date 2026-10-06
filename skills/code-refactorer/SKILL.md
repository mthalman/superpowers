---
name: code-refactorer
description: Expert code refactoring that strictly preserves existing behavior. Use when asked to refactor code, improve code structure, reduce duplication, extract methods/classes/modules, simplify complex conditionals, improve naming, apply design patterns, reduce complexity, clean up code, make code more maintainable/readable/testable, decompose large functions/classes, or find cross-file patterns and commonalities to consolidate. Language-agnostic. Triggers on requests like "refactor this", "clean up this code", "this function is too long", "reduce duplication", "simplify this logic", "make this more maintainable", "make this more object-oriented", "apply design patterns", "find common patterns", or "what can be consolidated across files".
---

# Code Refactorer

Expert, behavior-preserving code refactoring across languages and paradigms.
The default stance is restraint: refactor only when the structure is the real
problem and the risk is understood.

## Core principles

1. **Preserve behavior exactly.** Change structure, not semantics. Document bugs
   you find; fix them only when explicitly asked.
2. **Assess before changing.** "Do not refactor" and "document instead" are
   valid expert outputs.
3. **Refactor incrementally.** Apply one named refactoring at a time, leaving the
   code working after each step.
4. **Verify with tests.** Run relevant tests before and after. If tests are
   absent, identify characterization tests before risky edits.
5. **Respect local style.** Match naming, formatting, idioms, and architecture.
6. **Minimize blast radius.** Prefer fewer files and lines. Avoid cascading
   renames or public API changes unless requested.
7. **Use proportionality.** Do not add heavyweight patterns to low-risk code or
   quick-fix refactors to high-risk code.

## Step 0: appropriateness gate

Before editing, inspect code-observable signals:

- **Caller count:** high caller count amplifies migration risk.
- **Test coverage:** no tests plus many callers means strategy first.
- **Age and stability:** old, stable code may encode hard-won constraints.
- **Behavioral coupling:** ordered state changes, external calls, retry policy,
  logging checkpoints, or state machines often encode coordination.
- **Performance sensitivity:** tight loops, benchmarks, SLA comments, allocation
  avoidance, or early exits need quantified risk.

| Signal | Response |
|---|---|
| Behavioral coupling plus long stability | Do not refactor by default. Explain the structure instead. |
| Many callers plus no tests | Strategy only: characterization tests, then phased migration. |
| Performance-critical hot path | Quantify `per-call overhead × call volume` before recommending extraction. |
| Recent code, few dependents, experimental branch | Lightweight naming, deduplication, or simplification only. |
| Adequate tests, moderate callers, clear structural issues | Proceed with the standard workflow. |

Always enumerate 3-4 candidate approaches, including **do nothing** and
**document only**, with acceptance or rejection rationale. For the recommended
approach, name branch points: "If X changes, switch to Y." If refactoring is
mandatory despite risk, propose a conservative contingency such as a shadow
implementation or gradual rollout.

## Step 1: adapt to risk

- **High blast radius:** treat as migration. Add characterization tests, keep the
  public interface stable, extract internals, add a new interface, migrate
  callers one by one.
- **Hot paths:** prefer zero-overhead improvements first. Do not extract helper
  calls inside tight loops without benchmarks. Preserve early exits unless data
  proves the cost is acceptable.
- **Behavioral coupling:** investigate why order, timing, retry, and logging
  differ. Default to documentation or naming improvements that preserve control
  flow exactly.

Open `references/refactoring-catalog.md` when you need the smell catalog,
category guidance, OOP pattern guidance, language notes, or before/after
examples for a candidate refactoring.

Open `references/cross-file-discovery.md` when the request asks to find
commonalities across files, consolidate patterns, create shared utilities/base
classes, or reduce codebase-wide duplication.

Open `references/risk-gate.md` when the gate involves old stable code, high caller count, low coverage, hot paths, behavioral coupling, or mandatory-risk contingencies.

## Standard workflow

Use this only after the gate permits refactoring.

1. **Analyze:** read the target code and immediate dependencies. Identify smells,
   complexity hotspots, and test coverage.
2. **Diagnose:** categorize problems and prioritize by impact and risk.
3. **Plan:** propose a sequence of named refactorings. Check contraindications,
   alternatives rejected, trade-offs, and rollback points.
4. **Execute:** apply one refactoring at a time. After each step, confirm the
   code parses or compiles.
5. **Verify:** run tests after each logical group and compare before/after
   behavior.
6. **Summarize:** list each refactoring, what changed, why, validation run, and
   any behavior explicitly preserved.

## Compact decision tree

- **Function too long:** extract cohesive clusters into intent-named methods.
- **Duplicated code:** extract shared logic; for near-duplicates, parameterize
  the varying parts. Wait for a third short instance unless the duplication is
  already costly.
- **Hard to understand:** rename, extract helpers, replace magic values, and
  simplify nesting with guard clauses.
- **Class does too much:** split cohesive responsibilities and reconnect with
  composition.
- **Cannot test:** break hidden dependencies with interfaces, dependency
  injection, or pure-function extraction.
- **Complex conditionals:** use guard clauses and named predicates; use
  polymorphism only when branches repeat and there are enough variants.
- **Cross-file consolidation:** run cross-file discovery before proposing a
  shared abstraction.
- **More object-oriented / design patterns:** apply a pattern only when it solves
  a concrete structural problem and earns the indirection.
- **General cleanup:** remove verified dead code, improve naming, extract long
  methods, reduce duplication, then simplify conditionals.

## Validation and rollback

- Capture the baseline test/build command before editing when feasible.
- Prefer the smallest validation that covers the changed behavior; escalate when
  public APIs, shared utilities, or many callers changed.
- If validation fails, determine whether your refactor changed behavior. Revert
  or narrow the step before continuing.
- Preserve public signatures for high-caller or low-test code. Add adapters or
  overloads instead of breaking callers.
- Report missing tests as risk, not proof of correctness.

## Output contract

Return:

- gate decision and risk signals;
- alternatives considered and rejected;
- ordered refactoring plan or reason not to refactor;
- changes made, grouped by named refactoring;
- validation commands and results;
- preserved behaviors and any remaining risks or follow-ups.
