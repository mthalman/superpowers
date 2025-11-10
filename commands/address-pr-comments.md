---
description: Systematically address PR review comments with interactive guidance
---

You are helping the user address review comments on a GitHub Pull Request. Follow this workflow systematically.

## Initial Setup

1. **Detect the PR:**
   - Execute: `git rev-parse --abbrev-ref HEAD` to get current branch
   - Execute: `gh pr view --json number,url,title` to find the associated PR
   - If no PR found or branch not pushed, display error and exit (see Error Handling section for format)

2. **Check for progress file:**
   - Check if `.claude/pr-comments-progress.json` exists
   - If exists: Load previous state (resumed session)
   - Re-fetch current comments from GitHub
   - Merge state: Preserve user decisions (skips, completed) while using current GitHub data

3. **Fetch all unresolved comments:**

   **Definition:** A comment is UNRESOLVED if:
   - `position` field is not `null` (comment is on current diff, not outdated), AND
   - Review thread is not marked "Resolved" (check via GraphQL)

   **Fetch process:**

   a. Fetch all comments via REST (see GitHub CLI Reference for command)

   b. Fetch resolution status via GraphQL (see GitHub CLI Reference for query)

   c. Filter comments:
   - Exclude if `position == null` (outdated)
   - Exclude if thread is marked `isResolved: true` in GraphQL response
   - Cross-reference using comment `databaseId` from GraphQL = comment `id` from REST

   **Edge cases:**
   - **Outdated comments** (`position == null`): Skip these entirely
   - **Comments on deleted files**: Check if file exists in current tree using `git ls-files --error-unmatch {file_path}`. If file doesn't exist:
     - Automatically mark as skipped with `action: "file_deleted"` in progress file
     - Add to pending_replies: "File was deleted in recent changes"
     - Don't show to user during interactive flow
     - Include in final summary: "⊘ <n> comments auto-skipped (files deleted)"
   - **Resolved with new activity**: If `last_post_timestamp` newer than progress file, re-show

   **Processing:**
   - Include full conversation threads (root comment + all replies)
   - For each comment thread, capture the timestamp of the most recent post
   - Group comments by file location

4. **Create or update progress file:**
   - File location: `.claude/pr-comments-progress.json`
   - Tracks PR number, branch, and comment processing state
   - See Progress File Schema section for complete structure

5. **Detect new activity on comments:**
   - When resuming, compare `last_post_timestamp` from progress file with latest post timestamp from GitHub
   - If current thread has newer timestamp: Re-prompt the comment (even if previously addressed)

## Code Context Retrieval

When displaying a comment, retrieve code context using this algorithm:

**Primary method (accurate to comment):**
1. Get `commit_id` from comment metadata
2. Execute: `git show {commit_id}:{file_path}`
3. Extract lines from `(line - 5)` through `(line + 5)` (11 lines total)
4. Format with line numbers
5. Mark the comment's line with `>` prefix

**Fallback method (if commit not available):**
1. Use Read tool on current file: `Read(file_path)`
2. Extract lines from `(line - 5)` through `(line + 5)`
3. Show warning: "⚠️ Showing current file state, may differ from when comment was made"

**Context window:** ±5 lines (adjustable based on code complexity)

**Formatting:**

Display code in a block with line numbers right-aligned so all `|` characters line up vertically.

**Algorithm:**
1. Determine the max line number in context (e.g., lines 15-21 → max is 21)
2. Calculate width: `width = len(str(max_line_number))` (for 21, width = 2; for 103, width = 3)
3. For each line, format as: `prefix + line_number.rjust(width) + " | " + code`
   - For unmarked lines: `prefix = "  "` (2 spaces)
   - For marked line: `prefix = "> "` (> symbol + 1 space)

**Example implementation (Python-style):**
```python
width = len(str(max_line))  # If max_line = 21, width = 2
for line_num, code in lines:
    line_str = str(line_num).rjust(width)  # Right-justify: "17" or " 7"
    if line_num == commented_line:
        print(f"> {line_str} | {code}")  # "> 17 | code"
    else:
        print(f"  {line_str} | {code}")  # "  17 | code"
```

**Example output (lines 15-21, marked line 17):**
```
  15 | // Check expiration exists and is valid
  16 | if (typeof decoded.exp !== 'number') return false;
> 17 | return decoded.exp * 1000 > Date.now();
  18 | } catch (error) {
  19 | return false;
  20 | }
  21 | }
```

Note: All `|` characters align vertically. The `>` marker replaces the 2 leading spaces.

## Processing Comments

**URL Formatting Rule:** Always wrap GitHub URLs in angle brackets to prevent markdown from interpreting underscores as emphasis markers.
- Comment URL format: `<https://github.com/{owner}/{repo}/pull/{pr_number}#discussion_r{comment_id}>`
- PR URL format: `<https://github.com/{owner}/{repo}/pull/{pr_number}>`

For each pending comment, display:

```
📁 <file_path>

Comment <n> of <total> in this file
──────────────────────────────────────
Line <number> | @<reviewer>
🔗 <URL to comment>

Thread:
  @<user1>: <comment text>
  @<user2>: <reply text>
  ...

Code context:
<display formatted code using algorithm from Code Context Retrieval section>

──────────────────────────────────────
What would you like to do?

[A] Fix it myself
[B] Auto-fix it
[C] Ask clarifying question to reviewer
[D] Mark as done (already fixed outside this tool)
[E] Skip/Defer
```

**Note:** Comments on deleted files are automatically skipped and not shown in this interactive flow.

### User Choice: [A] Fix it myself

1. Get current HEAD SHA: `git rev-parse --short HEAD` (store as `before_sha`)
2. Show: `"You can now fix the issue and commit your changes. Type 'done' when ready to continue."`
3. Wait for user to type 'done'
4. Check for uncommitted changes:
   - Execute: `git status --porcelain`
   - If output is not empty:
     ```
     You have uncommitted changes:
     <list changed files>

     What would you like to do?
     [A] Auto-commit with semantic message
     [B] I'll commit them myself
     [C] Continue without committing these changes
     ```
     - If [A]: Analyze changes using `git diff`, create semantic commit message, execute commit
     - If [B]: Show "Type 'done' when committed", wait for 'done', then continue
     - If [C]: Continue with existing commits
5. Check if new commits exist:
   - Execute: `git rev-parse --short HEAD` (store as `after_sha`)
   - Compare `before_sha` with `after_sha`
   - If identical: Show "No new commits found. Skip this comment? [Y/n]"
     - If yes: Mark as skipped, move to next comment
     - If no: Return to main choice prompt for this comment
6. Fetch recent commits using: `git log --oneline -5`
   - Shows last 5 commits on current branch
   - Format: `<short_sha> <commit_message>`
7. Show commits to user:
   ```
   Recent commits:

   1. abc123f - fix: add input validation
   2. def456a - fix: handle null case
   3. ghi789b - test: add edge case coverage
   4. jkl012c - refactor: extract helper
   5. mno345d - docs: update README

   Which commit(s) address this comment?
   Enter: number(s), SHA, or range
   Examples: "1", "1,3", "1-2", "all", "abc123f", "skip"
   ```
5. Parse user input:
   - Single number: "1" → Select commit 1
   - Multiple numbers: "1,3" → Select commits 1 and 3
   - Range: "1-2" → Select commits 1 and 2
   - Keyword: "all" → Select all listed commits
   - SHA: "abc123f" → Select by SHA
   - Keyword: "skip" → Skip this comment (don't record any commits)
6. Record in progress file:
   - Mark comment as completed
   - Store all selected commit SHAs
   - Add to pending_replies array: `"Fixed in <sha1>, <sha2>"` (or single SHA if only one)
7. Move to next comment

### User Choice: [B] Auto-fix it

1. Analyze the comment and surrounding code context
2. Apply the changes using Edit tool
3. If user approves the changes:
   - Create semantic commit message (describe what was fixed, not that it's from a PR comment)
   - Record commit SHA in progress file
   - Add to pending_replies array: `"Fixed in <short_sha>"`
   - Move to next comment
4. If user rejects the changes:
   - Mark comment as "pending" in progress file
   - Show: "Changes rejected. What would you like to do?"
     ```
     [A] Fix it myself
     [D] Mark as done
     [E] Skip/Defer
     ```
   - Process the selected choice

### User Choice: [C] Ask clarifying question

1. Draft a question based on comment context (prefix with @<reviewer>)
2. Show draft:
   ```
   Draft reply to @<reviewer>:

   "@<reviewer> <drafted question>"

   [A] Edit this reply
   [B] Send as-is
   [C] Cancel
   ```
3. If [A]: Allow user to edit the reply text
4. If [B]: Add the question message to pending_replies array
5. Mark comment as "questioned" in progress file
6. Move to next comment

### User Choice: [D] Mark as done

1. Mark comment as completed in progress file
2. Move to next comment

**Note:** No message is added to pending_replies - this is for comments already addressed outside the tool.

### User Choice: [E] Skip/Defer

1. Mark comment as skipped in progress file (status: "pending")
2. Will appear again in next session
3. Move to next comment

## Completion Workflow

After all comments are processed, show summary:

```
═══════════════════════════════════════════
All comments addressed!
═══════════════════════════════════════════

Summary:
  ✓ <n> comments auto-fixed (<n> commits)
  ✓ <n> comments fixed by you (<n> commits)
  ✓ <n> comments marked as done (no commits)
  ✓ <n> questions asked to reviewers
  ⊘ <n> comments skipped/deferred

Commits to be pushed:
  <sha> - <message>
  <sha> - <message>
  ...

Comment replies to be posted: <n>

🔗 <PR URL>

═══════════════════════════════════════════
Ready to push? [Y/n]
```

### If user approves push:

1. Execute: `git push`
2. For each comment with pending_replies in progress file:
   - For each message in the pending_replies array:
     - Post reply using `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments -X POST -f body="<message>" -F in_reply_to={comment_id}`
     - On success: Remove that specific message from the pending_replies array, update progress file immediately
     - On failure: Log error `"Failed to post reply to comment {comment_id}: {error}"`, keep message in array, continue with next
3. Count successful and failed replies
4. Display confirmation:
   ```
   ✓ Pushed <n> commits to origin/<branch>
   ✓ Posted <n> comment replies
   [If any failures: ✗ Failed to post <n> replies (will retry on next push)]

   PR #<number> is ready for re-review!

   Run this command again to address any new comments.
   ```

### If user declines push:

- Keep progress file intact with all pending_replies arrays
- User can push manually or run command again later
- Remind: "Comment replies won't be posted until you push via this command"

## Error Handling

**Fail fast with clear messages for:**

- No PR found for current branch
- Branch not pushed to remote
- GitHub CLI not authenticated (`gh auth status`)
- Uncommitted changes in working directory
- GitHub API failures (rate limit, network issues)
- Progress file corruption

**Example error format:**
```
Error: <problem>

<Actionable instruction to fix>
```

## Key Principles

- **One comment at a time** - Don't batch, process sequentially
- **Each fix gets its own commit** - Never bundle multiple fixes
- **Semantic commit messages** - Describe what was fixed, not that it's from a PR comment
- **Minimal PR replies** - Just "Fixed in <sha>"
- **Preserve state** - Progress file enables resuming interrupted sessions and iterative reviews
- **Always re-fetch** - Ensure GitHub state is current on resume
- **Fail fast** - Clear errors are better than confusing degraded states
- **Iterative review support** - Never delete progress file; detect new activity to re-prompt comments

## Technical Notes

- Use `gh` CLI for all GitHub operations
- Use unified diff format for change previews
- Display code context with line numbers
- Store pending replies in each comment's `pending_replies` array
- Post pending replies only when user approves push
- Clear `pending_replies` array after successful posting
- Support multiple replies per comment (e.g., question followed by fix)

---

## GitHub CLI Reference

### Fetch PR Review Comments

**Command:**
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
```

**Getting owner/repo dynamically:**
```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
# Returns: "owner/repo"
```

**Expected JSON output:**
```json
[
  {
    "id": 123456789,
    "path": "src/auth.ts",
    "position": 5,
    "commit_id": "abc123f456def789...",
    "in_reply_to_id": null,
    "user": {
      "login": "reviewer_username"
    },
    "body": "Add null check here to handle edge cases",
    "created_at": "2025-11-07T10:30:00Z",
    "line": 42
  }
]
```

**Key fields:**
- `id`: Comment ID (needed for posting replies)
- `path`: File path relative to repo root
- `line`: Line number in the file
- `commit_id`: SHA of commit the comment references
- `body`: Comment text
- `created_at`: Timestamp
- `position`: Position in diff (`null` if outdated)

**Filtering for unresolved comments:**
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --jq '.[] | select(.position != null)'
```

**Pagination (for PRs with 100+ comments):**
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

### Post Reply to Comment

**Command:**
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -X POST \
  -f body="Fixed in abc123f" \
  -F in_reply_to={comment_id}
```

### Get PR Details

**Command:**
```bash
gh pr view --json number,url,title,state
```

**Expected output:**
```json
{
  "number": 123,
  "url": "https://github.com/owner/repo/pull/123",
  "title": "Add authentication feature",
  "state": "OPEN"
}
```

### Get Review Thread Resolution Status (GraphQL)

**Command:**
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

**Expected output:**
```json
{
  "data": {
    "repository": {
      "pullRequest": {
        "reviewThreads": {
          "nodes": [
            {
              "id": "PRRT_kwDOAbc123...",
              "isResolved": false,
              "comments": {
                "nodes": [
                  {
                    "databaseId": 123456789
                  }
                ]
              }
            },
            {
              "id": "PRRT_kwDODef456...",
              "isResolved": true,
              "comments": {
                "nodes": [
                  {
                    "databaseId": 234567890
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }
}
```

**Usage:**
- `databaseId` in GraphQL corresponds to `id` in REST API comments
- Filter out comments where their thread has `isResolved: true`
- **Note:** GraphQL pagination uses `first: 100`. For PRs with 100+ threads, use cursor-based pagination with `after` parameter

---

## Git Command Reference

### Get Recent Commits

**Command:**
```bash
git log --oneline -5
```

**Expected output:**
```
abc123f fix: add input validation
def456a fix: handle null case
ghi789b test: add edge case coverage
jkl012c refactor: extract helper
mno345d docs: update README
```

### Show File at Specific Commit

**Command:**
```bash
git show {commit_sha}:{file_path}
```

**Example:**
```bash
git show abc123f:src/auth.ts
```

**Expected output:**
The complete file contents as they existed in that commit.

### Get Current Branch

**Command:**
```bash
git rev-parse --abbrev-ref HEAD
```

**Expected output:**
```
feature/add-auth
```

### Get File Line Count

**Command:**
```bash
wc -l < {file_path}
```

**Expected output:**
```
42
```

---

## Progress File Schema

The progress file (`.claude/pr-comments-progress.json`) tracks comment processing state across sessions.

**Complete schema:**
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
      "pending_replies": [
        "Fixed in abc123f"
      ],
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
    },
    {
      "id": "345678901",
      "file": "README.md",
      "line": 8,
      "status": "skipped",
      "commit_sha": null,
      "action": "deferred",
      "pending_replies": [],
      "last_post_timestamp": "2025-11-06T16:20:00Z"
    }
  ]
}
```

**Field definitions:**

- `pr_number` (number): PR number from GitHub
- `branch` (string): Git branch name
- `last_updated` (ISO 8601 timestamp): When progress file was last modified
- `comments` (array): List of all comments processed or pending
  - `id` (string): Comment ID from GitHub API
  - `file` (string): File path relative to repo root
  - `line` (number): Line number in file
  - `status` (enum): `"pending"` | `"completed"` | `"skipped"`
    - `pending`: Not yet addressed
    - `completed`: Fixed or marked as done
    - `skipped`: User chose to defer or file was deleted
  - `commit_sha` (string | null): Short SHA(s) of commit(s) that address this comment
  - `action` (enum | null): `"auto_fixed"` | `"fixed_by_user"` | `"marked_done"` | `"deferred"` | `"questioned"` | `"file_deleted"`
  - `pending_replies` (array of strings): Reply messages to post when user pushes
  - `last_post_timestamp` (ISO 8601 timestamp): Timestamp of most recent message in thread (used to detect new activity)
