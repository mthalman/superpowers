# Review Checklist

Detailed catalog of issue classes to consult during Step 4 when the changed code touches the corresponding risk area.

## What to Look For

### Holistic Assessment

Evaluate the change as a whole before reviewing individual lines.

**Motivation & Justification:**
- Does the change articulate what problem it solves and why? Don't accept vague or absent motivation.
- Challenge every addition with "Do we need this?" New code, APIs, and abstractions must justify their existence.
- Demand real-world evidence. Hypothetical benefits are insufficient motivation for expanding surface area.

**Evidence & Data:**
- Performance changes require benchmark evidence — never accept optimization claims at face value.
- Distinguish real performance wins from micro-benchmark noise. Require evidence from realistic, varied inputs.
- Regressions in specific scenarios must be understood and explained, even if there's a net improvement.

**Approach & Alternatives:**
- Does the PR solve the right problem at the right layer? Prefer root cause fixes over workarounds.
- When a PR takes a fundamentally wrong approach, redirect early. Don't iterate on details of a flawed design.
- Always ask "Why not just X?" — prefer the simplest solution. The burden of proof is on the complex approach.

**Cost-Benefit & Complexity:**
- Weigh whether the change is a net positive. A tradeoff that shifts costs around is not automatically beneficial.
- Reject overengineering — complexity is a first-class cost. Unnecessary abstraction for marginal gains is harmful.
- Every addition creates a maintenance obligation. Long-term cost outweighs short-term convenience.

**Scope & Focus:**
- Require large or mixed PRs to be split into focused changes. Each PR should address one concern.
- Defer tangential improvements to follow-up PRs. Even good ideas should wait if they're not part of the core purpose.

**Risk & Compatibility:**
- Flag breaking changes and require documentation. Behavioral changes affecting downstream consumers need explicit acknowledgment.
- Assess regression risk proportional to the change's blast radius. High-risk changes to stable code need proportionally higher value and more thorough validation.

**Codebase Fit:**
- Ensure new code matches existing patterns and conventions. Deviations create confusion.
- Check whether a similar approach has been tried and rejected before. If so, require a clear explanation of what's different.

### Correctness & Safety

**Error Handling:**
- Are error paths handled appropriately? Check for silent failures, swallowed exceptions, uninitialized outputs.
- Include actionable details in error messages — the context needed to diagnose the problem.
- Challenge exception swallowing. When code silently catches and discards errors, question whether the exception represents a truly expected condition or masks a deeper problem. Silently catching errors "that shouldn't happen" hides root causes.
- Ensure output parameters and return values are initialized in all code paths, including error paths.

**Thread Safety:**
- Fields written on one thread and read on another must use appropriate synchronization (atomics, locks, volatile access).
- Watch for race conditions in lazy initialization, caching patterns, and compound check-then-act sequences.
- Use 64-bit counters for timeout calculations to avoid integer overflow.

**Security:**
- Guard integer arithmetic against overflow in size computations, especially multiplication.
- Clean sensitive data (keys, tokens, credentials) after use.
- Don't send credentials proactively without explicit opt-in.
- Limit stack-based allocations with user-controlled sizes.
- Validate and sanitize inputs at trust boundaries.

**Correctness Patterns:**
- Fix root cause, not symptoms. Investigate the source of an issue rather than adding workarounds.
- Prefer safe code over unsafe micro-optimizations without demonstrated performance need.
- Delete dead code, unnecessary wrappers, and unused variables when encountered.
- Prefer correct-by-construction designs over manually maintained parallel data structures.
- Seal types when equality implementations use exact type matching.

### Performance

- **Require benchmark evidence for optimization claims.** Performance changes without numbers have a high probability of being regressions in practice.
- **Avoid premature optimization.** Don't introduce caches, pools, or complex data structures without evidence they're needed. Prefer making the underlying operation faster.
- **Avoid allocations in hot paths.** Watch for closures capturing locals, unnecessary string operations, boxing, and intermediate collections.
- **Pre-allocate collections when size is known.**
- **Place cheap checks before expensive operations.** Order conditionals so cheapest/most-common checks come first.
- **Avoid O(n²) patterns.** Watch for linear scans inside loops, repeated removal from the middle of lists.
- **Allocate resources lazily where possible.** Avoid forcing initialization during startup.
- **Cache repeated expensive calls in locals** when a value is accessed multiple times.
- **Consider scalability, not just throughput.** Evaluate whether solutions hold up at high cardinality or under concurrent load.

### API Design

- **Parameters and contracts must be consistent.** Validate arguments in a consistent order, throw consistent exception types.
- **Follow the project's established API conventions.** Check for existing patterns before introducing new ones.

### Testing

- **Add regression tests for bug fixes and behavior changes.** Every behavioral change needs a test that fails without the fix and passes with it.
- **Test edge cases, error paths, and boundary conditions.** Include empty inputs, negative values, boundary values, and invalid states. Choose inputs that can't accidentally pass if the output wasn't touched.
- **Test assertions must be specific.** Assert exact expected values, not broad conditions like "not null" or "greater than zero."
- **Make test data deterministic.** Avoid culture-dependent, time-dependent, or order-dependent test data.
- **Delete flaky tests rather than patching them.** Do not add tests known to be unreliable.
- **Catch only expected exceptions** in error-path tests. Broad catches mask bugs like undocumented exceptions.

### Code Style

- **Use named constants instead of magic numbers.** Raw hex or decimal constants without explanation are unacceptable.
- **Name methods and variables to accurately reflect behavior.** Update names when behavior changes.
- **Prefer early return to reduce nesting.** Put the error case first, success return last.
- **Narrow warning/lint suppressions to the smallest possible scope.**
- **Match existing style in modified files.** The file's current conventions take precedence over general guidelines.

### Documentation

- **Comments should explain why, not restate code.** Delete comments that just duplicate the code in English.
- **Delete or update stale comments when code changes.** Outdated comments are worse than no comments.
- **Track deferred work with issues, not permanent TODOs.** Reference tracking issues in TODO comments so they can be found and addressed.
- **Don't duplicate documentation** across interface and implementation. Put it on the interface.

### Codebase Consistency

- **Extract duplicated logic into shared helpers.** Fix improvements inside helpers so all callers benefit.
- **Use existing APIs instead of creating parallel ones.** Before introducing new types or helpers, check if existing ones serve the same purpose.
- **Delete dead code and unused declarations aggressively.**
- **Keep PRs focused.** No unrelated refactoring, whitespace noise, accidental file modifications, or build artifacts.
- **Do large refactorings in separate PRs from functional changes.** Separate mechanical changes from logic changes.

### Dependencies & Supply Chain

- **Scrutinize new dependencies.** Every new package introduces supply chain risk and maintenance burden. Verify the package is well-maintained, widely used, and necessary — could the functionality be achieved with existing dependencies or a small utility?
- **Review version bumps.** Check changelogs for breaking changes, security fixes, or behavior changes. Major version bumps deserve extra scrutiny.
- **Watch for dependency sprawl.** Multiple packages solving similar problems (e.g., two HTTP clients, two date libraries) indicate a lack of standardization.
- **Check for known vulnerabilities** in added or updated dependencies when tools are available.

### Observability

- **Ensure changes are diagnosable in production.** New features and error paths should emit appropriate logs, metrics, or traces. If something goes wrong, can an operator figure out what happened?
- **Don't log sensitive data.** Credentials, PII, and tokens must never appear in logs.
- **Preserve existing observability.** If refactoring removes or changes logging/metrics, verify the information is still available through another path.
