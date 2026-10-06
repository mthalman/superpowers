---
name: copilot-pr-review
description: "Full GitHub Copilot PR review feedback loop — add Copilot as reviewer, poll for review, respond to comments, resolve threads, re-request review, and repeat until clean. Use when the user asks to 'run Copilot review', 'get Copilot feedback', 'request Copilot PR review', or when a PR needs automated code review from the Copilot reviewer bot."
---

# Copilot PR Review

Run the full GitHub Copilot code reviewer feedback loop on an open pull request:
add Copilot as reviewer, poll for its review, respond to each comment, resolve
threads, re-request review, and repeat until clean.

**Bot identity:** `copilot-pull-request-reviewer[bot]`

> **WARNING:** The bot login is NOT `Copilot`, NOT `copilot[bot]`, NOT
> `github-copilot`. It is exactly
> `copilot-pull-request-reviewer[bot]`. Using the wrong name silently fails or
> returns "not found".

## Prerequisites

- `gh` CLI installed and authenticated.
- An open pull request.
- The authenticated user has write access to the repository.
- A clean working tree, or an explicit decision to manage existing local
  changes before applying review fixes.

## Context detection

1. Infer `owner/repo` from `git remote get-url origin`.
2. Infer the PR number from the current branch with
   `gh pr view --json number --jq .number`.
3. If either cannot be inferred, ask for it instead of guessing.

## Six-step loop

### Step 1: add Copilot as reviewer

Use the GitHub API directly. `gh pr edit --add-reviewer` does not work for bot
accounts.

Open `references/api-commands.md` when you need the exact `gh api` command to
request Copilot, verify requested reviewers, fetch comments, reply, resolve
threads, or re-request review.

### Step 1.5: establish review baseline

Before requesting or re-requesting review, count existing reviews from
`copilot-pull-request-reviewer[bot]` and store `BASELINE_COUNT`. Step 2 must
look for a **new** review where the count exceeds that baseline, not merely any
old Copilot review.

### Step 2: poll for Copilot's review

Poll until a new review from `copilot-pull-request-reviewer[bot]` appears.
Default cadence is 60 seconds for up to 15 minutes unless project context
requires a different timeout. If polling is unreliable, use the commands and
checks in the reliability reference.

Open `references/reliability.md` when polling, merge conflicts, unresolved
threads, context budget, or pre-rerequest verification need deeper handling.

### Step 3: fetch review comments

Fetch line-level comments for the new review. If the review body says Copilot
generated no comments, the PR is clean. If it generated comments, process every
comment before Step 5.

### Step 4: respond to each comment

For each comment:

1. Read and understand the comment.
2. Make the fix on the PR branch.
3. Create **one commit per comment**.
4. Push the commit.
5. Reply to the comment with the fixing commit SHA.
6. Resolve the review thread.

> **PowerShell warning:** Do not use `-f "body=@$tempFile"`; PowerShell posts
> the literal file path. Store the reply in a variable and pass
> `-f "body=$bodyVar"` directly.

### Gate before Step 5

You MUST complete Steps 3-4 for **all** comments before re-requesting review.
Do not re-request until every comment has been read, fixed, committed, pushed,
replied to, and resolved. Skipping this gate prevents the loop from converging.

### Step 5: re-request Copilot review

After all comments are processed and threads are resolved, refresh
`BASELINE_COUNT`, then request Copilot again through the API.

### Step 6: repeat until clean

Return to Step 2. Poll for a review newer than the refreshed baseline. If it has
no comments, the loop is complete. If it has comments, repeat Steps 3-5.

## Anti-patterns

- **NEVER use `gh pr edit --add-reviewer`** for bot accounts.
- **NEVER filter by `.user.login=="Copilot"`**; use
  `copilot-pull-request-reviewer[bot]`.
- **NEVER batch multiple comment fixes into one commit**.
- **NEVER skip replies or thread resolution** after fixing a comment.
- **NEVER re-request review while current comments remain unprocessed**.
- **NEVER use `gh api ... -f 'reviewers[]=Copilot'`**; it can appear to succeed
  while doing nothing.

## Output contract

Report:

- repository and PR number;
- baseline counts for each review round;
- every Copilot comment processed, with fix commit SHA and thread resolution
  status;
- verification run before re-requesting or completing;
- final Copilot review state: clean, issues remaining, or blocked with evidence.
