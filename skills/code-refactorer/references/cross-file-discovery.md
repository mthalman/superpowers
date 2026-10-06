# Cross-File Discovery

Use this reference when searching for repeated patterns across files and planning safe consolidation.

## Workflow

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
