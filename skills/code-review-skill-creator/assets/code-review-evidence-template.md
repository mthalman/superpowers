# Code Review Evidence Report for [repo name]

Generated on [date]. This report documents the evidence behind every repo-specific part of `code-review-skill.md`. Each section below maps to a section the skill-generation step must fill in the skill template.

## Methodology

- Analyzed [N] merged PRs (`gh pr list --state merged --limit ...`).
- Analyzed [N] issues (`gh issue list --state all --limit ...`).
- Inspected codebase structure, CI configuration, and contributor docs.

## Repository Profile

Feeds the skill's intro framing, reviewer-mindset "stakes" clause, and the Step 2 "what surrounding code reveals" note.

- **Identifier**: [owner/repo]
- **Tech stack**: [languages, frameworks, build system, target runtimes]
- **Architecture**: [module/component boundaries, public API surfaces, layering rules, generated-code locations, platform-specific code organization]
- **What raises the review stakes**: [the one-clause reason scrutiny is elevated for this repo — e.g. "a shared SDK every downstream project consumes", "a security boundary", "a public API with broad compatibility guarantees". If nothing elevates the stakes, say so.]
- **What surrounding code reveals**: [the invariants/flows that diff-only review misses here — e.g. "target ordering, item-metadata flow, locking protocols, cross-project call patterns"]
- **CI coverage** (do NOT appear in the skill — listed so the generator excludes them): [linters, formatters, analyzers, type checks, test runs, security scanners, central package/dependency checks — anything CI catches]
- **Test layout**: [where unit tests live, where integration/e2e tests live, snapshot/approval/baseline files if any, ratio of test to product code]
- **Contributor docs consulted**: [CONTRIBUTING.md, AGENTS.md, copilot-instructions.md, docs/, .editorconfig, analyzer rulesets, ...]

## Change Areas & Categorization

Feeds the skill's **Step 3 change-area table**. List the coherent areas of the repo, the path globs that delimit each, and the principle-level class of review concern for each. Mark which areas are highest-blast-radius.

[For each area:]

### [Area name]

- **Paths**: `[path globs that scope this area]`
- **Review focus**: [principle-level — the classes of problems that matter in this area, NOT past bugs]
- **Blast radius**: [high / medium / low — and one phrase on why, e.g. "consumed by every downstream project"]
- **Evidence**: [e.g. "Changed in 22/100 recent PRs; reviewers repeatedly ask about X here. Representative PRs: #1234, #1187."]

## Recurring Problem Categories

Feeds the skill's **Step 4 "What to Flag" repo-specific priority categories**. These are the classes of issue *this repo's* reviewers flag most, that CI does NOT catch. Only include a category with ~3+ independent supporting incidents.

[For each category, ordered by how often/severely it appears:]

### [N]. [Category name — a single durable principle]

- **PR evidence**: [e.g. "Flagged in 18/100 recent PR reviews. Representative PRs: #1234, #1187, #1102."]
- **Issue evidence**: [e.g. "6 issues trace to this category. Representative: #2210, #2188, #2099."]
- **Code evidence**: [e.g. "Pattern appears in [module]; existing tests cover [scenario A] but not [scenario B]."]
- **Why a reviewer (not CI) catches this**: [what about the pattern makes it not automatable today]

## Test Coverage Expectations

Feeds the skill's **Step 4 test-coverage mapping table** and the snapshot/baseline caveat. For each change type maintainers care about, record the shape of coverage they expect and where it lives.

[For each change type:]

### [Change type — e.g. "CLI command behavior", "MSBuild task/target", "generated template output"]

- **Expected coverage**: [the test shape maintainers look for — unit / integration / e2e / approval, and what it must assert]
- **Location**: `[the test project or directory that should hold it]`
- **Evidence**: [e.g. "Reviewers requested this coverage in #1234, #1190; PRs merged without it were later reverted in #1300."]

- **Snapshot/approval/baseline files**: [if the repo has them, note their locations and that regenerating them only proves serializer output. Omit if none.]

## Repository Conventions

Feeds the skill's **Step 4 "Repository convention violations" bullets** and repo-specific **"What NOT to Flag"** exclusions. Capture conventions maintainers enforce informally that NO analyzer/linter/formatter catches.

[For each convention:]

- **[Convention]**: [the rule, phrased as a principle — e.g. "Generated files under `[path]` must not be hand-edited."] — **Evidence**: [where it's documented or where reviewers enforced it: doc path and/or representative PRs]

[Also list expected-during-development exclusions the reviewer should NOT flag — e.g. "missing `.xlf` regeneration", "missing reference-doc regeneration".]

## High-Risk Areas

Feeds the skill's Step 3 "apply extra scrutiny" note (at most 5 areas in the skill). Name the zone and the category of risk, not specific past bugs.

[For each high-risk area:]

### [module or directory]

- **Risk category**: [one short clause — e.g. "concurrency-sensitive; lock ordering and reentrancy invariants"]
- **Churn**: [e.g. "Changed in 22/100 recent PRs."]
- **Bug history**: [e.g. "5 regression issues filed against this module in the analyzed window."]
- **Complexity signals**: [e.g. "Contains 3 functions exceeding 200 lines; lock ordering documented inline."]

## Data Limitations

[Note any dimensions where insufficient data lowered confidence — e.g. "Only 22 of 100 PRs had review comments, so categories below #4 are lower confidence." or "Issue labels are inconsistent, so severity weighting is approximate."]
