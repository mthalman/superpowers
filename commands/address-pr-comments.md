---
description: Systematically address GitHub or Azure DevOps PR review comments one at a time, with interactive guidance and resumable progress
---

# Address Pull Request Comments

Help the user address review threads on the pull request associated with the current branch. Support GitHub and Azure DevOps through a shared workflow with provider-specific adapters.

Process one thread at a time, persist every decision, and never push or post a reply without explicit confirmation.

## How This Command Works

This command speaks in **actions**, not in a specific tool's vocabulary:

- **read a file** -- use the native file-reading capability.
- **edit a file** -- use the native edit or patch capability.
- **run a command** -- use the shell.
- **ask the user** -- use the native interactive question capability. Present fixed options as a single-select question, never a hand-written lettered menu.
- **track progress with a todo list** -- use the native task list as a live view. The progress file remains the durable source of truth.

Render user-facing output as clean Markdown. Use provider-specific terminology only where it improves clarity: GitHub "review thread" and Azure DevOps "comment thread" are both called a **thread** in the shared workflow.

## Non-Negotiable Safety Rules

1. Detect the provider. Do not assume GitHub because `gh` is installed.
2. Re-fetch remote thread state on every run and reconcile it with durable progress.
3. Preserve prior decisions and queued replies when resuming.
4. Make one commit per code fix.
5. Post queued replies sequentially and persist after every successful post.
6. Never clear a queued reply unless the API response contains a comment ID.
7. Never assume the push remote is named `origin`.
8. Show the exact push remote, push URL, and branch before requesting confirmation.
9. Push and post only after an explicit confirmation. If the push fails, post nothing.
10. Never delete the progress file.

## Tested Support Helpers

The repository includes `scripts/address-pr-comments-support.psm1`, a deterministic reference implementation for:

- GitHub and Azure DevOps remote detection
- Azure DevOps PR parsing and link generation
- Azure DevOps thread normalization and status filtering
- progress schema migration and reconciliation
- provider-specific fixed-reply formatting
- Azure DevOps UTF-8 reply payloads and `az devops invoke` arguments
- sequential reply posting with per-success persistence

Use these helpers when the module is available. Otherwise apply the same contracts directly. Do not replace provider-neutral workflow decisions with duplicated provider-specific flows.

## Progress State

Store progress in the agent's working or scratch directory, never in the repository or a tool-specific directory. If no dedicated directory exists, use the system temporary directory.

Use these relative paths:

- GitHub, retained for backward compatibility:
  `address-pr-comments/{owner}-{repo}/pr-{pr_number}.json`
- Azure DevOps:
  `address-pr-comments/azure-devops/{organization}-{project}-{repository}/pr-{pr_number}.json`

Sanitize path-key segments by replacing characters outside `[A-Za-z0-9._-]` with `-`.

Read JSON with strict error handling. A missing file starts a new session; malformed or unreadable JSON is an error, not a reason to silently reset state.

Persist atomically:

1. Serialize the complete state to JSON.
2. Write it to a sibling temporary file as UTF-8 without BOM.
3. Replace the progress file with the temporary file.
4. If persistence fails, stop before any further remote operation.

## Phase 1: Detect the Provider and Pull Request

### Step 1: Inspect the Branch and Remotes

Run:

```powershell
$branch = git rev-parse --abbrev-ref HEAD
$remoteNames = @(git remote)
$remoteUrls = foreach ($remoteName in $remoteNames) {
    $url = git remote get-url $remoteName
    [pscustomobject]@{
        name = $remoteName
        url = $url -replace '^(https?://)[^/]+@', '$1'
    }
}
git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
git for-each-ref `
  --format='%(upstream:remotename)%09%(upstream:remoteref)' `
  "refs/heads/$branch"
```

Prefer the current branch's upstream remote for provider detection. Persist the local branch separately from the upstream remote branch. The remote branch, without `refs/heads/`, is the PR `source_branch`; it can differ from the local branch name.

If no upstream exists, inspect every fetch remote to identify the repository, but report that the branch is not pushed and stop before the review flow.

Recognize these remote forms:

- GitHub HTTPS: `https://github.com/{owner}/{repo}.git`
- GitHub SSH: `git@github.com:{owner}/{repo}.git`
- Azure DevOps HTTPS:
  `https://{optional-user}@dev.azure.com/{organization}/{project}/_git/{repository}`
- Azure DevOps legacy:
  `https://{organization}.visualstudio.com/{project}/_git/{repository}`
- Azure DevOps SSH:
  `git@ssh.dev.azure.com:v3/{organization}/{project}/{repository}`

Strip a trailing `.git`. Reject unsupported or ambiguous remotes with an actionable error.

Capture remote commands into variables so raw URLs are never printed. If an HTTP(S) remote contains user information, strip everything between `://` and `@` before persisting, displaying, or including the URL in an error. Use the remote name for git operations so credentials never need to be copied into command arguments or progress state.

### Step 2: Run Provider Prerequisite Checks

#### GitHub

1. Confirm `gh` is installed.
2. Run `gh auth status`.
3. If authentication fails, stop and tell the user to run `gh auth login`.

#### Azure DevOps

1. Confirm `az` is installed.
2. Run `az version --output json`.
3. Confirm the `azure-devops` extension is installed.
4. Read optional defaults:

   ```powershell
   az devops configure --list --output json
   ```

5. Verify authentication by making a read-only request for the detected project or repository.

Azure CLI 2.83 with `azure-devops` extension 1.0.2 is a known-working combination, not a required exact version.

Use these actionable remedies:

- Missing CLI: install the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli).
- Missing extension:
  `az extension add --name azure-devops`
- Unauthenticated CLI: run `az login`, or configure `AZURE_DEVOPS_EXT_PAT` according to the user's authentication policy.
- Missing defaults: pass `--organization` and `--project` explicitly; do not depend on global defaults.

### Step 3: Resolve Pull Request Metadata

Persist provider-neutral metadata before fetching threads:

- `schema_version`
- `provider`: `github` or `azure-devops`
- `organization`
- `project`: `null` for GitHub
- `repository`
- `repository_id`: `null` for GitHub
- `pr_number`
- `pr_url`
- `branch`
- `source_branch`
- `source_repository`
- `source_repository_owner`
- `remote_name`
- `remote_url`: credential-redacted

#### GitHub Adapter

Run:

```powershell
gh pr view --json number,url,title,state,headRefName,headRepository,headRepositoryOwner
gh repo view --json nameWithOwner -q .nameWithOwner
```

The PR must be associated with the current branch. Persist `headRepository.name` and `headRepositoryOwner.login` as the source repository identity so fork PRs can verify the push target. Preserve the current GitHub error behavior when no PR exists or the branch is not pushed.

#### Azure DevOps Adapter

Use the remote URL as the primary source of organization, project, and repository name. Use `az devops configure --list` only as a fallback or consistency check.

Resolve the repository ID:

```powershell
az repos show `
  --organization "https://dev.azure.com/{organization}" `
  --project "{project}" `
  --repository "{repository}" `
  --query id `
  --output tsv `
  --only-show-errors
```

Find the active PR whose source branch exactly matches the upstream remote branch, not necessarily the local branch:

```powershell
az repos pr list `
  --organization "https://dev.azure.com/{organization}" `
  --project "{project}" `
  --repository "{repository_id}" `
  --source-branch "refs/heads/{source_branch}" `
  --status active `
  --output json `
  --only-show-errors
```

Require exactly one match. If there are none, report that no active Azure DevOps PR was found for the upstream branch. If there are multiple matches, list their IDs and URLs and stop rather than guessing.

Require the returned `sourceRefName` to equal the upstream remote ref. Persist `pullRequestId`, `sourceRefName`, repository name and ID, and this browser URL:

```text
https://dev.azure.com/{organization}/{project}/_git/{repository}/pullrequest/{pullRequestId}
```

## Phase 2: Load and Reconcile Progress

### Step 1: Load Existing State

If the progress file exists, upgrade it in memory to schema version 2.

Legacy GitHub files have no `schema_version` or `provider`. Infer `provider: "github"` and add provider metadata without changing:

- comment status
- action
- commit SHA
- pending replies
- last-post timestamp

For a legacy GitHub comment, default `root_comment_id` and `thread_id` to its existing `id` when the richer values are unavailable.

### Step 2: Fetch Threads

#### GitHub Adapter

Fetch all review comments:

```powershell
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" --paginate
```

Fetch review thread resolution through GraphQL. Paginate review threads beyond 100. Use the REST result to assemble the complete conversation and GraphQL `databaseId` values to map comments to `isResolved`.

A GitHub thread is unresolved when:

- the root comment's `position` is not `null`, and
- GraphQL reports `isResolved: false`.

Continue to exclude outdated comments (`position == null`) exactly as before.

#### Azure DevOps Adapter

Fetch all PR threads:

```powershell
az devops invoke `
  --organization "https://dev.azure.com/{organization}" `
  --area git `
  --resource pullRequestThreads `
  --route-parameters `
    project="{project}" `
    repositoryId="{repository_id}" `
    pullRequestId="{pr_number}" `
  --api-version 7.1 `
  --output json `
  --only-show-errors
```

The underlying route is:

```text
{project}/_apis/git/repositories/{repositoryId}/pullRequests/{pullRequestId}/threads
```

Before status validation, skip a status-less thread only when it contains at least one comment and every `commentType` is `system` (or numeric value `3`). These are Azure DevOps event threads, not reviewer feedback. A status-less thread containing any non-system comment is an API compatibility error. Do not filter a user thread merely because it lacks file context.

Normalize one progress comment per remaining Azure DevOps thread:

- `id` and `thread_id`: thread `id`
- `root_comment_id`: the first root comment whose `parentCommentId` is `0`
- `conversation`: every comment in chronological order, including IDs, parent IDs, author, content, type, deletion flag, and timestamps
- `file`: `threadContext.filePath`, without a leading `/`, when present
- `line`: prefer `rightFileStart.line`, then `leftFileStart.line`
- `latest_post_timestamp`: newest comment `lastUpdatedDate` or `publishedDate`
- `remote_unresolved`: whether the provider currently considers the thread actionable
- `provider_metadata`: thread status, thread timestamps, and properties

An actionable thread must contain an explicit root comment. If it has no comments or only replies with nonzero `parentCommentId`, stop with an actionable malformed-response error. Never substitute the first reply or `0` as the root ID.

Azure DevOps API 7.1 defines these thread statuses:

- Non-actionable: `unknown`
- Unresolved: `active`, `pending`
- Resolved: `fixed`, `wontFix`, `closed`, `byDesign`

The numeric equivalents are `0` through `6` in the same order:
`unknown`, `active`, `fixed`, `wontFix`, `closed`, `byDesign`, `pending`.

Treat any other status as an API compatibility error. Never silently drop a thread with a status the command does not understand. See the official [CommentThreadStatus API documentation](https://learn.microsoft.com/rest/api/azure/devops/git/pull-request-threads/list?view=azure-devops-rest-7.1#commentthreadstatus).

### Step 3: Reconcile Remote and Durable State

For each freshly fetched thread:

1. Match GitHub state by root review-comment ID and Azure DevOps state by thread ID.
2. Refresh remote metadata and the complete conversation.
3. Preserve prior action, commit SHA, and queued replies.
4. Compare the newest remote post with `last_post_timestamp`.
5. If it is newer, set the item back to `pending` so it reappears, even when it was previously completed or the remote thread now has a resolved status.
6. Retain progress entries absent from the fresh unresolved set so queued replies and history are not lost.

Set `last_post_timestamp` to the latest observed remote post after reconciliation. A pending item still reappears after interruption even though its timestamp is current.

### Step 4: Handle Deleted Files

For a thread with file context, run:

```powershell
git ls-files --error-unmatch -- "{file_path}"
```

If the file no longer exists:

- set `status: "skipped"` and `action: "file_deleted"`
- queue `File was deleted in recent changes.`
- do not present it in the interactive flow
- count it separately in the final summary

### Step 5: Persist and Build the Todo List

Persist reconciled state before showing the first thread.

Create one todo per actionable thread, such as
`src/auth.ts:42 -- @reviewer`. Mark the current item in progress and complete it when its decision is durably recorded.

## Phase 3: Show and Process One Thread at a Time

### Showing a Thread

For each pending thread, show:

- file path
- "Comment _n_ of _total_ in this file"
- line and reviewer
- provider-specific thread link
- complete conversation as blockquotes
- roughly five lines of code before and after the commented line

Links:

- GitHub thread:
  `https://github.com/{owner}/{repo}/pull/{pr_number}#discussion_r{root_comment_id}`
- Azure DevOps thread:
  `https://dev.azure.com/{organization}/{project}/_git/{repository}/pullrequest/{pr_number}?discussionId={thread_id}`

Use Markdown link syntax or angle brackets so special characters do not alter rendering.

For code context, prefer the file at the comment's commit:

```powershell
git show "{commit_sha}:{file_path}"
```

If that commit is unavailable, show the current working-tree file and warn that it may differ from the commented version. Clearly identify the commented line in a syntax-highlighted code block.

### Ask for a Decision

Present a single-select question:

- **Fix it myself**
- **Auto-fix it**
- **Reply to the comment**
- **Mark as done**
- **Skip / defer**

### Fix It Myself

1. Record `git rev-parse --short HEAD` as `before_sha`.
2. Wait for the user to make the fix.
3. On return, run `git status --porcelain`.
4. If changes are uncommitted, ask whether to auto-commit with a semantic message, wait for the user to commit, or continue without committing.
5. Compare HEAD with `before_sha`. If unchanged, ask whether to skip or choose another action.
6. Show `git log --oneline -10` and let the user select the commit or commits that address the thread.
7. Mark the item completed with `action: "fixed_by_user"` and persist.
8. Queue the provider-specific fixed reply described below.

### Auto-Fix It

1. Analyze the full conversation and code context.
2. Show the proposed diff.
3. Ask for approval.
4. If approved, apply the edit and make one semantic commit describing the code change.
5. Record the commit, set `action: "auto_fixed"`, queue the fixed reply, persist, and complete the todo.
6. If rejected, leave the item pending and ask the user to fix it, mark it done, or defer it.

### Reply to the Comment

1. Ask for reply text.
2. Append it to `pending_replies`.
3. Set `action: "replied"` and `status: "completed"`.
4. Persist before moving on.

### Mark as Done

Set `status: "completed"` and `action: "marked_done"` without queuing a reply. Persist before moving on.

### Skip or Defer

Keep `status: "pending"` and set `action: "deferred"` so it reappears next time. Persist before moving on.

### Provider-Specific Fixed Replies

GitHub behavior remains:

```text
Fixed in abc1234
```

For Azure DevOps, resolve every selected short SHA locally:

```powershell
git rev-parse "abc1234^{commit}"
```

Require a full 40-character SHA, then queue a Markdown link:

```text
Fixed in [abc1234](https://dev.azure.com/{organization}/{project}/_git/{repository}/commit/{fullCommitSha})
```

For multiple commits, link each short SHA. Never construct an Azure DevOps commit URL from an unresolved short SHA.

## Phase 4: Summarize and Request Confirmation

After every thread has a recorded decision, determine the exact upstream push target:

```powershell
git for-each-ref `
  --format='%(upstream:remotename)%09%(upstream:remoteref)' `
  "refs/heads/{branch}"
$pushUrl = git remote get-url --push "{remote_name}"
$displayPushUrl = $pushUrl -replace '^(https?://)[^/]+@', '$1'
```

Verify the unredacted push URL in memory against `source_repository` and `source_repository_owner` for GitHub, or organization, project, and repository for Azure DevOps. Verify the upstream remote ref matches `source_branch`. Display and persist only `$displayPushUrl`. Do not substitute `origin`.

Show:

> **All comments processed**
>
> - Provider: GitHub or Azure DevOps
> - Auto-fixed: N comments (M commits)
> - Fixed by you: N comments (M commits)
> - Marked done: N comments
> - Replies queued: N
> - Deferred: N
> - Auto-skipped because files were deleted: N
>
> **Push target:** `{remote_name}/{remote_branch}`
>
> **Push URL:** `<exact push URL>`
>
> **Commits to push**
> - `<sha>` -- message
>
> **Replies to post:** N
>
> **PR:** <provider-specific PR URL>

Ask one explicit confirmation: **Push these commits to the displayed remote and post the queued replies?**

If declined, keep all state and remind the user that replies remain queued until a confirmed push through this command.

## Phase 5: Push and Post Queued Replies

### Push

Use the displayed, verified target explicitly:

```powershell
git push "{remote_name}" "HEAD:{remote_branch}"
```

If the push fails, stop. Do not post any replies.

### Shared Posting Policy

Walk comments in stable order and replies in array order.

For each reply:

1. Call the provider API.
2. Parse the JSON response.
3. Require a returned comment `id`.
4. Remove only that successfully posted reply from `pending_replies`.
5. Update `last_post_timestamp` from the response:
   - GitHub: `created_at`
   - Azure DevOps: `publishedDate`
6. Persist progress immediately.
7. Continue with the next reply.

On API failure or a response without an ID:

- keep the reply queued
- report the thread and error
- do not attempt later replies in the same thread, preserving their order
- continue with the next thread

If the remote post succeeds but progress persistence fails, stop immediately and clearly report that the reply may already exist remotely. Do not post anything else.

### GitHub Posting Adapter

Preserve the existing endpoint and behavior:

```powershell
$body = $reply
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" `
  -X POST `
  -f "body=$body" `
  -F "in_reply_to={root_comment_id}"
```

### Azure DevOps Posting Adapter

The route is:

```text
{project}/_apis/git/repositories/{repositoryId}/pullRequests/{pullRequestId}/threads/{threadId}/comments
```

Create a unique temporary payload file containing:

```json
{
  "content": "<reply>",
  "parentCommentId": 1,
  "commentType": 1
}
```

Use the thread's actual `root_comment_id`, not the example value. Serialize with `ConvertTo-Json`, then write with .NET UTF-8 without BOM:

```powershell
$payload = [ordered]@{
    content = $reply
    parentCommentId = [int] $rootCommentId
    commentType = 1
} | ConvertTo-Json -Compress

[IO.File]::WriteAllText(
    $payloadPath,
    $payload,
    [Text.UTF8Encoding]::new($false)
)
```

Post:

```powershell
az devops invoke `
  --organization "https://dev.azure.com/{organization}" `
  --area git `
  --resource pullRequestThreadComments `
  --route-parameters `
    project="{project}" `
    repositoryId="{repository_id}" `
    pullRequestId="{pr_number}" `
    threadId="{thread_id}" `
  --api-version 7.1 `
  --http-method POST `
  --in-file "$payloadPath" `
  --encoding utf-8 `
  --output json `
  --only-show-errors
```

Delete only the unique payload file after the call. Surface API and cleanup errors; do not silently continue.

### Completion Message

Report:

> ✓ Pushed N commits to `{remote_name}/{remote_branch}`
>
> ✓ Posted N replies
>
> ✗ M replies failed and remain queued
>
> **Provider:** GitHub or Azure DevOps
>
> **PR:** <provider-specific PR URL>

## Error Handling

Fail fast with this format:

> **Error:** What went wrong
>
> One concrete step to fix it

Cover these cases:

- unsupported or ambiguous remote
- branch has no upstream or has not been pushed
- no PR for the current branch
- multiple Azure DevOps PR matches
- missing `gh`
- unauthenticated `gh`
- GitHub REST or GraphQL failure
- missing `az`
- missing `azure-devops` extension
- unauthenticated Azure CLI or PAT
- missing organization or project defaults when the remote cannot supply them
- Azure DevOps repository or PR not found
- Azure DevOps API failure
- unrecognized Azure DevOps thread status
- malformed API response
- corrupt or unreadable progress state
- progress persistence failure
- push remote or branch does not match the PR source

Never turn an error into empty comments, an empty queue, or a success-shaped result.

## PowerShell Text Safety

### GitHub

Backticks in inline arguments can be interpreted as PowerShell escapes. For the GitHub review-reply endpoint, keep the reply in a variable:

```powershell
$body = $reply
gh api "repos/{owner}/{repo}/pulls/{pr_number}/comments" `
  -X POST `
  -f "body=$body" `
  -F "in_reply_to={root_comment_id}"
```

Do not use `-f "body=@$tempFile"`; it can post the literal path.

For `gh` subcommands that support `--body-file`, a unique UTF-8 temporary file is safest.

### Azure DevOps

Never interpolate user-provided reply text into an `az devops invoke` command line. Serialize the JSON payload and pass it through `--in-file`.

Use UTF-8 without BOM so Markdown, backticks, and non-ASCII text survive unchanged. Use a unique file inside the working directory or system temp directory and delete only that file.

## Progress File Schema

Schema version 2:

```json
{
  "schema_version": 2,
  "provider": "azure-devops",
  "organization": "dnceng",
  "project": "internal",
  "repository": "build-duty",
  "repository_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
  "pr_number": 731,
  "pr_url": "https://dev.azure.com/dnceng/internal/_git/build-duty/pullrequest/731",
  "branch": "feature/review-fixes",
  "source_branch": "feature/review-fixes",
  "source_repository": "build-duty",
  "source_repository_owner": "dnceng",
  "remote_name": "upstream",
  "remote_url": "https://dev.azure.com/dnceng/internal/_git/build-duty",
  "last_updated": "2026-08-18T15:00:00Z",
  "comments": [
    {
      "id": "41",
      "provider": "azure-devops",
      "thread_id": "41",
      "root_comment_id": "1",
      "file": "src/Widget.cs",
      "line": 12,
      "status": "completed",
      "remote_unresolved": true,
      "commit_sha": "abc1234",
      "action": "auto_fixed",
      "pending_replies": [
        "Fixed in [abc1234](https://dev.azure.com/dnceng/internal/_git/build-duty/commit/abcdef0123456789abcdef0123456789abcdef01)"
      ],
      "last_post_timestamp": "2026-08-18T14:30:00Z",
      "conversation": [
        {
          "id": "1",
          "parent_comment_id": "0",
          "author": "Reviewer",
          "content": "Please validate this input.",
          "published_date": "2026-08-18T14:30:00Z"
        }
      ],
      "provider_metadata": {
        "status": "active"
      }
    }
  ]
}
```

Valid workflow values:

- `status`: `pending`, `completed`, `skipped`
- `action`: `auto_fixed`, `fixed_by_user`, `marked_done`, `deferred`, `replied`, `file_deleted`, or `null`

Provider identifiers are strings because GitHub uses review-comment IDs while Azure DevOps uses separate thread and comment IDs.
