---
description: "Full PR lifecycle — local code review and test loop, PR creation, Copilot review loop, CI verification, and merge conflict resolution"
---

You are orchestrating the complete pull request lifecycle. Follow the phases below in order. The guiding principle is: **any code change triggers a re-run of the local loop before continuing the remote loop.**

## PowerShell Text Safety

**⚠️ CRITICAL (Windows/PowerShell only):** Backticks (`` ` ``) in ANY text passed to `gh` CLI commands are interpreted as PowerShell escape characters (`` `r `` → carriage return, `` `n `` → newline, `` `a `` → bell, `` `v `` → vertical tab, etc.), silently mangling the output. This affects **all** GitHub interactions that post text:

- `gh pr create --body "..."` / `--fill`
- `gh pr comment "..."`
- `gh issue comment "..."`
- `gh api ... -f body="..."`
- Any `--body`, `--message`, or `-f` parameter containing backticks

**For `gh` subcommands that support `--body-file` (pr create, pr comment, issue comment):**

```powershell
# Write text to a temp file, then pass via --body-file
$tempFile = "$env:TEMP\gh-body-$(Get-Random).md"
Set-Content -Path $tempFile -Value $bodyText -Encoding UTF8
gh pr comment 123 --body-file $tempFile
Remove-Item $tempFile
```

**For `gh api` calls (review replies, etc.) — use a PowerShell variable, NOT `@file`:**

```powershell
# ⚠️ BAD — @file syntax does NOT work in PowerShell; posts the literal file path:
gh api "repos/.../comments/123/replies" -f "body=@$tempFile"

# ✅ GOOD — store text in a variable and pass it directly:
$body = "Fixed in abc1234"
gh api "repos/.../comments/123/replies" -f "body=$body"
```

> **Why:** `gh api -f "body=@file"` is supposed to read from a file, but in PowerShell the `@` is not interpreted correctly, resulting in the literal file path being posted as the comment body.

This applies everywhere in this workflow — PR creation, Copilot review replies, issue comments, and any other text posted to GitHub.

## Phase 0 — Context Detection

1. Get the current branch: `git rev-parse --abbrev-ref HEAD`
2. Confirm it is NOT `main` or the repo's default branch. If it is, stop and tell the user.
3. Detect `owner/repo` from git remotes: `git remote get-url origin`
4. Detect the merge base: `git merge-base HEAD origin/main` (or the default branch)

## Phase 1 — Local Loop

Repeat this loop until **all tests pass AND code review is clean**.

### Step 1: Update Branch

Bring the branch up to date with the target branch:

1. Fetch latest: `git fetch origin`
2. Rebase onto target: `git rebase origin/main` (or the repo's default branch)
3. If conflicts arise, resolve them and continue the rebase
4. Force-push if already pushed: `git push --force-with-lease`

### Step 2: Run Tests

1. Detect the test runner from the repo (look for `package.json` scripts, `Makefile`, `pytest`, `dotnet test`, `go test`, etc.)
2. Run the full test suite
3. If tests fail, fix the failures and re-run. Ask the user for guidance if the fix is ambiguous.
4. Tests must be green before proceeding to code review.

### Step 3: Code Review Loop

1. Determine the git range to review:
   - Base: merge-base with target branch
   - Head: current HEAD
2. Dispatch the `superpowers:code-reviewer` agent with the diff range
3. Review the findings:
   - **Critical issues** — must fix
   - **Important issues** — should fix; use judgment, ask user if unclear
   - **Minor/suggestions** — fix if quick and clearly beneficial; otherwise note and move on
   - Not all comments require code changes — use judgment. If a comment is a style nit, a subjective preference, or doesn't apply, it's fine to skip it with a brief rationale.
4. After addressing findings, re-run the `superpowers:code-reviewer` agent
5. Repeat until the review comes back clean (no Critical or Important issues remaining)

### Step 4: Re-run Tests

After code review changes, re-run the full test suite to ensure nothing broke.

### Step 5: Loop Check

- If tests pass AND review is clean → proceed to Phase 2
- If either failed → go back to Step 1

## Phase 2 — Create PR

1. Push the branch: `git push -u origin HEAD`
2. Create the PR:
   ```bash
   gh pr create --fill
   ```
   - If the user has provided a PR title/body, use `--title` and `--body` instead of `--fill`
   - Ask the user if they want to customize the title/body before creating
   - **On PowerShell:** Always use `--body-file` (see PowerShell Text Safety above). Never pass backtick-containing text inline.
3. Capture the PR URL from the output

## Phase 3 — Remote Loop

After the PR is created, run the remote verification loop.

> **Reminder:** When replying to Copilot review comments, posting PR comments, or any other text posted to GitHub, use `--body-file` with a temp file (see PowerShell Text Safety above). Never pass text containing backticks as inline arguments.

### Step 6: Copilot PR Review

Use the `copilot-pr-review` skill workflow:
1. Add `copilot-pull-request-reviewer[bot]` as a reviewer
2. Poll for the review (60s intervals, 15min timeout)
3. Fetch review comments
4. For each comment:
   - Read and understand the feedback
   - Make the fix (one commit per comment)
   - Push
   - Reply to the comment with the fix SHA
   - Resolve the thread
5. Re-request Copilot review
6. Repeat until Copilot review is clean (no comments)

**After making any code changes in this step → re-run Phase 1 (local loop) before continuing.**

### Step 7: CI Verification

1. Check GitHub Actions workflow status:
   ```bash
   gh pr checks <pr_number> --watch
   ```
2. If any workflows fail:
   - Fetch the logs: `gh run view <run_id> --log-failed`
   - Diagnose and fix the failure
   - Push the fix
   - **Re-run Phase 1 (local loop)** since code changed
   - Then re-check CI status
3. All workflows must be green before proceeding.

### Step 8: Merge Conflict Resolution

1. Check for merge conflicts:
   ```bash
   gh pr view <pr_number> --json mergeable --jq .mergeable
   ```
2. If `CONFLICTING`:
   - Fetch and rebase: `git fetch origin && git rebase origin/main`
   - Resolve conflicts
   - Force-push: `git push --force-with-lease`
   - **Re-run Phase 1 (local loop)** since code changed
   - Then re-run from Step 6 (Copilot re-review) and Step 7 (CI)
3. If `MERGEABLE` → PR is ready

## Completion

When all phases are complete, report:

```
═══════════════════════════════════════
PR #<number> is ready for human review!
═══════════════════════════════════════

Title: <pr_title>
URL:   <pr_url>

✅ All tests passing
✅ Code review clean
✅ Copilot review clean
✅ CI workflows green
✅ No merge conflicts
```

## Key Principles

- **Any code change triggers local loop** — whether from code review, Copilot feedback, CI fix, or conflict resolution, always re-run local tests and local code review before continuing
- **One commit per Copilot comment** — never batch fixes
- **Use judgment on review feedback** — not every comment requires a code change; ask the user when uncertain
- **Fail fast** — if something can't be resolved, stop and tell the user rather than looping forever
- **Ask user when needed** — for ambiguous review feedback, PR title/body customization, or complex merge conflicts
