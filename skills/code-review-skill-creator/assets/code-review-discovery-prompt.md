# Code Review Discovery Prompt

Use this prompt with an AI coding agent to analyze a GitHub repository and produce an evidence report documenting the review standards actually enforced by maintainers. The evidence report is the input for the [skill generation prompt](code-review-skill-generation-prompt.md), which produces a reusable code-review skill.

---

## Prompt

```
You are a staff software engineer extracting the actual review standards enforced in a specific GitHub repository. Your goal: investigate the repo's PR history, issue history, and codebase, then produce an evidence report that a separate skill-generation step will use to build a reusable code-review skill.

## Investigation

Perform the analysis below using the GitHub CLI and local tools. Collect findings silently — do NOT output your raw analysis. The investigation informs the generated evidence report; the report is the only output.

### Step 1: Mine PR review history

Run:
gh pr list --state merged --limit 100 --json number,title,body,reviews,files,additions,deletions,labels

For each PR, fetch the review comments (`gh api repos/:owner/:repo/pulls/:number/comments`) and issue-style comments (`gh api repos/:owner/:repo/issues/:number/comments`).

Extract:
1. Recurring categories of reviewer feedback — what classes of issues do maintainers most often flag? (e.g., error handling, null/option safety, async/concurrency, API surface design, allocation/perf, naming, test coverage gaps, log/telemetry hygiene). Track ~3+ independent supporting PRs per category — these become the skill's repo-specific "What to Flag" categories.
2. Patterns that cause PRs to be sent back for changes (requested-changes reviews, repeated revision rounds).
3. Conventions that are enforced informally — phrases like "we usually...", "in this repo we prefer...", "please follow the existing pattern in X".
4. Test-coverage expectations by change type — for which *kinds* of change do reviewers regularly demand tests/benchmarks/docs, what *shape* of coverage they ask for (unit / integration / e2e / approval), and where that coverage lives. These become the skill's test-coverage mapping.

### Step 2: Mine issue history

Run:
gh issue list --state all --limit 200 --json number,title,body,labels,comments

Extract:
1. Recurring bug categories — what classes of defects are reported most often? (e.g., race conditions, regressions in specific subsystems, edge-case handling, platform-specific failures)
2. Root-cause categories — which categories of bugs trace to gaps a reviewer could plausibly have caught? Distinguish those from bugs only catchable with runtime testing or production telemetry.
3. Severity and label distribution — which areas accumulate the most high-severity or regression-tagged issues?

### Step 3: Map the codebase

Without enumerating every file, build a high-level model of the repo:

1. Tech stack — languages, frameworks, build system, target runtimes.
2. Architecture — module/component boundaries, public API surfaces, layering rules, generated-code locations, platform-specific code organization.
3. Change areas — the coherent areas a reviewer would categorize a diff into, the path globs that delimit each, and each area's blast radius (e.g., consumed by every downstream project vs. isolated/experimental). This becomes the skill's change-area table. Also capture, in one phrase, what raises the review stakes for the repo as a whole and what surrounding code reveals that diff-only review would miss.
4. Test layout — where unit tests live, where integration/e2e tests live, snapshot/approval/baseline files (and their locations) if any, ratio of test code to product code, gaps in coverage for critical paths.
5. CI coverage — what is enforced automatically (linters, formatters, type checks, analyzers, test runs, security scans, central package/dependency checks, benchmarks). Anything enforced by CI should NOT appear in the review skill — record it so the generator excludes it.
6. High-risk zones — modules with high churn, recurring bug history, or high complexity. Public/exported APIs. Concurrency primitives. Security-sensitive code (auth, crypto, deserialization, IO boundaries). Platform-specific code.
7. Repo-specific conventions encoded in CONTRIBUTING.md, AGENTS.md, copilot-instructions.md, docs/, .editorconfig, analyzer rule sets, or similar configuration — focusing on conventions maintainers enforce informally that NO analyzer/linter/formatter catches. Also note expected-during-development states a reviewer should NOT flag (e.g., un-regenerated generated files).

## Output: `code-review-evidence.md`

Generate the file using the template in [`code-review-evidence-template.md`](code-review-evidence-template.md), replacing every placeholder with evidence collected during the investigation. The evidence report is for humans who want to audit, tune, or extend the skill, and serves as the input for the skill-generation step.

## Constraints

- Base every finding on evidence from this repo. Cite specific PR or issue numbers in the evidence report.
- If a dimension lacks evidence, note the limitation in the Data Limitations section. Do not pad.
- Exclude anything CI, linters, formatters, or analyzers already enforce — note these in the CI coverage section so the skill-generation step knows what to skip.
```
