---
name: code-refactorer
description: Expert code refactoring that strictly preserves existing behavior. Use when asked to refactor code, improve code structure, reduce duplication, extract methods/classes/modules, simplify complex conditionals, improve naming, apply design patterns, reduce complexity, clean up code, make code more maintainable/readable/testable, decompose large functions/classes, or find cross-file patterns and commonalities to consolidate. Language-agnostic. Triggers on requests like "refactor this", "clean up this code", "this function is too long", "reduce duplication", "simplify this logic", "make this more maintainable", "find common patterns", or "what can be consolidated across files".
---

# Code Refactorer

Expert, behavior-preserving code refactoring across all languages and paradigms.

## Core Principles

1. **Restraint is expert judgment.** The most valuable refactoring decision is sometimes "don't change this code." Always assess whether changing the code is the right response before proposing changes.
2. **Preserve behavior exactly.** Never change what the code does—only how it's structured. If a bug exists, document it but do not fix it unless the user explicitly asks.
3. **Refactor incrementally.** Apply one refactoring at a time in a logical sequence. Each step should leave the code in a working state.
4. **Verify with tests.** Run existing tests before and after refactoring. If no tests exist, note which behaviors should be tested and offer to write them first.
5. **Respect the codebase style.** Match existing conventions for naming, formatting, indentation, and idioms in the surrounding code.
6. **Minimize blast radius.** Prefer changes that touch fewer files and fewer lines. Avoid cascading renames or restructurings unless specifically requested.
7. **Proportionality.** Match refactoring depth to the code's risk profile. Don't apply heavyweight patterns to low-risk code or quick-fix patterns to high-risk code.

## Step 0: Refactoring Appropriateness Gate

**Before any code changes, assess whether refactoring is the right response.** "Recommend not refactoring" or "document instead" are valid, expert-level outputs.

Assess these code-observable signals:

1. **Caller count.** Search for references to the target function/class. High caller counts amplify blast radius.
2. **Test coverage.** Check for existing tests. No tests + many callers = high risk of undetected behavior changes.
3. **Code age and stability.** Check git history. Code untouched for a long time with no bug-fix commits is likely battle-tested. Treat apparent "mess" as potentially intentional.
4. **Behavioral coupling signals.** Look for: state machine patterns (status field updates in sequence), multiple external service calls with specific ordering, different retry/backoff strategies for different calls, logging between operations. These patterns often encode implicit coordination — do not reorder, extract, or "simplify" them without deep understanding.
5. **Performance-critical indicators.** Look for: tight loops processing large datasets, comments mentioning performance/SLA, benchmarks in the test suite, code that avoids function calls or allocations deliberately.

### Gate Decision

| Code Signal | Recommended Response |
|---|---|
| Behavioral coupling detected (state machines, ordered side effects, varied retry strategies) + long stability in git history | **Don't refactor.** Add documentation explaining the structure instead. |
| Many callers + no test coverage | **Strategy only.** Provide a phased plan starting with characterization tests. No code changes yet. |
| Performance-critical hot path (tight loop, benchmark tests present) | **Quantify first.** Estimate per-call overhead of each proposed change before recommending it. |
| Recently created code, few dependents, experimental branch | **Lightweight refactoring.** Quick wins only — naming, deduplication of active pain points. |
| Adequate test coverage + moderate caller count + clear structural issues | **Proceed with standard refactoring workflow.** |

### Alternative Enumeration

After the gate decision, always enumerate at least 3-4 candidate approaches (including "do nothing" and "document only") with a 1-sentence rejection or acceptance rationale for each. For the recommended approach, identify threshold-based branch points:

- "If [condition X changes], switch to [alternative approach]"
- "If this must be done despite the recommendation against it, then [contingency protocol]"

When recommending "don't refactor," always include a contingency for the mandatory case (e.g., shadow-mode implementation with gradual rollout). When recommending limited changes, describe what would justify deeper refactoring later.

## Step 1: Context-Adapted Analysis

If the gate permits proceeding, adapt your analytical approach based on what you observed:

### High-Blast-Radius Code (many callers, no tests)

- Frame as a **migration problem**, not a refactoring problem
- Use the **strangler fig pattern**: build new interface alongside old, migrate callers gradually
- Phase 1: Write characterization tests capturing current behavior — do NOT change code
- Phase 2: Extract internal helper methods without changing the public interface
- Phase 3: Create a new clean interface that delegates to the existing implementation
- Phase 4: Migrate callers one-by-one with per-change verification
- **Never change a public method signature** when many callers exist and test coverage is low — add a new method and deprecate the old one

### Performance-Critical Hot Paths

- **Quantify before proposing.** For each change, reason about: `per-call overhead × call volume`
- Lead with **zero-overhead improvements**: cache repeated lookups, eliminate redundant allocations, extract constants
- **Do not extract helper functions** inside tight loops without benchmarking — function call overhead matters when multiplied across millions of iterations
- Preserve early-exit patterns that skip computation — these are performance features, not code smells
- Guard clauses that reorder checks may change performance characteristics — verify data distributions
- Provide **conditional recommendations**: "If benchmarks show >X% headroom, also consider Y"

### Behavioral Coupling (ordered side effects, state machines, distributed calls)

- Investigate before changing anything: Why is this statement before that one? Why are retry strategies different? Why is this log between those calls?
- Different retry/backoff strategies are often **tuned to specific failure modes**, not inconsistent
- Statement ordering between external calls often prevents race conditions or implements implicit locking via DB status updates
- Strategic log placement may serve as audit checkpoints or debugging correlation points
- Default output: **documentation and comments explaining the behavioral encoding**, not code changes
- If changes are necessary: propose only the most conservative changes (naming, constants) while preserving all ordering, timing, and control flow

## Refactoring Workflow (Steps 2-7)

Use this workflow when the Appropriateness Gate indicates standard refactoring is appropriate.

2. **Analyze** — Read the target code and its immediate dependencies. Identify code smells, complexity hotspots, and structural issues. Note existing test coverage.
3. **Diagnose** — Categorize the problems found (duplication, long method, feature envy, etc.). Prioritize by impact and risk.
4. **Plan** — Propose a sequence of named refactorings. For each technique, check its contraindications (see below). Present the plan with **alternatives considered and rejected, with rationale.** Include trade-off reasoning for each decision.
5. **Execute** — Apply each refactoring one at a time. After each step, confirm the code compiles/parses cleanly.
6. **Verify** — Run tests after each logical group of changes. Compare before/after behavior.
7. **Summarize** — List every refactoring applied, what changed, and why.

## Identifying Code Smells

Scan for these common smells to determine what refactoring is needed:

| Smell | Symptom | Typical Refactoring | Contraindication |
|---|---|---|---|
| Long Method | Function > ~20 lines or does multiple things | Extract Method | Hot path with high call volume — function call overhead matters. Behavioral coupling — ordering may be intentional. |
| Large Class | Class has too many responsibilities | Extract Class, Move Method | Many external dependents — use strangler fig instead. |
| Duplicated Code | Same logic in 2+ places | Extract Method/Function, Pull Up | Hot path — inlining may be deliberate for performance. |
| Near-Duplicate Code | Structurally similar blocks with minor variations | Parameterize differences, extract shared template | Blocks may diverge in the future (different domains). Only 2 instances + short — wait for a third (Rule of Three). |
| Feature Envy | Method uses another class's data more than its own | Move Method | Many callers depend on current location. |
| Data Clumps | Same group of fields/params appear together | Extract Class/Record | — |
| Primitive Obsession | Overuse of primitives instead of small objects | Replace Primitive with Object | — |
| Long Parameter List | Function takes > 3-4 parameters | Introduce Parameter Object | Many callers + no tests — add new overload with deprecation instead of changing signature. |
| Divergent Change | One class modified for unrelated reasons | Extract Class | — |
| Shotgun Surgery | One change requires edits across many classes | Move Method, Inline Class | — |
| Switch Statements | Repeated switch/if-else on same type field | Replace Conditional with Polymorphism | Fewer than 3 branches or pattern doesn't repeat. |
| Speculative Generality | Unused abstractions "for the future" | Collapse Hierarchy, Inline Class | — |
| Dead Code | Unreachable or unused code | Remove Dead Code | Verify via grep/search that code is truly unreachable — feature flags or reflection may use it. |
| Comments as Deodorant | Comments explaining confusing code | Rename, Extract Method (make code self-documenting) | Comments may explain *why* (business rules, edge cases) — preserve those. Only remove comments that explain *what* when the code is made self-explanatory. |
| Cross-File Duplication | Same logic pattern repeated across multiple files with only entity/field names varying | Extract shared base class, factory function, decorator, or utility module (see Cross-File Pattern Discovery) | Instances in different bounded contexts — coupling is worse than duplication. Pattern still evolving — premature abstraction. Only 2 short instances — Rule of Three. |

## Refactoring Decision Tree

Determine the refactoring approach based on the request:

**"This function/method is too long"** → Extract Method. Identify clusters of related statements, especially those preceded by a comment or blank line. Each cluster becomes a method named after its intent.

**"There's duplicated code"** → Extract shared logic into a common function/method. If duplication is across classes, consider Extract Superclass or a shared utility. Also scan for *near-duplicates*: code blocks with the same control flow but different names, types, or constants. Parameterize the varying parts into a shared function. See the "Unify Near-Duplicate Code" section in [references/refactoring-catalog.md](references/refactoring-catalog.md) for detailed examples.

**"This is hard to understand"** → Rename variables/methods for clarity, extract well-named helper methods, replace magic numbers with named constants, simplify nested conditionals with guard clauses or early returns.

**"This class does too much"** → Identify distinct responsibilities. Extract Class for each cohesive group of fields and methods. Use composition to reconnect.

**"I want to add tests but can't"** → Identify and break hidden dependencies. Extract interfaces, inject dependencies, extract pure functions from side-effectful code.

**"Simplify these conditionals"** → Apply guard clauses for early returns, decompose complex boolean expressions into named methods, consider Replace Conditional with Polymorphism for type-based switching.

**"Find common patterns across files"** or **"What can be consolidated?"** → Use the Cross-File Pattern Discovery workflow. Start with structural reconnaissance (parallel names, shared imports, repeated signatures), then deep-analyze each candidate cluster, then plan consolidation with explicit migration order.

**"General cleanup"** → Prioritize: dead code removal → naming improvements → extract method for long functions → reduce duplication → simplify conditionals.

## Guidelines Per Refactoring Category

### Extraction Refactorings

- Name extracted methods/functions after *what* they do, not *how*
- Prefer pure functions (no side effects) when extracting
- Keep extracted units at a single level of abstraction
- Pass only the data the extracted unit needs—avoid passing entire objects when only one field is used

### Simplification Refactorings

- Replace nested if/else with guard clauses (early returns) when possible
- Decompose compound boolean expressions: `if (isValid(x) && isAuthorized(user))` over `if (x != null && x.status == 1 && user.role == "admin")`
- Prefer polymorphism over repeated type-checking switches only when there are 3+ branches and the pattern repeats

### Moving Refactorings

- Move a method to the class whose data it primarily uses
- Group related functions into modules/namespaces by cohesion
- When moving, update all callers and re-run tests

### Naming Refactorings

- Use domain language from the codebase's ubiquitous language
- Variables: describe the *value* (`remainingRetries` not `r` or `count`)
- Functions: describe the *action and result* (`calculateTotalPrice` not `process`)
- Booleans: use `is/has/can/should` prefix (`isValid`, `hasPermission`)

## Cross-File Pattern Discovery

When asked to reduce duplication, find common patterns, or improve consistency across a codebase, perform a systematic cross-file search before proposing changes. This goes beyond spotting duplication in code you can already see — it actively hunts for structural commonalities scattered across the project.

### When to Use Cross-File Discovery

- User says "find duplication across the codebase" or "what can be consolidated"
- You notice a pattern in one file and suspect it repeats elsewhere
- Refactoring a single file reveals it follows a pattern shared by sibling files
- User asks for a "shared utility," "base class," or "common abstraction"

### Discovery Workflow

#### Phase 1: Structural Reconnaissance

Map the codebase structure to identify likely duplication zones:

1. **Identify parallel hierarchies.** Search for files/directories with parallel naming (e.g., `UserService`, `OrderService`, `ProductService`; or `user_handler.py`, `order_handler.py`). Parallel names strongly predict parallel implementations.
2. **Scan import/dependency patterns.** Search for commonly imported modules. Files importing the same set of dependencies often contain similar logic.
3. **Find repeated function signatures.** Search for functions with similar names or parameter shapes across files (e.g., `validate*`, `handle*`, `process*`, `create*`).
4. **Check for repeated error handling.** Search for `try/catch`/`try/except` blocks, retry logic, or error-wrapping patterns that appear in multiple files.
5. **Look for boilerplate markers.** Search for similar comment blocks (e.g., `// TODO: extract`, `# same as in X`), copy-paste artifacts, or structurally identical code blocks.

#### Phase 2: Deep Pattern Analysis

For each candidate pattern cluster found in Phase 1:

1. **Collect all instances.** Gather every file containing the pattern. Read each instance fully — don't stop at 2-3 examples.
2. **Diff the instances.** Identify exactly what varies between instances (field names, types, constants, callbacks, config values) vs. what is invariant (control flow, error handling structure, sequencing).
3. **Classify the pattern.** Determine which cross-file pattern type it matches (see table below).

#### Phase 3: Consolidation Planning

For each validated pattern:

1. **Design the abstraction.** Choose the right consolidation strategy (see "Cross-File Pattern Types" below). The abstraction should make the varying parts explicit parameters while encapsulating the invariant structure.
2. **Assess blast radius.** Count how many files change. Identify callers of each instance. Check test coverage across all affected files.
3. **Plan the migration order.** Start with the simplest instance as a proof-of-concept. Migrate remaining instances incrementally, verifying tests after each.
4. **Define the "stop extracting" boundary.** Not every instance needs to use the shared abstraction. Instances that are diverging or have unique constraints may be better left alone.

### Cross-File Pattern Types

| Pattern | How to Detect | Consolidation Strategy | Watch Out For |
|---|---|---|---|
| **Parallel entity handlers** — Same CRUD/workflow logic repeated per entity (User, Order, Product) | Search for functions named `create*`, `update*`, `delete*` across service/handler files | Generic handler factory, base class with entity-specific overrides, or higher-order function | Entity-specific business rules that break the abstraction — keep hooks/extension points |
| **Scattered validation logic** — Same validation rules reimplemented in multiple places | Search for regex patterns, range checks, or format validations on the same field type | Shared validator module with composable rules | Validation rules that look identical but have context-dependent edge cases |
| **Repeated data transformation** — Same mapping/conversion logic across files | Search for similar `.map()` chains, field-by-field copies, or serialization patterns | Shared mapper/transformer functions or a mapping registry | Transformations that will diverge as schemas evolve independently |
| **Copy-pasted error handling** — Identical try/catch structures with logging, retry, fallback | Search for similar catch blocks, retry loops, or error-wrapping patterns | Error-handling middleware, decorators, or wrapper functions | Error handlers that look similar but have intentionally different retry/fallback strategies |
| **Repeated configuration/setup** — Same initialization boilerplate across modules | Search for similar constructor patterns, config loading, or connection setup | Factory functions, builder pattern, or shared config module | Setup that looks boilerplate but encodes environment-specific tuning |
| **Parallel test structures** — Same test setup/teardown/assertion patterns across test files | Search for similar `beforeEach`/`setUp` blocks and assertion sequences | Shared test fixtures, custom assertion helpers, or test base classes | Test readability — over-abstracting tests makes failures harder to diagnose |
| **Duplicated middleware/decorators** — Same cross-cutting concern (auth, logging, caching) reimplemented per endpoint | Search for repeated auth checks, logging calls, or cache-key patterns at function boundaries | Extract middleware, decorators, or aspect-oriented wrappers | Middleware that looks identical but has endpoint-specific behavior embedded |
| **Structural near-duplicates** — Functions with identical control flow but different field/type references | Search for functions with same line count and same branching structure in related files | Parameterize differences via callbacks, generics, or configuration objects | Apparent similarity masking genuinely different domain logic |

### Search Techniques

Use targeted searches to find each pattern type. Here are effective search strategies:

**Find parallel naming conventions:**
- Search for files matching patterns like `*Service*`, `*Handler*`, `*Controller*`, `*Repository*`
- Within those files, compare exported function/method names

**Find repeated logic by signature:**
- Search for common function name prefixes: `validate`, `parse`, `format`, `convert`, `handle`, `process`, `create`, `build`
- Search for similar parameter patterns: functions taking `(req, res)`, `(ctx, input)`, or `(id, options)`

**Find structural duplication by markers:**
- Search for identical import blocks across files
- Search for similar error messages or log strings — they often bracket duplicated logic
- Search for the same sequence of method calls (e.g., `validate → save → notify`) across files

**Find copy-paste artifacts:**
- Search for comments referencing other files: `same as`, `copied from`, `see also`, `similar to`
- Search for identical magic numbers or string constants across files
- Search for TODO/FIXME comments about duplication: `extract`, `consolidate`, `DRY`, `shared`

### Cross-File Discovery Contraindications

Do **not** consolidate when:

- **Instances are in different bounded contexts** (e.g., billing vs. shipping). Similar code across domain boundaries is often *intentional* duplication — coupling them creates a worse problem than the duplication.
- **Consolidation requires more than 3 parameters to handle variation.** If the abstraction needs many configuration knobs to cover all instances, the "shared" code may be harder to understand than the duplicates.
- **Only 2 short instances exist.** Apply the Rule of Three — wait for a third occurrence before extracting. Two instances may be coincidence; three confirms a pattern.
- **Test coverage is low across the affected files.** Cross-file refactoring with inadequate test coverage is high risk. Write characterization tests first.

### Output Format for Cross-File Analysis

When reporting cross-file patterns, structure your findings as:

1. **Pattern summary** — One sentence describing the repeated structure
2. **Instances found** — List every file and location containing the pattern
3. **Invariant vs. varying parts** — What's shared and what differs between instances
4. **Recommended abstraction** — The proposed consolidation with rationale
5. **Migration plan** — Order of changes, starting with the simplest instance
6. **Exceptions** — Instances that should NOT be consolidated, with reasons

## Language-Specific Notes

Adapt refactoring to language idioms:

- **Python**: Prefer list comprehensions over map/filter chains; use `@property` when extracting computed attributes; leverage `dataclass` or `NamedTuple` for data clumps
- **JavaScript/TypeScript**: Prefer destructuring for parameter objects; use optional chaining to simplify null checks; extract custom hooks in React
- **Java/C#**: Leverage interfaces for dependency inversion; use records/data classes for data clumps; prefer streams/LINQ for collection transformations
- **Go**: Extract functions over methods when no state is needed; use interfaces implicitly; keep packages focused on one responsibility
- **Rust**: Extract traits for shared behavior; use `impl` blocks to group related methods; leverage pattern matching over if-else chains

For detailed before/after examples of each refactoring type, see [references/refactoring-catalog.md](references/refactoring-catalog.md).
