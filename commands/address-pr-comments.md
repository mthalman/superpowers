---
description: Systematically address GitHub PR review comments one at a time, with interactive guidance and resumable progress
---

You are helping the user address review comments on a GitHub Pull Request, one comment at a time. Follow this workflow systematically.

## How this command works

This command speaks in **actions**, not in a specific tool's vocabulary. Wherever it says:

- **read a file** — use your native file-reading capability (it already shows line numbers).
- **edit a file** — use your native edit/patch capability.
- **run a command** — use your shell.
- **ask the user** — use your native interactive question capability. When the user is choosing between fixed options, present them as a **single-select question**, not a block of text the user has to answer in prose. Never print a lettered `[A]/[B]/[C]` menu and parse the reply yourself.
- **track progress with a todo list** — use your native task/todo list so the user can see, at a glance, which comments are done and which remain.

Render everything you show the user as clean **markdown** — headings, lists, blockquotes, fenced code blocks, and links. Do not hand-draw ASCII boxes or hand-align columns; let the rendering layer format it.

## Working File (Progress State)

Progress is persisted to a JSON file so an interrupted or iterative review can resume exactly where it left off. This is the durable source of truth; the in-session todo list is just a live view of it.

**Where to store it:** your agent's working/scratch directory — *not* inside the repository, and never a tool-specific folder like `.claude/`. If your agent exposes a dedicated session or working-files directory, use that. Otherwise use the **system temporary directory** (`$env:TEMP` on Windows, `$TMPDIR` or `/tmp` on Unix).

**Path:** key it by repository and PR so multiple PRs and repos never collide:

```
{working_dir}/address-pr-comments/{owner}-{repo}/pr-{pr_number}.json
```

See the [Progress File Schema](#progress-file-schema) section for the full structure.

## Initial Setup

1. **Detect the PR:**
   - Run `git rev-parse --abbrev-ref HEAD` to get the current branch.
   - Run `gh pr view --json number,url,title,state` to find the associated PR.
   - Resolve `owner/repo`: `gh repo view --json nameWithOwner -q .nameWithOwner`.
   - If no PR is found or the branch isn't pushed, show a clear error and stop (see [Error Handling](#error-handling)).

2. **Check for an existing progress file:**
   - Look for the working file at the path above.
   - If it exists, load it — this is a resumed session. Preserve the user's prior decisions (skips, completed items, pending replies) and reconcile them against freshly fetched GitHub data below.

3. **Fetch all unresolved comments:**

   **Definition:** a comment is UNRESOLVED when both are true:
   - its `position` field is not `null` (the comment still maps onto the current diff, i.e. it is not outdated), and
   - its review thread is not marked **Resolved** (checked via GraphQL).

   **Fetch process:**

   a. Fetch all review comments via REST (see [GitHub CLI Reference](#fetch-pr-review-comments)).

   b. Fetch thread resolution status via GraphQL (see [GitHub CLI Reference](#get-review-thread-resolution-status-graphql)).

   c. Filter the comments:
   - Exclude any where `position == null` (outdated).
   - Exclude any whose thread is `isResolved: true` in the GraphQL response.
   - Cross-reference using the comment `databaseId` from GraphQL = comment `id` from REST.

   **Edge cases:**
   - **Outdated comments** (`position == null`): skip entirely.
   - **Comments on deleted files:** check whether the file still exists with `git ls-files --error-unmatch {file_path}`. If it doesn't:
     - Auto-mark the comment as skipped with `action: "file_deleted"` in the progress file.
     - Queue a pending reply: "File was deleted in recent changes."
     - Don't surface it in the interactive flow.
     - Account for it in the final summary: "⊘ N comments auto-skipped (files deleted)".
   - **Resolved with new activity:** if a thread's latest post is newer than `last_post_timestamp` in the progress file, re-surface it even if previously addressed.

   **Processing:**
   - Include the full conversation thread (root comment + all replies).
   - Capture the timestamp of the most recent post in each thread.
   - Group comments by file.

4. **Create or update the progress file** at the working path with the reconciled state.

5. **Build a todo list for visible progress:** create one todo per unresolved comment (a short label like `src/auth.ts:42 — @reviewer`), in the order you'll process them. Mark the current comment **in progress** as you work it and **complete** when its decision is recorded. This gives the user a live overview alongside the persisted JSON. Comments auto-skipped for deleted files can be added as already-completed (or omitted) — don't make the user act on them.

6. **Detect new activity on resume:** for each thread, compare its latest post timestamp against `last_post_timestamp` in the progress file. If newer, re-prompt that comment even if it was previously addressed.

## Showing a Comment

Process comments **one at a time**. For each pending comment, show the user a compact markdown block:

- A heading with the file path.
- "Comment _n_ of _total_ in this file".
- The line number and reviewer.
- A markdown link to the comment (see URL rule below).
- The thread, rendered as blockquotes — one quoted line per participant, in order.
- The surrounding **code context** (see below).

**URL rule:** wrap GitHub URLs in angle brackets (or use markdown link syntax) so underscores aren't interpreted as emphasis.
- Comment: `<https://github.com/{owner}/{repo}/pull/{pr_number}#discussion_r{comment_id}>`
- PR: `<https://github.com/{owner}/{repo}/pull/{pr_number}>`

### Showing code context

Show the code around the commented line so the user understands it in place:

1. Identify the file, line, and `commit_id` from the comment metadata.
2. Read the file **as of the comment's commit** when possible: `git show {commit_id}:{file_path}`. If that commit isn't available locally, read the current working-tree version instead and tell the user: "⚠️ Showing the current file; it may differ from when the comment was made."
3. Show roughly **±5 lines** around the commented line.
4. Render it as a **fenced code block** so it's syntax-highlighted, and clearly mark which line the comment is on — e.g. an arrow (`→`) on that line, or a one-line note ("comment is on line 42").

Do **not** hand-align line numbers or build ASCII tables — read the file with your native tooling and let the code block format it.

## Processing a Comment

After showing the comment, **ask the user** — as a single-select question — how they want to handle it. Offer these options:

- **Fix it myself** — the user will make and commit the change, then continue.
- **Auto-fix it** — you propose and apply the fix.
- **Reply to the comment** — post a reply without a code change.
- **Mark as done** — already fixed outside this command.
- **Skip / defer** — leave it for a later pass.

Then follow the matching flow below. (Comments on deleted files are handled automatically and never reach this step.)

### Fix it myself

1. Record the current HEAD: `git rev-parse --short HEAD` → `before_sha`.
2. Tell the user to make and commit their fix, and to let you know when they're ready to continue. Wait for them.
3. When they return, check for uncommitted changes: `git status --porcelain`.
   - If there are uncommitted changes, list them and **ask the user** (single-select):
     - **Auto-commit with a semantic message** — analyze `git diff`, craft a semantic commit message, and commit. Then go to step 5 to record the commit.
     - **I'll commit them myself** — wait until they confirm they've committed, then continue.
     - **Continue without committing** — proceed without committing these changes.
4. Check whether new commits exist: `git rev-parse --short HEAD` → `after_sha`. If `after_sha == before_sha`, **ask the user** whether to skip this comment (yes → mark skipped and move on; no → re-ask the handling question for this comment).
5. Show the recent commits (`git log --oneline -10`) as a short markdown list, and **ask the user** which commit(s) address this comment. Accept a multi-select of the listed commits, explicit SHAs, or "none".
6. Record in the progress file: mark the comment **completed**, store the selected commit SHA(s), and queue a pending reply: `"Fixed in <sha1>, <sha2>"` (or a single SHA). Mark its todo complete. Move on.

### Auto-fix it

1. Analyze the comment together with the surrounding code.
2. Propose the change and show it to the user — as a unified-diff fenced block, or by previewing the edit with your native tooling.
3. **Ask the user** to approve (yes/no).
   - **Approved:** edit the file, commit with a semantic message (describe *what* was fixed, not "from a PR comment"), record the commit SHA, queue a pending reply `"Fixed in <short_sha>"`, mark the comment completed and its todo complete, and move on.
   - **Rejected:** leave the comment pending and **ask the user** again (single-select: Fix it myself / Mark as done / Skip), then follow that flow.

### Reply to the comment

1. **Ask the user** for their reply text.
2. Queue it in the comment's `pending_replies`.
3. Mark the comment **replied** in the progress file. Move on.

### Mark as done

1. Mark the comment **completed** in the progress file (no pending reply — it was addressed outside this command).
2. Mark its todo complete. Move on.

### Skip / defer

1. Mark the comment **pending** with `action: "deferred"` so it reappears next pass.
2. Move on.

## Completion

When every comment has been processed, show a markdown summary:

> **All comments processed**
>
> - ✓ N auto-fixed (M commits)
> - ✓ N fixed by you (M commits)
> - ✓ N marked done (no commits)
> - ✓ N replies queued
> - ⊘ N skipped/deferred
> - ⊘ N auto-skipped (files deleted)
>
> **Commits to push**
> - `<sha>` — <message>
> - …
>
> **Replies to post:** N
>
> PR: <PR URL>

Then **ask the user** whether to push (yes/no).

### If the user approves the push

1. Push: `git push`.
2. For each comment with queued `pending_replies`, post each message as a reply (see [Post Reply to Comment](#post-reply-to-comment)). On success, remove that message from the array and save the progress file immediately. On failure, keep the message, log `"Failed to post reply to comment {comment_id}: {error}"`, and continue.
3. Confirm in markdown:

> ✓ Pushed N commits to `origin/<branch>`
> ✓ Posted N replies _(✗ M failed — will retry next push, if any)_
>
> PR #<number> is ready for re-review. Run this command again to pick up new comments.

### If the user declines

- Keep the progress file (and all queued replies) intact so a later run can finish the job.
- Remind the user: "Queued replies won't be posted until you push through this command."

## Error Handling

Fail fast with a clear, actionable message for:

- No PR found for the current branch.
- Branch not pushed to the remote.
- `gh` not authenticated (`gh auth status`).
- GitHub API failures (rate limit, network).
- A corrupt or unreadable progress file.

**Format:**

> **Error:** <what went wrong>
>
> <one concrete step to fix it>

## Key Principles

- **One comment at a time** — process sequentially, never batch.
- **One commit per fix** — never bundle multiple fixes into a commit.
- **Semantic commit messages** — describe what was fixed, not that it came from a PR comment.
- **Minimal replies** — usually just "Fixed in <sha>".
- **Resumable** — never delete the progress file; it powers cross-session resume and iterative reviews.
- **Always re-fetch** — reconcile against current GitHub state on every run; re-prompt threads with new activity.
- **Defer to the agent** — use your native question, todo, read, and edit capabilities rather than reinventing them in text.

## PowerShell Text Safety

**⚠️ Windows/PowerShell only.** Backticks (`` ` ``) in any text passed to `gh` are interpreted as PowerShell escape characters (`` `n ``, `` `r ``, …), silently mangling the posted text. This matters when posting reply bodies that contain user-provided text or code.

When posting a reply via `gh api`, put the body in a PowerShell variable and pass it directly — **do not** use the `-f "body=@file"` syntax (PowerShell posts the literal file path):

```powershell
# ✅ GOOD
$body = "Fixed in abc1234"
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" -f "body=$body" -F in_reply_to=$commentId

# ⚠️ BAD — posts the literal path, not the file contents
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" -f "body=@$tempFile" -F in_reply_to=$commentId
```

For `gh` subcommands that support `--body-file` (e.g. `gh pr comment`), writing the text to a UTF-8 temp file and passing `--body-file` is the safest route.

---

## GitHub CLI Reference

### Fetch PR Review Comments

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

Use `--paginate` for PRs with 100+ comments.

**Key fields:** `id` (needed to post replies), `path`, `line`, `commit_id`, `body`, `created_at`, `position` (`null` ⇒ outdated), `user.login`, `in_reply_to_id`.

Filter to comments still on the diff:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate \
  --jq '.[] | select(.position != null)'
```

### Get Review Thread Resolution Status (GraphQL)

```bash
gh api graphql -F owner="{owner}" -F repo="{repo}" -F pr={pr_number} -F query=@- <<'EOF'
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 10) {
            nodes {
              databaseId
              createdAt
            }
          }
        }
      }
    }
  }
}
EOF
```

- `databaseId` (GraphQL) corresponds to `id` (REST).
- Exclude comments whose thread has `isResolved: true`.
- For 100+ threads, page with the `after` cursor.

### Post Reply to Comment

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -X POST \
  -f body="Fixed in abc123f" \
  -F in_reply_to={comment_id}
```

On Windows, build `body` from a variable (see [PowerShell Text Safety](#powershell-text-safety)).

### Get PR Details

```bash
gh pr view --json number,url,title,state
```

---

## Git Command Reference

### Recent commits

```bash
git log --oneline -10
```

### Show a file at a specific commit

```bash
git show {commit_sha}:{file_path}
```

Returns the file contents as they existed in that commit — used to show code context that matches the comment.

### Current branch

```bash
git rev-parse --abbrev-ref HEAD
```

### Current HEAD (short)

```bash
git rev-parse --short HEAD
```

---

## Progress File Schema

The progress file (`{working_dir}/address-pr-comments/{owner}-{repo}/pr-{pr_number}.json`) tracks comment processing state across sessions.

```json
{
  "pr_number": 123,
  "branch": "feature/add-auth",
  "last_updated": "2025-11-08T14:30:00Z",
  "comments": [
    {
      "id": "123456789",
      "file": "src/auth.ts",
      "line": 42,
      "status": "completed",
      "commit_sha": "abc123f",
      "action": "auto_fixed",
      "pending_replies": ["Fixed in abc123f"],
      "last_post_timestamp": "2025-11-07T21:48:42Z"
    },
    {
      "id": "234567890",
      "file": "src/utils.ts",
      "line": 15,
      "status": "pending",
      "commit_sha": null,
      "action": null,
      "pending_replies": [],
      "last_post_timestamp": "2025-11-08T10:15:30Z"
    }
  ]
}
```

**Field definitions:**

- `pr_number` (number): PR number.
- `branch` (string): git branch name.
- `last_updated` (ISO 8601): when the file was last written.
- `comments` (array):
  - `id` (string): comment ID from the GitHub API.
  - `file` (string): path relative to the repo root.
  - `line` (number): line number in the file.
  - `status` (enum): `"pending"` | `"completed"` | `"skipped"`.
  - `commit_sha` (string | null): short SHA(s) of the commit(s) addressing the comment.
  - `action` (enum | null): `"auto_fixed"` | `"fixed_by_user"` | `"marked_done"` | `"deferred"` | `"replied"` | `"file_deleted"`.
  - `pending_replies` (array of strings): reply messages to post on the next push.
  - `last_post_timestamp` (ISO 8601): timestamp of the most recent post in the thread (used to detect new activity).
