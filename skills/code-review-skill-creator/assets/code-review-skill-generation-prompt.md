# Code Review Skill Generation Prompt

Use this prompt with an AI coding agent to transform a `code-review-evidence.md` report (produced by the [discovery prompt](code-review-discovery-prompt.md)) into a reusable, self-contained code-review skill.

The generated skill follows a fixed **Step 1–6 procedural skeleton** (checkout → gather context → categorize → review → present findings → post review). Repo-specific knowledge is woven *into* that skeleton — the change-area table, the impact-analysis surfaces, the test-coverage mapping, the "What to Flag" priority categories, and the convention list — rather than abstracted into a separate rule list. The skeleton, the GitHub-tool calls, the dual PR-review/local-review mode handling, and the present-then-post flow are identical across repos; only the bracketed parts are synthesized per repo.

---

## Prompt

```
You are a staff software engineer synthesizing a reusable code-review skill from an evidence report. The evidence report (`code-review-evidence.md`) was produced by a prior investigation of this repository's PR history, issue history, and codebase. Your job: read the evidence, apply the synthesis rules below, and produce a self-contained skill an AI agent can use when reviewing any future PR for this repo.

## Input

Read `code-review-evidence.md` in the current directory. This report contains:
- Repository profile (tech stack, architecture, CI coverage, test layout)
- Change areas & categorization (module/component map with path globs)
- Recurring problem categories (what reviewers most often flag)
- Test coverage expectations by change type
- Repository conventions (informally enforced, not analyzer-caught)
- High-risk / high-blast-radius areas
- Data limitations

## Output: `code-review-skill.md`

Generate the file using the template in [`code-review-skill-template.md`](code-review-skill-template.md). Preserve the YAML frontmatter, the headings, and the Step 1–6 ordering **exactly**. Replace every `[bracketed placeholder]` with content synthesized from the evidence report, and remove every `GENERATOR GUIDANCE` HTML comment from the final file. The bracketed parts you fill are:

- The intro problem categories and the reviewer-mindset "stakes" clause.
- The Step 2 note on what surrounding code reveals in this repo.
- The Step 3 **change-area table** (area → path globs → principle-level review focus).
- The Step 4 impact-analysis **affected surfaces** and **regression-risk vectors**.
- The Step 4 **test-coverage mapping** table (change type → expected test shape + location).
- The Step 4 **"What to Flag" repo-specific priority categories** (lead the list) and the **repository-convention-violation** bullets.
- The Step 4 **"What NOT to Flag"** repo-specific exclusions (including this repo's CI-enforced checks).

Leave the durable universal "What to Flag" categories, the checkout flow, the PR-review/local-review mode split, the MCP-tool calls, the severity scale, and the present/post steps as-is except for renumbering and dropping any universal category that genuinely does not apply to this repo.

## Synthesis Rules

The generated skill must describe **durable principles**, not enumerate specific past incidents. The reader should not be able to reverse-engineer which PRs or bugs were analyzed by reading the skill.

### The durability test

Before including any area, category, check, or example, apply this test:

> "Would this still be valuable five years from now, even if every file mentioned was renamed and every bug observed had been fixed?"

If the answer is "no" because it is tied to a specific recent incident, generalize it or drop it. If you cannot generalize without losing meaning, the finding is too narrow to belong in the skill.

### Hard rules

1. **No incident traces.** Never include a phrase that obviously originated from a specific PR or bug. Forbidden specificity includes:
   - Named string literals from real cases (specific flag names, URL schemes, error messages, config values).
   - Scenario descriptions that read like a bug title ("where a malicious value could redirect a build", "when the manifest is missing", "if the user passes a path containing `..`").
   - Lists of specific vulnerable code constructs derived from a single CVE or bug report.
2. **Frame checks as principles, not scenarios.** Prefer "Verify X" or "Ensure Y" over "Watch for Z, e.g., specific-bad-thing." If a check has an "e.g.," followed by a concrete bug, the check *is* the bug, not the principle — rewrite it. This applies to every area-table review-focus cell, every regression-risk vector, every "What to Flag" category, and every convention bullet.
3. **Each "What to Flag" category is one durable principle.** A repo-specific category is a single class of problem ("MSBuild property/item/target semantics", "asset-graph invariant violations"), not a bundle of unrelated subsystems welded together because they all had bugs. If a category needs a list of distinct scenarios to be understood, it is multiple categories — split it. Do not attach a per-category severity; severity is assigned at finding time in Step 5 based on real impact.
4. **The change-area table maps structure, not history.** Each row delimits *where* a class of review concern applies using path globs as scope markers, and states the *category of risk* there — never "what went wrong there." Acceptable focus: "target ordering and item-metadata flow across build/pack/publish." Not acceptable: "the bug where pack dropped content metadata."
5. **File paths only as scope markers, never as targets.** Use a directory like `src/Foo/` to delimit where a rule applies, not to imply what went wrong there.
6. **Categories must be principles, not subsystems.** "Async cancellation propagation" is a principle. "Security and input validation in installer, container, and parsing code" is three subsystems welded together — split or generalize.
7. **Exclude anything CI, linters, formatters, or analyzers already enforce.** Use the CI coverage section of the evidence to identify what is already automated, and list it under "What NOT to Flag" so the reviewer doesn't re-flag it.
8. **Exclude generic platitudes** ("write clean code", "follow best practices"). If something is true of every codebase ever, it does not belong in a repo-specific skill — and the durable universal "What to Flag" categories already cover the cross-repo basics.
9. **If a dimension lacks evidence, omit it.** Delete the placeholder and keep the surrounding durable text rather than padding. Do not invent area rows, coverage-mapping rows, or convention bullets that the evidence does not support.

### Consolidation

After drafting the repo-specific parts, re-read them as a set and ask:

- Do two or more "What to Flag" categories or area rows describe the same underlying principle from different angles? Merge them.
- Does any repo-specific category or area appear from fewer than ~3 independent supporting incidents in the evidence? Drop it (the durable universal categories still cover the basics).
- Could a reader summarize each category in one sentence without losing meaning? If not, simplify.
- **Does any category bundle distinct concerns that each have independent supporting evidence?** Split them. Common bundling traps:
  - *Quality of a new addition* vs *compatibility of changing an existing one* — different review questions with different evidence.
  - *Code-level correctness* vs *cultural/convention adherence* — the former is largely covered by the universal categories; the latter belongs in the convention-violation bullets.
- **Do not exclude cultural conventions just because they look like "style".** Conventions maintainers enforce informally but no analyzer catches (idiomatic patterns, repo-specific naming, structural conventions for parallel implementations) belong in the convention-violation bullets — unlike formatting CI already enforces.

Scale the repo-specific "What to Flag" categories and area rows to the repo's complexity — aim for the fewest that cover the recurring review themes. A single-purpose repo may need only 2–3 repo-specific categories and a handful of area rows; a large monorepo spanning multiple domains may justify more. Every repo-specific category must still pass the durability test and have ~3+ independent supporting incidents.

## Final Constraints

- **Write the output file as UTF-8 without BOM.** The skill contains emoji (🤖, ✅, ⚠️, ❌, 💡, 📝) and em-dashes that get mangled (e.g., `��` replacement chars) when saved with the wrong encoding. On Windows, default `Out-File` / `Set-Content` encodings will corrupt these — use `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))` or an equivalent that guarantees UTF-8 without BOM.
- Cite specific PR or issue numbers **never** — those belong only in the evidence report.
- Synthesize durable principles; do not list incidents. The skill must remain useful for future PRs that look nothing like past ones, and a reader must not be able to identify the source PRs from the skill text.
- Exclude anything CI, linters, formatters, or analyzers already enforce — by construction, every repo-specific check in the skill is something CI cannot catch.
- Preserve the Step 1–6 skeleton, the GitHub-tool calls, the PR-review/local-review mode split, the severity scale, and the present-then-post flow exactly. Do not invent new top-level sections or reorder steps.
- If a bracketed section would have to be filled with generic content, delete the placeholder and keep the surrounding durable text instead.
- The skill must be self-contained — an AI agent should be able to apply it without reading the evidence report or this meta-prompt.
- Remove every `GENERATOR GUIDANCE` HTML comment from the final skill.

### Self-audit before emitting the skill

After drafting `code-review-skill.md`, re-read it once and answer YES/NO for each:

1. Could a reader identify any specific PR or bug analyzed by reading any area row, category, or convention bullet? (must be NO)
2. Does any check contain a named string literal, error message, URL, flag, or scenario taken from a real incident? (must be NO)
3. Is any "What to Flag" category a wrapper around multiple unrelated subsystems just because they all had recent bugs, or does any category carry a pre-enumerated severity? (must be NO)
4. Are the Step 1–6 headings, frontmatter, GitHub-tool calls, and severity scale preserved verbatim, with all `GENERATOR GUIDANCE` comments removed? (must be YES)
5. Would every area row, category, and convention bullet still be valuable five years from now if every file mentioned were renamed? (must be YES)

If any answer is wrong, revise the skill before emitting it.
```
