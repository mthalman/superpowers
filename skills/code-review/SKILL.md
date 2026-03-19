---
name: code-review
description: Use when analyzing code changes for correctness, performance, safety, and quality. Provides review criteria, severity classification, and output format for code reviews. Use standalone when reviewing any code changes, diffs, or patches. Triggers on "review my code", "check this for bugs", "audit this change", "is this safe to merge", "what could go wrong", "look at my changes", or requests to evaluate code quality or find risks. For PR walkthroughs, use pull-request-walk-through instead.
---

# Code Review

Review code changes for correctness, performance, safety, and consistency with established patterns. This skill provides the analytical framework — what to look for, how to evaluate it, and how to report findings.

**Reviewer mindset:** Be polite but skeptical. Treat PR descriptions and linked issues as claims to verify, not facts to accept. Question stated direction, probe edge cases, and flag concerns even when unsure. A false approval is far worse than an unnecessary question.

## Review Process

**Context modes:** This skill works in two modes. In **PR mode** (reviewing a pull request), follow all steps including Step 2 (reconcile with PR narrative). In **standalone mode** (reviewing a diff, file, or code snippet without a PR), skip Step 2 and proceed directly from Step 1 to Step 3 — there is no author narrative to reconcile against.

### Step 0: Gather Code Context

Before analyzing, collect code context. **Do NOT read the PR description, linked issues, or existing review comments yet.** Form your own independent assessment before exposure to the author's framing — reading the narrative first anchors your judgment and makes you less likely to find real problems.

1. **Diff and file list**: Get the full diff and changed files.
2. **Full source files**: For every changed file, read the **entire source file** — not just diff hunks. Surrounding code reveals invariants, patterns, and data flow that diff-only review misses.
3. **Consumers and callers**: If the change modifies a public API or shared function, search for callers and usages. Understanding consumption reveals whether changes could break existing behavior or violate caller assumptions.
4. **Related code**: If the change fixes a bug or adds a pattern, check whether similar code elsewhere has the same issue or needs the same fix.
5. **Utility and helper files**: If the diff calls into shared utilities, read those to understand the contracts (thread-safety, idempotency, etc.).
6. **Git history**: Check recent commits to changed files (`git log --oneline -20 -- <file>`). Look for related changes, reverts, or prior fix attempts. This reveals whether the area is actively churning or whether a similar fix was tried and reverted.
7. **Execution context**: If the changed code is invoked by CI/CD pipelines, build systems, or orchestration frameworks, find and read the invocation definitions (pipeline YAML, build scripts, task runners). Determine what runs before and after this code, what preconditions hold at the point this code executes, what data has been produced or transformed by prior steps, and what external state exists (registries, databases, caches) at invocation time.
8. **Data producers**: For any data the changed code consumes, trace it back to its source. Don't assume properties of the data — verify by reading the producer code. Ask: who creates this data? What does it contain? What filtering or transformation has been applied before it reaches this code?

### Step 1: Form Independent Assessment

Based **only** on code context (without PR description):

1. **What does this change actually do?** Describe the behavioral change in your own words. What was the old behavior? What is the new behavior?
2. **Why might it be needed?** Infer motivation from the code itself. What bug, gap, or improvement does it appear to address?
3. **Is this the right approach?** Would a simpler alternative be more consistent with the codebase? Could existing functionality achieve the goal?
4. **What problems do you see?** Identify bugs, edge cases, missing validation, safety issues, performance concerns, test gaps, and anything else that concerns you.

Write down your independent assessment before proceeding.

### Step 2: Incorporate PR Narrative and Reconcile

Now read the PR description, linked issues, existing review comments, and author information. Treat all of this as **claims to verify**, not facts to accept.

1. **Reconcile** your assessment with the author's claims. Where your independent reading of the code disagrees with the PR description, investigate further — do not simply defer to the author's framing.
2. **Update** your assessment if new context genuinely changes your evaluation (e.g., a linked issue proves a bug is real, or an existing review comment already identified the same concern).
3. **Don't soften** findings just because the PR description sounds reasonable. If your independent assessment found problems the narrative doesn't acknowledge, those problems are more likely to be real, not less.

### Step 3: Detailed Analysis

1. **Focus on what matters.** Prioritize bugs, performance regressions, safety issues, race conditions, resource management, incorrect assumptions, and design problems. Do not comment on trivial style issues unless they violate an explicit project convention.
2. **Consider collateral damage.** For every changed code path: what other scenarios, callers, or inputs flow through this code? Could any break or behave differently after this change? Surface plausible risks even if you can't fully confirm them — the tradeoff is the author's decision, your job is to make it visible.
3. **Be specific and actionable.** Every comment should say exactly what to change and why. Include evidence of verification (e.g., "checked all callers — none validate this parameter").
4. **Don't pile on.** If the same issue appears many times, flag it once on the primary location with a note listing all affected files.
5. **Respect existing style.** When modifying existing files, the file's current style takes precedence over general guidelines.
6. **Don't flag what CI catches.** Skip issues that linters, compilers, formatters, or CI will catch automatically.
7. **Avoid false positives.** Before flagging any issue:
   - Verify the concern actually applies given the full context, not just the diff. Confirm the issue isn't already handled by a caller, callee, or wrapper layer.
   - Skip theoretical concerns with negligible real-world probability.
   - If unsure, surface it as a low-confidence question rather than a firm claim. Every comment should be worth the reader's time.
   - Trust the author's codebase knowledge. If a pattern seems odd but is consistent with the repo, assume it's intentional.
   - Never assert that something "does not exist" or "is deprecated" based on training data alone. When uncertain, ask rather than assert.
8. **Ensure code suggestions are valid.** Any code you suggest must be syntactically correct and complete.
9. **Label in-scope vs. follow-up.** Distinguish between issues the PR should fix and out-of-scope improvements that belong in a follow-up.
10. **Context-shift analysis.** When code is moved from one execution context to another (e.g., from one pipeline stage to another, from sync to async, from one service to another), do not assume behavioral equivalence. Explicitly enumerate what changes: what steps have or haven't run before this code now, what external state (registries, databases, file system) differs, what data preconditions that held in the old context no longer hold, and whether the same code pattern produces different outcomes in the new context. Treat "same code, different context" as a high-risk area. The claim "this pattern already existed" is insufficient — verify that the pattern is still correct in the new execution environment.

---

## Severity Classification

| Severity | When to use | Examples |
|----------|-------------|---------|
| ❌ **Error** | Must fix before merge | Bugs, security vulnerabilities, data corruption, missing error handling on critical paths |
| ⚠️ **Warning** | Should fix or needs human judgment | Performance regressions, missing validation, inconsistency with established patterns |
| 💡 **Suggestion** | Consider changing | Readability improvements, minor optimizations, naming clarity |
| ✅ **Verified** | Confirmed correct (use in output) | Important aspects verified as correct — shows the reviewer checked |

If unsure between two levels, choose the higher one.

**Using ✅ Verified:** Include Verified items for non-obvious correctness — things a casual reader might question but that are actually right. Examples: tricky edge case handling that works, thread-safe patterns that look suspicious but are correct, intentional deviation from a convention with good reason. Don't verify trivial or obvious things. A review with only ✅ items is a strong LGTM signal.

---

## Review Output Format

### Structure

```
## 🤖 Code Review

### Holistic Assessment

**Motivation**: <1-2 sentences on whether the change is justified and the problem is real>

**Approach**: <1-2 sentences on whether the approach is sound>

**Summary**: <✅ LGTM / ⚠️ Needs Human Review / ⚠️ Needs Changes / ❌ Reject>. <2-3 sentence verdict with key points. If "Needs Human Review," state which findings you are uncertain about and what a human reviewer should focus on.>

---

### Detailed Findings

#### ✅/⚠️/❌/💡 <Category> — <Brief description>

<Explanation with specifics. Reference code, line numbers, evidence.>

(Repeat for each finding. Group related findings under a single heading.)
```

### Verdict Rules

1. **The verdict must reflect your most severe finding.** If you have any ⚠️ findings, the verdict cannot be LGTM. Only use LGTM when all findings are ✅ or 💡 and you are confident the change is correct and complete.
2. **When uncertain, always escalate.** If you are unsure whether a concern is valid, the verdict must be "Needs Human Review" — not LGTM. A false LGTM is far worse than an unnecessary escalation.
3. **Separate correctness from completeness.** A change can be correct code that is an incomplete approach. If the code is right for what it does but the approach is insufficient (e.g., treats symptoms without root cause, masks errors, fixes one instance but not others), the verdict must reflect the gap.
4. **Classify each ⚠️/❌ finding as merge-blocking or advisory.** Before writing your summary, decide for each: "Would I be comfortable if this merged as-is?" Any "no" → Needs Changes. Any "unsure" → Needs Human Review.
5. **Devil's advocate check.** Re-read all ⚠️ findings before finalizing. Do they represent unresolved concerns? Do not default to optimism because the diff is small or syntactically correct.

### Re-Review (Iteration)

When reviewing updated code after a prior review round:

1. **Focus on what changed.** Re-review the new diff, not the entire PR from scratch. Check whether each prior finding was addressed.
2. **Track prior findings.** For each finding from the previous review, classify it as: resolved, partially addressed, unaddressed, or disagreed-upon.
3. **Handle disagreements with evidence.** If the author disagrees with a finding, evaluate their reasoning. If they provide a valid argument or evidence (test results, documentation, codebase conventions), update or withdraw the finding. If their reasoning is insufficient, restate the concern with additional evidence.
4. **Don't introduce new scope.** A re-review should not raise new issues on unchanged code unless a prior finding's resolution reveals a new problem.
5. **Update the verdict.** The re-review verdict applies to the current state of the code, not relative to the prior review.

### Output Format Adaptation

When used as a **delegate** of the `pull-request-walk-through` skill (file-by-file walkthrough), adapt the output:
- **Skip the Holistic Assessment block** per file — the walkthrough skill handles the opening and closing summaries.
- **Provide findings inline** per file using the severity classification and format from this skill.
- **Save the Holistic Assessment and verdict** for the walkthrough's closing summary (Step 4).

---

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
- **`TryX` methods should return `false` only for the expected failure mode.** Throw for everything else (corruption, invalid arguments).
- **Don't expose mutable state after construction** if values are captured at creation time.
- **New virtual methods must work with unoverridden derived types.** The default implementation must behave equivalently to the pre-existing path.
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

---

## Multi-Model Review

When the environment supports launching sub-agents with different models (e.g., the `task` tool with a `model` parameter), run the review across multiple model families for diverse perspectives. Different models catch different classes of issues.

1. **Select models**: Pick one model from each distinct family (e.g., one Anthropic, one Google, one OpenAI). Use 2-4 models. Pick from models explicitly listed as available — highest capability tier, never "mini" or "fast." Don't select your own model.
2. **Launch in parallel**: Give each agent the same review prompt (diff, review rules, severity format).
3. **Synthesize**: Deduplicate shared findings, elevate issues flagged by multiple models (higher confidence), include unique findings that meet the confidence bar. When models **disagree on severity**, use the higher severity but note the disagreement — the reviewer can downgrade with context the models lack. When models **contradict** each other (one says it's a bug, another says it's correct), present both perspectives and mark the finding as needing human judgment.
4. **Timeout handling**: If a sub-agent hasn't completed after 10 minutes and you have other results, proceed. Note which models contributed.
5. **Present unified review** noting when an issue was flagged by multiple models.

If the environment does not support multiple models, proceed with a single-model review.
