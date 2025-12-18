---
name: azure-devops-pr-reviews
description: Use when creating or modifying Azure DevOps PR reviews via Azure CLI, adding comments to threads, voting on PRs, or getting errors about non-existent commands - explains CLI vs REST API split and provides correct az devops invoke patterns
---

# Azure DevOps PR Reviews via Azure CLI

## Overview

Create and modify Azure DevOps pull request reviews using Azure CLI and REST API.

**The key insight:** Azure CLI has NO direct commands for PR comments/threads. You must use REST API via `az devops invoke`.

**⚠️ CRITICAL:** There is NO `az repos pr comment`, NO `az repos pr thread`, NO `az repos pr review create`. If you find yourself typing these, STOP - they don't exist. Use `az devops invoke` instead.

## Core Principles

### 1. Understand the CLI vs REST API Split

**Azure CLI commands (direct support):**
- `az repos pr set-vote` - Vote on PR (approve, reject, etc.)
- `az repos pr reviewer` - Manage reviewers (add, list, remove)
- `az repos pr create/list/show/update` - Basic PR management

**REST API only (via `az devops invoke`):**
- Creating comment threads
- Adding comments to existing threads
- All file-specific positioning

**Critical:** Commands like `az repos pr comment` or `az repos pr thread` **DO NOT EXIST**. Don't invent them.

### 2. Prefer Simplicity

Always choose the simplest tool:
- Simple vote/approval → `az repos pr set-vote`
- Comments on code → REST API via `az devops invoke`
- Manage reviewers → `az repos pr reviewer`

### Quick Reference

| Task | Tool | Command Pattern |
|------|------|-----------------|
| Vote on PR | CLI | `az repos pr set-vote --id {pr} --vote {approve\|approve-with-suggestions\|reject\|reset\|wait-for-author}` |
| Add/remove reviewers | CLI | `az repos pr reviewer add/remove --id {pr} --reviewers user@email` |
| Create comment thread | REST API | `az devops invoke --area git --resource threads --route-parameters project={project} repositoryId={repo} pullRequestId={pr} --in-file thread.json --http-method POST` |
| Add to existing thread | REST API | `az devops invoke --area git --resource comments --route-parameters project={project} repositoryId={repo} pullRequestId={pr} threadId={threadId} --in-file comment.json --http-method POST` |
| List threads | REST API | `az devops invoke --area git --resource threads --route-parameters project={project} repositoryId={repo} pullRequestId={pr} --http-method GET` |

## Key Concepts

### Voting is NOT Commenting

**Voting** (CLI):
- Sets your review status: approve, approve-with-suggestions, reject, wait-for-author, reset
- Simple CLI command: `az repos pr set-vote`
- No file-specific positioning

**Commenting** (REST API):
- Creates threads on specific files/lines or general PR comments
- Requires REST API via `az devops invoke`
- Complex JSON structure for positioning

You can do both independently. Common pattern: Create comment threads, then vote.

### Thread Context and Positioning

For file-specific comments, thread context specifies location:

```json
{
  "comments": [{"parentCommentId": 0, "content": "Your comment", "commentType": 1}],
  "status": 1,
  "threadContext": {
    "filePath": "/src/file.ts",
    "rightFileStart": {"line": 10, "offset": 1},
    "rightFileEnd": {"line": 10, "offset": 1}
  }
}
```

**Key points:**
- **Lines are 1-indexed** (start at 1, not 0)
- **Offsets are 1-indexed** (character position in line)
- **rightFile** = new/added code
- **leftFile** = old/deleted code
- Omit `threadContext` entirely for general PR comments

### Thread Status Values

- `1` = active (default for new threads)
- `2` = fixed
- `3` = wontFix
- `4` = closed
- `5` = byDesign
- `6` = pending

### Comment Type Values

- `1` = text (use this for code review comments)
- `0` = unknown
- `2` = codeChange
- `3` = system

## How-To

### Simple Approval

```bash
# Option 1: Approve without comments
az repos pr set-vote \
  --id 42 \
  --vote approve \
  --org https://dev.azure.com/myorg

# Option 2: Approve with suggestions
az repos pr set-vote \
  --id 42 \
  --vote approve-with-suggestions \
  --org https://dev.azure.com/myorg

# Option 3: Request changes
az repos pr set-vote \
  --id 42 \
  --vote reject \
  --org https://dev.azure.com/myorg
```

Vote options:
- `approve` - LGTM, no concerns
- `approve-with-suggestions` - Approve but have minor suggestions
- `reject` - Request changes before merging
- `wait-for-author` - Waiting for author response
- `reset` - Clear your vote

### Create Comment Thread on Specific Line

```bash
# 1. Create thread.json with your comment
cat > thread.json << 'EOF'
{
  "comments": [
    {
      "parentCommentId": 0,
      "content": "Consider extracting this to a constant",
      "commentType": 1
    }
  ],
  "status": 1,
  "threadContext": {
    "filePath": "/src/config.ts",
    "rightFileStart": {"line": 10, "offset": 1},
    "rightFileEnd": {"line": 10, "offset": 1}
  }
}
EOF

# 2. Create thread via REST API
az devops invoke \
  --area git \
  --resource threads \
  --route-parameters \
    project="MyProject" \
    repositoryId="abc-123-def" \
    pullRequestId=42 \
  --in-file thread.json \
  --http-method POST \
  --org https://dev.azure.com/myorg \
  --api-version 7.1
```

### Create Multi-Line Comment Thread

```bash
cat > thread.json << 'EOF'
{
  "comments": [
    {
      "parentCommentId": 0,
      "content": "Add error handling for this block",
      "commentType": 1
    }
  ],
  "status": 1,
  "threadContext": {
    "filePath": "/src/api/handler.ts",
    "rightFileStart": {"line": 25, "offset": 1},
    "rightFileEnd": {"line": 27, "offset": 1}
  }
}
EOF

az devops invoke \
  --area git \
  --resource threads \
  --route-parameters \
    project="MyProject" \
    repositoryId="abc-123-def" \
    pullRequestId=42 \
  --in-file thread.json \
  --http-method POST \
  --org https://dev.azure.com/myorg \
  --api-version 7.1
```

### Create General PR Comment (No File Context)

```bash
# For comments not tied to specific code lines
cat > thread.json << 'EOF'
{
  "comments": [
    {
      "parentCommentId": 0,
      "content": "Overall this looks good! Just a few minor suggestions.",
      "commentType": 1
    }
  ],
  "status": 1
}
EOF

az devops invoke \
  --area git \
  --resource threads \
  --route-parameters \
    project="MyProject" \
    repositoryId="abc-123-def" \
    pullRequestId=42 \
  --in-file thread.json \
  --http-method POST \
  --org https://dev.azure.com/myorg \
  --api-version 7.1
```

### Add Comment to Existing Thread

```bash
# 1. Create comment.json
cat > comment.json << 'EOF'
{
  "content": "Also consider adding logging here",
  "parentCommentId": 0,
  "commentType": 1
}
EOF

# 2. Add to thread via REST API
az devops invoke \
  --area git \
  --resource comments \
  --route-parameters \
    project="MyProject" \
    repositoryId="abc-123-def" \
    pullRequestId=42 \
    threadId=15 \
  --in-file comment.json \
  --http-method POST \
  --org https://dev.azure.com/myorg \
  --api-version 7.1
```

**Note:** `threadId` is returned when you create a thread. Save it if you need to add follow-up comments.

### List All Threads on a PR

```bash
# Get all threads (returns JSON array)
az devops invoke \
  --area git \
  --resource threads \
  --route-parameters \
    project="MyProject" \
    repositoryId="abc-123-def" \
    pullRequestId=42 \
  --http-method GET \
  --org https://dev.azure.com/myorg \
  --api-version 7.1 \
  --query "value[].{id:id, status:status, filePath:threadContext.filePath, line:threadContext.rightFileStart.line}"
```

### Multi-Comment Review Workflow

```bash
# 1. Create first comment thread
cat > thread1.json << 'EOF'
{
  "comments": [{"parentCommentId": 0, "content": "First comment", "commentType": 1}],
  "status": 1,
  "threadContext": {
    "filePath": "/src/file1.ts",
    "rightFileStart": {"line": 10, "offset": 1},
    "rightFileEnd": {"line": 10, "offset": 1}
  }
}
EOF

az devops invoke --area git --resource threads \
  --route-parameters project="MyProject" repositoryId="abc-123" pullRequestId=42 \
  --in-file thread1.json --http-method POST \
  --org https://dev.azure.com/myorg --api-version 7.1

# 2. Create second comment thread
cat > thread2.json << 'EOF'
{
  "comments": [{"parentCommentId": 0, "content": "Second comment", "commentType": 1}],
  "status": 1,
  "threadContext": {
    "filePath": "/src/file2.ts",
    "rightFileStart": {"line": 25, "offset": 1},
    "rightFileEnd": {"line": 27, "offset": 1}
  }
}
EOF

az devops invoke --area git --resource threads \
  --route-parameters project="MyProject" repositoryId="abc-123" pullRequestId=42 \
  --in-file thread2.json --http-method POST \
  --org https://dev.azure.com/myorg --api-version 7.1

# 3. Vote to approve with suggestions
az repos pr set-vote --id 42 --vote approve-with-suggestions \
  --org https://dev.azure.com/myorg
```

### Comment on Deleted Code (Left Side)

```bash
# Use leftFileStart/leftFileEnd for code that was removed
cat > thread.json << 'EOF'
{
  "comments": [
    {
      "parentCommentId": 0,
      "content": "Why was this removed?",
      "commentType": 1
    }
  ],
  "status": 1,
  "threadContext": {
    "filePath": "/src/removed.ts",
    "leftFileStart": {"line": 15, "offset": 1},
    "leftFileEnd": {"line": 15, "offset": 1}
  }
}
EOF

az devops invoke --area git --resource threads \
  --route-parameters project="MyProject" repositoryId="abc-123" pullRequestId=42 \
  --in-file thread.json --http-method POST \
  --org https://dev.azure.com/myorg --api-version 7.1
```

## Troubleshooting

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `az repos pr comment: command not found` | Invented non-existent command | Use REST API via `az devops invoke` |
| `az repos pr thread: command not found` | Invented non-existent command | Use REST API via `az devops invoke` |
| `--thread-position: unrecognized argument` | Tried to use non-existent parameter | Use threadContext JSON with rightFileStart/rightFileEnd |
| `Line must be positive` | Used 0-indexed lines | Lines start at 1, not 0 |
| `Thread not found` | Wrong threadId | List threads with GET request to verify ID |
| `Invalid thread context` | Malformed JSON structure | Check threadContext has correct nested structure |

### Finding Repository ID

```bash
# List repositories to find ID
az repos list \
  --project MyProject \
  --org https://dev.azure.com/myorg \
  --query "[].{name:name, id:id}"
```

### Finding Project Name

```bash
# List projects
az devops project list \
  --org https://dev.azure.com/myorg \
  --query "value[].{name:name, id:id}"
```

### Getting PR Details

```bash
# Show PR info including head commit
az repos pr show \
  --id 42 \
  --org https://dev.azure.com/myorg \
  --query "{title:title, status:status, sourceRef:sourceRefName, targetRef:targetRefName}"
```

## Common Mistakes

### ❌ DON'T: Invent Non-Existent Commands

```bash
# WRONG - these commands don't exist
az repos pr comment create --line 10 --file src/file.ts
az repos pr thread add --thread-id 15
az repos pr reviewer create --thread-position 10
```

**Why wrong:** Azure CLI has no direct comment/thread commands. These will fail.

**DO instead:** Use `az devops invoke` with REST API endpoints.

### ❌ DON'T: Use 0-Indexed Lines

```json
{
  "threadContext": {
    "rightFileStart": {"line": 0, "offset": 0}
  }
}
```

**Why wrong:** Lines and offsets are 1-indexed in Azure DevOps.

**DO instead:**
```json
{
  "threadContext": {
    "rightFileStart": {"line": 1, "offset": 1}
  }
}
```

### ❌ DON'T: Mix Up Left and Right File Context

```json
{
  "threadContext": {
    "filePath": "/src/new-feature.ts",
    "leftFileStart": {"line": 10, "offset": 1}
  }
}
```

**Why wrong:** New code uses `rightFileStart`, not `leftFileStart`.

**DO instead:**
- `rightFileStart/rightFileEnd` for new/added code
- `leftFileStart/leftFileEnd` for old/deleted code

### ❌ DON'T: Try to Create Thread and Vote in One Command

```bash
# WRONG - no combined command exists
az repos pr review create --vote approve --comment "LGTM"
```

**Why wrong:** Voting and commenting are separate operations.

**DO instead:**
```bash
# Create threads first
az devops invoke --area git --resource threads ...

# Then vote
az repos pr set-vote --id 42 --vote approve
```

## Authentication

Azure CLI uses your authenticated Azure DevOps organization. Ensure you're logged in:

```bash
# Login to Azure DevOps
az login

# Set default organization (optional)
az devops configure --defaults organization=https://dev.azure.com/myorg

# Verify authentication
az devops user show
```

## API Selection Guide

### Decision Tree

```
Simple vote/approval?
├─ YES → az repos pr set-vote --vote {approve|reject|...}
└─ NO → Continue

Need to add/remove reviewers?
├─ YES → az repos pr reviewer add/remove
└─ NO → Continue

Need comments on specific code?
├─ YES → az devops invoke with REST API (threads endpoint)
└─ NO → az repos pr update for description changes
```

### CLI vs REST API Comparison

| Scenario | CLI | REST API | Recommendation |
|----------|-----|----------|----------------|
| Vote on PR | ✅ `az repos pr set-vote` | ✅ Works | CLI simpler |
| Manage reviewers | ✅ `az repos pr reviewer` | ✅ Works | CLI simpler |
| Comment on code | ❌ No command | ✅ Required | REST API only |
| General PR comment | ❌ No command | ✅ Required | REST API only |
| Add to existing thread | ❌ No command | ✅ Required | REST API only |
| Update PR title/description | ✅ `az repos pr update` | ✅ Works | CLI simpler |

## Reference

### az devops invoke Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--area` | API area | `git` |
| `--resource` | API resource | `threads`, `comments` |
| `--route-parameters` | URL route parameters | `project="MyProject" repositoryId="abc-123" pullRequestId=42` |
| `--in-file` | JSON input file | `thread.json` |
| `--http-method` | HTTP verb | `POST`, `GET`, `PATCH` |
| `--org` | Organization URL | `https://dev.azure.com/myorg` |
| `--api-version` | API version | `7.1` (use latest) |
| `--query` | JMESPath query for output | `value[].id` |

### Useful JMESPath Queries

```bash
# Get thread IDs and file paths
--query "value[].{id:id, file:threadContext.filePath}"

# Get active threads only
--query "value[?status==\`1\`].{id:id, file:threadContext.filePath}"

# Get thread comments
--query "value[].{id:id, comments:comments[].content}"
```

## Sources

- [Azure CLI az repos pr commands](https://learn.microsoft.com/en-us/cli/azure/repos/pr?view=azure-cli-latest)
- [Pull Request Threads - Create API](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads/create?view=azure-devops-rest-6.0)
- [Pull Request Thread Comments API](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-thread-comments?view=azure-devops-rest-7.1)
