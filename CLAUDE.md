# Superpowers Repository Memory

Each time you complete a task or learn important information about the project, you should update the `CLAUDE.md` file in the repo to reflect any new information that you've learned or changes that require updates to the instruction file.

The repository no longer includes the `adr-generator`, `brainstorming`, `writing-plans`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `test-driven-development`, `using-superpowers`, or `verification-before-completion` skills. Active skills must not depend on those workflows.

## Skill relationships

- `arena` replaces `design-an-interface`. It compares at least three
  structurally distinct interface or module designs against a rubric written
  before dispatch, selects one base, grafts compatible ideas, and records
  rejected alternatives. It remains a design-only workflow.
- `dispatching-parallel-agents` owns partition, race, and mixed execution
  shapes. Interface and module design competitions route to `arena`.
- `blast-radius` is an explicitly invoked change-impact investigation that
  grades safety facts from assertion through live reproduction.
- `validation-scenarios` turns proposed or completed changes into a
  proportional set of risk-based automated, manual, or hybrid validation
  scenarios. It plans observable assurance coverage rather than implementing
  test cases, issuing a code-review verdict, or proving blast-radius safety
  facts.
- `tdd` applies the initial red phase of test-driven development to an
  approved design: it creates compile-valid public contract stubs and
  behaviorally failing tests, then stops before implementation. Unresolved
  interface competitions route to `arena`; requests for validation planning
  without test code route to `validation-scenarios`.
- `technical-writing` owns document mode, information structure, terminology,
  and sentence clarity. `draft-pr` owns ready-to-paste PR title and body
  drafts without creating or updating the PR, and honors the target GitHub
  repository's PR template when one exists. `markdown-toolkit` owns GFM
  mechanics. `unslop` is an explicitly invoked final prose cleanup.
- `unslop` removes every em dash from editable prose. It preserves verbatim
  quotations, code, identifiers, evidence, technical precision, and
  uncertainty while rewriting with periods or commas.
- `bro` explicitly restates the preceding assistant response in plain language.
- `why` investigates historical rationale and separates direct evidence,
  inference, competing hypotheses, and unknowns.
- `show-me-your-work` keeps optional decision trails for long-running work. Its
  logs are session artifacts by default and are never committed without
  approval.
- `code-commenting` includes a comment-audit mode with `KEEP`, `DELETE`,
  `REWRITE`, `ENCODE`, and `INVESTIGATE` classifications.
- `over-engineering-review` is a read-only, evidence-based assessment of
  unnecessary complexity. It owns proportionality and simpler-counterfactual
  analysis; `code-review` remains the broad correctness review, and
  `code-refactorer` implements an approved simplification.
- `defend-the-diff` is an explicitly invoked, read-only-first explainability panel. An isolated questioner asks as many independently tracked material questions as each semantic change unit requires, a defender answers with evidence and self-assessment, and an independent judge verifies the response. Panel roles use persistent agent contexts for follow-up turns when supported; fresh isolated agents receiving the complete accumulated packet are the non-blocking fallback. Callers may identify semantic units explicitly; the skill preserves those boundaries and inventories uncovered changes separately. It proposes code or documentation changes and waits for user approval before editing.

## Skill layout: progressive disclosure

A skill's whole `SKILL.md` body loads on every activation, and Codex CLI
truncates it at 8 KB. Files under `references/` load only when the agent opens
them. Keep `SKILL.md` to frontmatter, when-to-use guidance, the workflow steps
and gates, the output contract, and non-negotiable rules, with a target of
8 KB or less. Put catalogs, long examples, rubrics, templates, and deep detail
in `references/*.md`. Link each reference with a sentence saying when to open
it, for example "Open `references/review-checklist.md` when ...". Bundled
helpers live in `scripts/`; templates and static files live in `assets/`.

`tests/skills/SkillReferences.Tests.ps1` checks that every backticked
`references/`, `scripts/`, or `assets/` path and every relative Markdown link
in a skill's `.md` files exists. Fenced code blocks are ignored. Intentional
illustrative paths are allowlisted in the test. Run it with:

```powershell
Invoke-Pester -Path tests/skills/ -Output Detailed
```

The code-review eval adapters expose `skills/code-review/references/` to the
reviewer: `copilot.ps1` through `--add-dir`, and `template.ps1` by inlining the
files.

## Python Script Execution

### UTF-8 Encoding

When executing Python scripts in this repository, always use UTF-8 mode to handle Unicode characters (emojis, special symbols) in output and file operations:

```bash
PYTHONUTF8=1 python script.py
```

**Why:** Windows console defaults to cp1252 encoding, which doesn't support Unicode characters. The `PYTHONUTF8=1` environment variable enables Python's UTF-8 mode for both console output and file I/O operations.

**Examples:**
- Running init_skill.py: `PYTHONUTF8=1 python skills/skill-creator/scripts/init_skill.py skill-name --path skills`
- Any Python script that uses emojis or non-ASCII characters in print statements or file writes

## PowerShell Usage

The repository uses PowerShell for scripts and automation. When creating new skills or utilities, prefer PowerShell (.ps1) over Python for better Windows integration.

### Strict-mode gotchas (when writing harness/library code)

- `Measure-Object -Sum` over an empty pipeline returns a MeasureInfo whose `Sum` is `$null`; under `Set-StrictMode -Version Latest` accessing `.Sum` throws. Guard with `if (@($items).Count -gt 0)`.
- A function that returns an empty array via `return $errors.ToArray()` is unwrapped by the caller to `$null` unless the call site wraps it: `$x = @(Get-Foo)`.
- String interpolation: `"$var:rest"` is parsed as drive-qualified; use `"${var}:rest"`.
- Suppress `CopyToAsync(...).GetAwaiter().GetResult()` with `[void]`; PowerShell
  can emit a `VoidTaskResult` into the success pipeline and corrupt a structured
  native-process result. Transfer Git NUL-delimited paths through byte streams,
  not PowerShell's text pipeline.

### Worktree and decision-log utilities

`manual-worktree-session` is the large-repository exception to native-first
isolation. Its `scripts/Initialize-ManualWorktree.ps1` creates an external
worktree, pins and verifies HEAD/branch/index/files, and emits orchestration
JSON. Register the ready path with `create_project(path: ...)`, then use
`create_session(workspace_type: 'branch')` without `base_branch`. App tools stay
in the skill, not the helper. Recovery is limited to this helper's recorded
failed initialization and requires stopped-session/no-writer attestations;
it never adopts arbitrary existing worktrees or overwrites surviving files.
Before restoring deleted paths it rejects reparse-point and non-directory
ancestors, preventing checkout through a directory junction.
Run the focused temporary-repository tests with:

```powershell
Invoke-Pester -Path tests/manual-worktree-session -Output Detailed
```

`skills/using-git-worktrees/scripts/Get-WorktreeAudit.ps1` performs a
conservative read-only audit of linked worktrees. It never fetches or removes
worktrees. Run its focused tests with:

```powershell
Invoke-Pester -Path tests/using-git-worktrees/WorktreeAudit.Tests.ps1 -Output Detailed
```

`skills/show-me-your-work/scripts/Add-DecisionLogEntry.ps1` appends normalized
UTF-8 TSV rows, retries concurrent writers, and neutralizes spreadsheet
formulas. Run its focused tests with:

```powershell
Invoke-Pester -Path tests/show-me-your-work/DecisionLog.Tests.ps1 -Output Detailed
```

### Markdown Toolkit

`skills/markdown-toolkit/markdown-toolkit/scripts/validate_markdown.sh` must be
resolved from the loaded skill root, not the user's repository. It uses a
`markdownlint` command on `PATH`, a target-repository
`node_modules/.bin/markdownlint`, or `npx --no-install` without installing
dependencies automatically.

Run its focused tests with:

```powershell
Invoke-Pester -Path tests/markdown-toolkit/MarkdownToolkit.Tests.ps1 -Output Detailed
```

## Address PR Comments Command

`commands/address-pr-comments.md` supports both GitHub and Azure DevOps PRs through a shared provider-neutral workflow. Deterministic provider helpers live in `scripts/address-pr-comments-support.psm1`; focused fixtures and Pester coverage live in `tests/address-pr-comments/`.

Azure DevOps API 7.1 thread status `unknown` is non-actionable; `active` and `pending` are unresolved; `fixed`, `wontFix`, `closed`, and `byDesign` are resolved. Provider timestamps are normalized to UTC without depending on the current culture. Queued Azure DevOps replies are posted from UTF-8-without-BOM JSON payload files, and progress is persisted after each response containing a comment ID.

Status-less Azure DevOps threads are ignored only when all comments are system comments. Actionable threads require an explicit root comment with `parentCommentId: 0`. Remote URLs are credential-redacted before persistence or display, and PR source branches come from the upstream remote ref rather than the local branch name.

The command imports its support module from the installed plugin root (literal `${CLAUDE_PLUGIN_ROOT}` substitution in Claude Code) or the absolute linked-module path supplied by another host, never from the user repository. Null comment or reply collections normalize to empty arrays, and successful reply responses add or update `last_post_timestamp` before progress is persisted.

Run the focused suite:

```powershell
Invoke-Pester -Path tests/address-pr-comments/AddressPrComments.Tests.ps1 -Output Detailed
```

## Skill Evals

Real-model evals follow `evals/_docs/blinding.md`: candidates receive organic
prompts and sanitized project-shaped environments; fixture truth and rubrics
remain outside candidate visibility; comparative judges see randomized neutral
labels and score variants in one pass when possible. Smoke adapters are exempt
from behavioral blinding.

### code-review skill — detection-quality harness

Lives at `evals/code-review/`. Five evaluation dimensions are documented under `design/`; only **detection quality** has a runnable harness in v1.

### Evidence-based finding policy

Build a broad evidence model before generating hypotheses; deepen research in
high-risk areas; derive candidates from gaps or contradictions with verified
contracts/invariants; then verify candidates again before output. Unresolved
concerns may be non-material questions, but are not findings and cannot affect
severity or verdict. Material evidence gaps make the review incomplete rather
than an approval.

The code-review process is single-model. Step 5 is the final self-critique ("Grill Your Assessment"); the skill and eval harness do not delegate critique to additional model families.

**Run the Pester unit tests** (parser, matcher, schema):

```powershell
cd evals/code-review/harness/tests
Invoke-Pester -Path . -Output Detailed
```

**Run the targeted skill-guidance policy tests:**

```powershell
Invoke-Pester -Path evals/code-review/harness/tests/SkillGuidance.Tests.ps1 -Output Detailed
```

**Run the detection eval end-to-end** against the bundled smoke adapter and worked fixtures:

```powershell
cd evals/code-review
./harness/Run-DetectionEval.ps1 `
  -Adapter ./adapters/smoke.ps1 `
  -Fixtures ./fixtures/detection/dev `
  -Trials 1 `
  -OutDir ./results/local
```

The smoke adapter returns canned reviews from `adapters/canned-reviews/<case>.review.md` if present, otherwise a generic LGTM. It's for harness validation only — not a real reviewer.

**Run against GitHub Copilot CLI** (real reviewer; requires `copilot` on PATH and an active session):

```powershell
cd evals/code-review
./harness/Run-DetectionEval.ps1 `
  -Adapter ./adapters/copilot.ps1 `
  -Fixtures ./fixtures/detection/dev `
  -Trials 1 `
  -OutDir ./results/copilot
```

Override the model with `$env:COPILOT_REVIEW_MODEL` (e.g. `claude-opus-4.7`, `gpt-5.3-codex`) and reasoning effort with `$env:COPILOT_REVIEW_EFFORT` (`low`|`medium`|`high`|`xhigh`|`max`).

To wire a different reviewer, copy `adapters/template.ps1` and follow `adapters/README.md` (JSON request on stdin → markdown review on stdout, optional `META: {...}` on stderr).

## Per-commit skill-eval workflow

Issue #7 adds a CI pipeline that runs the per-skill eval suites on push to
main and publishes per-commit headline scores to `gh-pages` as JSON.

**Per-skill contract.** Every skill that wants to be scored ships
`evals/<skill>/run-eval.ps1` — invoked as
`pwsh -File evals/<skill>/run-eval.ps1 -OutDir <path>` — that writes two
files in `<path>`:

- `headline-score.json` — `{schema_version,pattern,headline_score,status,
  metrics,…}`
- `run-detail.json` — `{schema_version,pattern,detail}`

See `evals/_docs/run-eval-contract.md` for the full schema and
`evals/_docs/headline-score-pattern-a.md` for the Pattern A formula
(`100 * caught_in_any / required_bug_count`).

**Scripts** (in `scripts/`):

- `detect-changed-skills.ps1` — emits JSON array of skills whose
  `skills/<S>/` or `evals/<S>/` paths changed. Used by Job 1 of the
  workflow. Special cases:
  - Any change under `evals/_<name>/` (shared eval infra such as
    `evals/_shared/`) triggers a **full sweep** — every skill with a
    `run-eval.ps1` is re-evaluated.
  - `evals/_docs/` is explicitly **excluded** from the full-sweep
    trigger: documentation-only edits never re-run scoring.
  - Initial commits (no `HEAD^`) also fall back to a full sweep so the
    workflow never silently emits nothing.
  - Manual `workflow_dispatch` runs with `skills: all` use `-FullSweep`;
    `skills: foo,bar` uses `-FullSweep -OnlySkills foo,bar`.
- `wrap-eval-output.ps1` — wraps a shard's contract files + git metadata
  into the publishable `history.jsonl` row and `runs/<ts>-<sha>.json`.
- `build-manifest.ps1` — sweeps `data/<skill>/history.jsonl` into
  `data/manifest.json`. Emits per-skill `sparkline` (trailing N rows),
  `biggest_drop_last_10` per skill, and a global `worst_recent_drop`.
  Resolves the `repository` field from `-Repository` > `$env:GITHUB_REPOSITORY`
  > parsing `git remote get-url origin` (used by the dashboard for
  commit-link construction).
- `sync-dashboard.ps1` — copies the dashboard sources from `dashboard/`
  on `main` onto the `gh-pages` checkout. Mirrors `index.html`,
  `skill.html`, and `assets/**`; prunes stale files inside `assets/`;
  never touches `data/`, `.nojekyll`, the root `README.md`, or anything
  outside dashboard-owned paths.
- `init-gh-pages.ps1` — one-shot helper to create the empty `gh-pages`
  orphan branch (must be run once per fresh repo before the workflow can
  publish anything). Dashboard files appear on the first workflow run
  after that.

**Workflow:** `.github/workflows/skill-eval.yml` (three jobs:
detect-changed-skills → eval matrix → publish). The publish job also
runs when only `dashboard/**` changes, so dashboard tweaks reach
`gh-pages` without forcing an eval re-run.

**Run the Pester tests for the workflow scripts:**

```powershell
Invoke-Pester -Path tests/skill-eval/ -Output Detailed
```

**Run the dashboard JS unit tests (node, no browser needed):**

```powershell
Invoke-Pester -Path tests/dashboard/ -Output Detailed
# or directly:
node tests/dashboard/app-tests.mjs
```

**Locally exercise the code-review reference run-eval (smoke adapter):**

```powershell
pwsh -File evals/code-review/run-eval.ps1 -OutDir ./tmp/eval-out
# Then wrap + publish into a local pages dir:
pwsh -File scripts/wrap-eval-output.ps1 `
  -Skill code-review `
  -EvalOutDir ./tmp/eval-out `
  -PagesDir ./tmp/pages `
  -Commit (git rev-parse HEAD)
pwsh -File scripts/build-manifest.ps1 -PagesDir ./tmp/pages
```

Set `$env:EVAL_ADAPTER=copilot` (or any bundled-adapter name) to switch
the reference run-eval to a real reviewer. Set `$env:EVAL_TRIALS=N` to
override the per-case trial count. Both env vars are honored by every
skill's `run-eval.ps1` per the contract in
`evals/_docs/run-eval-contract.md`.

### Configuring the CI workflow

The workflow defaults to the smoke adapter for every skill (free,
deterministic, **not a regression signal**). To switch all skills to a
real reviewer, set a single repo variable:

| Setting | Type | Value |
|---|---|---|
| `vars.EVAL_ADAPTER` | Repo variable | `copilot` (or `smoke`) — applies to every skill's `run-eval.ps1` |
| `vars.EVAL_TRIALS`  | Repo variable (optional) | Integer, e.g. `3` — trials per case where the pattern supports it |
| `secrets.COPILOT_PAT` | Repo secret | User-owned fine-grained PAT (see below) |

**Adapter resolution.** Each skill's `run-eval.ps1` reads
`$env:EVAL_ADAPTER` as a short name (e.g. `smoke`, `copilot`) and
resolves it to `adapters/<name>.ps1` under its own skill directory. So
`EVAL_ADAPTER=copilot` selects `evals/code-review/adapters/copilot.ps1`
today, and `evals/<future-skill>/adapters/copilot.ps1` once a future
skill ships its own copilot adapter. This is intentional: one
workflow-wide knob, one adapter naming convention per skill.

**Manual override.** The workflow's `workflow_dispatch` trigger
exposes an `adapter` input that takes precedence over `vars.EVAL_ADAPTER`
for that one run — useful for testing a real adapter before flipping
the repo-wide default, or for one-off backfills.

**Authentication for the Copilot adapter.** When `EVAL_ADAPTER`
resolves to `copilot`, the workflow installs the Copilot CLI and
exports `COPILOT_GITHUB_TOKEN` + `GH_TOKEN` from `secrets.COPILOT_PAT`
(those are the two env vars the CLI reads, with `COPILOT_GITHUB_TOKEN`
taking precedence). The fine-grained PAT just provides a GitHub
identity for the CLI to authenticate as — your account's Copilot
subscription is what gates Copilot access. For the bundled `copilot.ps1`
adapter the token needs no repo or API permissions; if you later extend
the adapter to fetch GitHub data, add the matching permissions then.

Create the PAT at
https://github.com/settings/personal-access-tokens/new and save it as
`COPILOT_PAT` under **Settings → Secrets and variables → Actions**.

When `EVAL_ADAPTER` does NOT contain `copilot`, the install steps are
skipped to keep CI fast and free.

## Eval dashboard (`dashboard/`)

Issue #8 adds a static GitHub Pages dashboard at the `gh-pages` root
that visualizes the JSON data the per-commit workflow publishes.

- Source files live in `dashboard/` on `main`:
  - `index.html` — landing page (skill grid + biggest-recent-regression callout)
  - `skill.html` — drill-down (`?name=<skill>`), Chart.js line chart, pattern-A detail table, generic-fallback for other patterns
  - `assets/{app.js,styles.css,chart.umd.js,LICENSE.chartjs.md}`
  - `README.md` — vendoring + local-smoke instructions
- Vendored Chart.js v4.5.1 (MIT) lives at `dashboard/assets/chart.umd.js`.
  Source URL + SHA-256 are recorded in `dashboard/README.md`.
- The workflow's `publish` job calls `scripts/sync-dashboard.ps1` to
  mirror these onto `gh-pages` after writing `data/`. Scoped pruning
  means stale `assets/*` files are removed but `data/`, `.nojekyll`, and
  the root `README.md` are preserved.
- All data is rendered via `textContent` / DOM APIs (no `innerHTML`
  interpolation with user-supplied strings) and all paths are relative,
  so the dashboard works at any Pages base path and is XSS-resistant.
- Repo identity (for commit URLs) comes from `manifest.repository`,
  never `window.location` — preventing brittleness on custom domains,
  user-pages sites, and forks.

**Run JS unit tests + dashboard sync tests:**

```powershell
Invoke-Pester -Path tests/dashboard/, tests/skill-eval/Dashboard.Tests.ps1 -Output Detailed
```

**Local smoke test the dashboard against fake data:** see the recipe in
`dashboard/README.md`. Requires a real static server — `file://` won't
work because browsers block local `fetch()`.
