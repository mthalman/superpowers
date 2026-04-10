---
name: copilot-pr-review
description: "Full GitHub Copilot PR review feedback loop — add Copilot as reviewer, poll for review, respond to comments, resolve threads, re-request review, and repeat until clean. Use when the user asks to 'run Copilot review', 'get Copilot feedback', 'request Copilot PR review', or when a PR needs automated code review from the Copilot reviewer bot."
---

# Copilot PR Review

Run the full GitHub Copilot code reviewer feedback loop on an open pull request: add Copilot as reviewer, poll for its review, respond to each comment, resolve threads, re-request review, and repeat until clean.

**Bot identity:** `copilot-pull-request-reviewer[bot]`

> **WARNING:** The bot login is NOT `Copilot`, NOT `copilot[bot]`, NOT `github-copilot`.
> It is exactly `copilot-pull-request-reviewer[bot]`. Using the wrong name will
> silently fail or return "not found".

## Prerequisites

- `gh` CLI installed and authenticated
- An open pull request
- The authenticated user must have write access to the repo

## Context Detection

1. Infer `owner/repo` from git remotes: `git remote get-url origin`
2. Infer PR number from current branch: `gh pr view --json number --jq .number`
3. If either cannot be inferred, ask the user

## Workflow

### Step 1 — Add Copilot as reviewer

Use the GitHub API directly. `gh pr edit --add-reviewer` does NOT work for bot accounts.

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/requested_reviewers" \
  --method POST \
  -f 'reviewers[]=copilot-pull-request-reviewer[bot]'
```

**Verification:** Confirm the reviewer was set:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/requested_reviewers" \
  --jq '.users[].login'
```

### Step 2 — Poll for Copilot's review

Poll the reviews endpoint until a review from `copilot-pull-request-reviewer[bot]` appears.

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/reviews" \
  --jq '[.[] | select(.user.login=="copilot-pull-request-reviewer[bot]")] | length'
```

**Polling parameters:**
- **Interval:** 60 seconds between checks
- **Timeout:** 15 minutes (15 attempts)
- **Detection:** Review count > 0 means Copilot has reviewed

**Full detection query** (returns review state and comment count):

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/reviews" \
  --jq '.[] | select(.user.login=="copilot-pull-request-reviewer[bot]") | {id: .id, state: .state, submitted_at: .submitted_at}'
```

### Step 3 — Fetch review comments

After a review is detected, fetch the individual line-level comments:

```bash
REVIEW_ID=$(gh api "repos/{owner}/{repo}/pulls/{pr_number}/reviews" \
  --jq '[.[] | select(.user.login=="copilot-pull-request-reviewer[bot]")][-1].id')

gh api "repos/{owner}/{repo}/pulls/{pr_number}/reviews/$REVIEW_ID/comments" \
  --jq '.[] | {id: .id, path: .path, line: .line, body: .body}'
```

If the review body says "generated no comments", no action is needed — the PR is clean.
If it says "generated N comments", proceed to Step 4.

### Step 4 — Respond to each comment

For EACH comment, make a fix and create ONE commit per comment:

1. **Read the comment** — understand what Copilot is asking for
2. **Make the fix** in the appropriate file(s) on the PR branch
3. **Commit** with a semantic message describing the fix
4. **Push** the commit to the PR branch

**Reply to the comment thread** after pushing:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies" \
  --method POST \
  -f "body=Fixed in {commit_sha}"
```

**PowerShell equivalent:**

```powershell
$body = "Fixed in <commit_sha>"
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies" -f "body=$body"
```

> **⚠️ PowerShell:** Do NOT use `-f "body=@$tempFile"` — the `@file` syntax does not work in PowerShell and will post the literal file path. Always store the body in a variable and pass directly: `-f "body=$bodyVar"`.

### Step 4.5 — Resolve the conversation thread

After replying to each comment, **resolve the review thread** using the GraphQL API.

**Find the thread ID** for the comment:

```bash
THREAD_ID=$(gh api graphql -f query='{ repository(owner: "{owner}", name: "{repo}") { pullRequest(number: {pr_number}) { reviewThreads(first: 50) { nodes { id isResolved comments(first: 1) { nodes { databaseId } } } } } } }' \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.comments.nodes[0].databaseId == {comment_id}) | .id')
```

**Resolve it:**

```bash
QUERY=$(printf 'mutation { resolveReviewThread(input: {threadId: "%s"}) { thread { isResolved } } }' "$THREAD_ID")
gh api graphql -f query="$QUERY" --jq '.data.resolveReviewThread.thread.isResolved'
```

**Batch resolution** — to resolve ALL unresolved threads at once:

```bash
for tid in $(gh api graphql -f query='{ repository(owner: "{owner}", name: "{repo}") { pullRequest(number: {pr_number}) { reviewThreads(first: 50) { nodes { id isResolved } } } } }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | .id'); do
  QUERY=$(printf 'mutation { resolveReviewThread(input: {threadId: "%s"}) { thread { isResolved } } }' "$tid")
  gh api graphql -f query="$QUERY" --jq '.data.resolveReviewThread.thread.isResolved'
  echo " resolved: $tid"
done
```

**PowerShell batch resolution:**

```powershell
$threadIds = gh api graphql -f query='{ repository(owner: "{owner}", name: "{repo}") { pullRequest(number: {pr_number}) { reviewThreads(first: 50) { nodes { id isResolved } } } }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | .id'

foreach ($tid in $threadIds) {
  gh api graphql -f query="mutation { resolveReviewThread(input: {threadId: `"$tid`"}) { thread { isResolved } } }" --jq '.data.resolveReviewThread.thread.isResolved'
}
```

**Rules:**
- Always resolve after replying — unresolved threads block clean PR state
- Use `printf` (bash) or backtick-escaped quotes (PowerShell) for the mutation query to avoid shell escaping issues
- Never use `-F` or variable interpolation inside the query string — it breaks GraphQL parsing

### Step 5 — Re-request Copilot review

After addressing ALL comments, re-request Copilot's review:

```bash
gh api "repos/{owner}/{repo}/pulls/{pr_number}/requested_reviewers" \
  --method POST \
  -f 'reviewers[]=copilot-pull-request-reviewer[bot]'
```

### Step 6 — Repeat

Go back to Step 2. Poll for the NEW review. If the new review has no comments,
the PR is clean and the Copilot review loop is complete. If it has comments,
repeat Steps 3-5.

## Anti-Patterns

- **NEVER use `gh pr edit --add-reviewer`** for bot accounts — it returns "not found"
- **NEVER filter by `.user.login=="Copilot"`** — the login is `copilot-pull-request-reviewer[bot]`
- **NEVER batch multiple comment fixes into one commit** — one commit per comment
- **NEVER skip the re-request step** — Copilot won't re-review unless explicitly asked
- **NEVER use `gh api ... -f 'reviewers[]=Copilot'`** — succeeds silently but does nothing

## Merge Conflict Resolution

If merge conflicts arise during this workflow:

1. Fetch and rebase: `git fetch origin && git rebase origin/<target-branch>`
2. Resolve conflicts
3. Force-push: `git push --force-with-lease`
4. Re-request review (Step 5)
