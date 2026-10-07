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

### Worktree and decision-log utilities

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

## Vally skill evaluations

Skill evaluations use `@microsoft/vally` and `@microsoft/vally-cli` 0.17.0.
Node.js 22.12 or newer is required. Telemetry must be disabled with
`VALLY_TELEMETRY_OPTOUT=1`.

- `.vally.yaml` defines the `pr`, `main`, and `nightly` suites.
- Each evaluated skill owns `evals/<skill>/eval.yaml`.
- Shared TypeScript graders and reporters live in `evals/_vally/` and compile
  into `evals/_vally/dist/`. Vally loads the emitted JavaScript, not raw
  TypeScript.
- `finding-match` deterministically scores code-review findings by expected
  file region, semantic keywords, verdict floor, and distractor penalties.
  A verdict below the fixture's floor forces the numeric score to zero.
- The `pages-history` reporter appends uniform schema-v2 history and detail
  records. Their schemas reject undeclared fields so raw trajectories cannot
  enter compact Pages history. The `detection` reporter calculates
  catch-in-any across trials.
  Pass rates use Vally's effective scoring threshold, falling back to the
  grader's binary verdict only when no threshold is configured. Execution
  and grader errors remain error records even when the run lifecycle completes.
- `evals/experiments/skill-uplift.experiment.yaml` compares rubric-based skills
  with and without their skill directory. Vally's comparison judge uses
  randomized neutral A/B labels.
- Real-model fixtures follow `evals/_docs/blinding.md`. Hidden truth belongs in
  `grading_environment`, outside the candidate workspace.

Vally 0.17.0 runs environment setup commands in the host's default shell
without injecting the generated `EVALUATE_ASSETS` variable. Do not rely on
that variable in setup commands; validate fixture materialization without a
model before running expensive evaluations. On Windows the default shell is
`cmd.exe`, not PowerShell or Bash.
Code-review fixtures keep `change.patch` as review evidence rather than
applying it: the supplied contextual source snapshots are not uniformly
pre-change, and some diffs are illustrative excerpts.
`evals/_vally/test/fixture-setup.test.ts` materializes all seven cases without
models and checks source preservation, a clean initial worktree, and hidden
expected findings.

Grader infrastructure errors are separate from trial execution errors.
`hadExecutionErrors` alone does not detect failed judges or graders; use
Vally's `hasGraderError(grade)` to distinguish these from valid failing
measurements.
The Pages reporter uses that helper and preserves the failing grader's
diagnostic in `error_message`. Valid failing grades remain normal measurements.

Install and validate the toolchain:

```powershell
npm ci --prefix evals/_vally
$node = (Get-Command node).Source
& $node evals/_vally/node_modules/typescript/bin/tsc --project evals/_vally/tsconfig.json --noEmit
& $node evals/_vally/node_modules/typescript/bin/tsc --project evals/_vally/tsconfig.json
Push-Location evals/_vally
& $node node_modules/vitest/vitest.mjs run
Pop-Location
Invoke-Pester -Path tests/skill-eval/, tests/dashboard/ -Output Detailed
```

Lint all skills and evals with the pinned CLI:

```powershell
$vally = "evals/_vally/node_modules/@microsoft/vally-cli/dist/index.js"
$grader = (Resolve-Path "evals/_vally/dist/graders/finding-match.js").Path.Replace("\", "/")
node $vally lint skills --strict
Get-ChildItem evals -Filter eval.yaml -Recurse | ForEach-Object {
  node $vally lint --eval-spec $_.FullName --grader-plugin $grader --strict
}
```

The GitHub Actions workflow validates deterministic surfaces on pull requests,
runs changed-skill live evals on `main`, publishes the static trend dashboard
to `gh-pages`, and supports manual changed-skill runs. Live Actions runs require
`secrets.COPILOT_PAT`.
Failed changed-skill evaluations still attempt artifact upload and Pages
publication before the workflow reports failure. The manifest keeps legacy
history without requiring Vally metrics and excludes reserved uplift and
canonical-nightly directories from skill discovery.

The expensive three-trial full suite and uplift experiment run locally so they
do not consume GitHub Actions minutes. A Copilot automation can invoke:

```powershell
./scripts/Invoke-VallyNightly.ps1 -Publish
```

Use `-DryRun` to validate discovery and experiment resolution without invoking
models, or `-SkipUplift` to run only the five skill evals. `-Runs` controls both
skill evaluations and uplift trials; the wrapper defaults to three. Direct
Vally experiment runs default to one trial and accept `--param RUNS=3`.
`-Publish` clones the
configured upstream remote's `gh-pages` branch, appends the local run's
per-skill history and detail records, writes a schema-validated canonical
nightly summary and uplift history, synchronizes the dashboard, pushes a
`vally-history/<timestamp>-<sha>` branch, where the timestamp includes
milliseconds to avoid same-commit run collisions, and opens a ready-for-review pull
request targeting `gh-pages`. The source worktree must be clean. If the current
branch has no unambiguous upstream remote, pass `-Remote <name>`. Pass
`-AutomationSessionUrl <url>` when the automation can provide its session link.
Combining `-DryRun -Publish` validates GitHub authentication, remote selection,
and `gh-pages` existence without running models or changing the repository.
Publication PRs are left for manual review and merge, including valid runs that
record a regression or inconclusive uplift.

The Pages dashboard shows pass rate, mean score, pass@k, pass^k, flakiness,
cost, and recent regressions. Detailed trajectories from Actions runs are
stored in the `eval-history-<run-id>` workflow artifact; local nightly
trajectories remain under that run's output directory. Open either source with
Vally's richer dashboard:

```powershell
./scripts/Start-EvalDashboard.ps1 -Latest
./scripts/Start-EvalDashboard.ps1 -RunId <run-id>
./scripts/Start-EvalDashboard.ps1 -ResultsDir <local-results-directory>
./scripts/Start-EvalDashboard.ps1 -Stop
```

The launcher recursively finds `results.jsonl` files and explicitly ingests
each run directory into its SQLite store before serving. Empty result trees
and failed ingestion are errors, not empty dashboards.
