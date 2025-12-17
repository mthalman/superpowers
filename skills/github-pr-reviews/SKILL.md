---
name: github-pr-reviews
description: Use when creating or modifying GitHub PR reviews via API, adding comments to pending reviews, or getting errors like "user can only have one pending review" - provides correct gh api commands and explains REST vs GraphQL limitations
---

# GitHub PR Reviews via API

## Overview

Create and modify GitHub pull request reviews using `gh api`.

**The key insight:** REST API cannot add comments to existing pending reviews, but GraphQL can.

## Core Principles

### 1. Prefer Simplicity
Always choose the simplest tool that meets requirements:
- CLI over API when functionality is equivalent
- REST over GraphQL when capabilities match
- Built-in commands over custom scripts
- Fewer steps over more steps

**When to use complex approaches:**
- Requirements cannot be met by simple tools
- Automation requires programmatic output (JSON)
- Integration with other systems needs specific API features

### 2. Preserve Data Before Destructive Operations
Before ANY destructive operation (deleting reviews, force-pushing), ALWAYS extract affected data first:

1. **Identify what will be lost**: Comments, review state, metadata
2. **Extract to durable storage**: JSON files, local backups
3. **Verify extraction succeeded**: Check file exists and contains expected data
4. **THEN perform destructive operation**

**Why:** Comments represent human effort. Loss is expensive and frustrating. Never delete without backup.

### 3. Articulate Trade-offs
For each recommendation, explain:
- **Why this approach** over alternatives
- **When to deviate** from this recommendation
- **What you're trading** for what benefit

### Quick Reference

| Task | API | Command |
|------|-----|---------|
| Simple approval | CLI | `gh pr review {pr} --approve --body "LGTM"` |
| Create pending review | REST | `gh api repos/{owner}/{repo}/pulls/{pr}/reviews --method POST --input -` |
| Add to existing pending review | **GraphQL** | `gh api graphql -f query='mutation { addPullRequestReviewComment(...) }'` |
| Find pending review | REST | `gh api repos/{owner}/{repo}/pulls/{pr}/reviews --jq '.[] | select(.state=="PENDING")'` |
| Submit pending review | REST | `gh api repos/{owner}/{repo}/pulls/{pr}/reviews/{id}/events --method POST -f event=APPROVE` |
| Delete pending review | REST | `gh api repos/{owner}/{repo}/pulls/{pr}/reviews/{id} --method DELETE` |

## Key Concepts

### REST Cannot Add to Existing Pending Reviews

`POST /repos/{owner}/{repo}/pulls/{pr}/reviews` ALWAYS creates a new review. If a pending review exists, you get: `"user can only have one pending review per pull request"`

**Common trap:** Using `pull_request_review_id` parameter with REST does NOT add to the pending review - it creates a standalone comment that won't be bundled when you submit.

**Note:** `POST /repos/{owner}/{repo}/pulls/{pr}/comments` creates **immediately visible standalone comments** - these do NOT attach to your pending review.

**Decision rule:**
- Creating first review → REST
- Adding to existing pending review → GraphQL (mandatory)

### Position vs Line

| Parameter | API | Meaning |
|-----------|-----|---------|
| `line` | REST | Actual line number in file |
| `position` | GraphQL | Position in diff hunk (count from 1 after `@@`) |

**These are NOT interchangeable.** Using the wrong one places comments on wrong lines.

```
@@ -13,7 +13,7 @@     <- not counted
 unchanged line         <- position 1
 unchanged line         <- position 2
-old line               <- position 3
+new line               <- position 4  <-- to comment here, use position=4
```

Get diff with: `gh pr diff {pr}`

### Pending vs Immediate Submission

**Use pending when:**
- Adding comments incrementally over time
- Need to verify before submission
- Comments span many files

**Submit immediately when:**
- Simple LGTM approval
- All comments prepared in advance
- Single comment with clear decision

**Trade-off:** Pending reviews become stale if author force-pushes before you submit.

## How-To

### Simple Approval

```bash
# Option 1: CLI (simplest)
gh pr review {pr} --approve --body "LGTM"

# Option 2: API (if you need more control)
COMMIT=$(gh pr view {pr} --json headRefOid --jq '.headRefOid')
cat << 'EOF' | gh api repos/{owner}/{repo}/pulls/{pr}/reviews --method POST --input -
{
  "commit_id": "COMMIT_SHA",
  "event": "APPROVE",
  "body": "Looks good!"
}
EOF
```

Valid events: `"APPROVE"`, `"REQUEST_CHANGES"`, `"COMMENT"`

### Multi-Comment Review Workflow

```bash
# 1. Get PR info
PR=123
OWNER=owner
REPO=repo
COMMIT=$(gh pr view $PR --repo $OWNER/$REPO --json headRefOid --jq '.headRefOid')

# 2. Create pending review with initial comments (REST)
REVIEW=$(cat << EOF | gh api repos/$OWNER/$REPO/pulls/$PR/reviews --method POST --input - --jq '.node_id'
{
  "commit_id": "$COMMIT",
  "comments": [
    {"path": "src/File1.cs", "line": 10, "body": "First comment"},
    {"path": "src/File2.cs", "line": 20, "body": "Second comment"}
  ]
}
EOF
)

# 3. Add more comments later (GraphQL - required for existing pending review)
gh api graphql -f query="
mutation {
  addPullRequestReviewComment(input: {
    pullRequestReviewId: \"$REVIEW\",
    path: \"src/File3.cs\",
    position: 5,
    body: \"Third comment\"
  }) { comment { id } }
}"

# 4. Submit when ready
REVIEW_ID=$(gh api repos/$OWNER/$REPO/pulls/$PR/reviews --jq '.[] | select(.state=="PENDING") | .id')
gh api repos/$OWNER/$REPO/pulls/$PR/reviews/$REVIEW_ID/events --method POST -f event=COMMENT
```

### Adding to Existing Pending Review

If you already have a pending review and need to add comments:

```bash
# 1. Find your pending review's node_id
REVIEW_NODE_ID=$(gh api repos/{owner}/{repo}/pulls/{pr}/reviews --jq '.[] | select(.state=="PENDING") | .node_id')

# 2. Calculate position from diff (not line number!)
gh pr diff {pr}  # Find your target line, count position from @@

# 3. Add comment via GraphQL
gh api graphql -f query='
mutation {
  addPullRequestReviewComment(input: {
    pullRequestReviewId: "'"$REVIEW_NODE_ID"'",
    path: "src/File.cs",
    position: 5,
    body: "Your comment"
  }) {
    comment { id }
  }
}'
```

## Troubleshooting

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `"user can only have one pending review"` | Tried REST while pending exists | Use GraphQL `addPullRequestReviewComment` |
| `"Variable $event... invalid value"` | Used `-f event=PENDING` | Omit event field entirely for pending |
| `"line is not a permitted key"` | Used `line` in GraphQL | Use `position` instead |
| `"pull_request_review_id is invalid"` | Used numeric ID in GraphQL | Use `node_id` (starts with `PRR_`) |
| Comment on wrong line | Confused position/line | Position = diff offset, line = file line |
| `"line not in diff"` | Line wasn't changed | Can only comment on lines in the diff |

### Force-Push Recovery

Force-push invalidates your pending review (commit SHA no longer exists).

**Recovery (preserving your work):**
```bash
# 1. FIRST: Extract existing comments (preserve your work!)
REVIEW_ID=$(gh api repos/{owner}/{repo}/pulls/{pr}/reviews --jq '.[] | select(.state=="PENDING") | .id')
gh api repos/{owner}/{repo}/pulls/{pr}/reviews/$REVIEW_ID/comments > pending_comments_backup.json

# 2. Verify backup contains your comments
cat pending_comments_backup.json | jq -r '.[].body' | head -3

# 3. NOW safe to delete stale pending review
gh api repos/{owner}/{repo}/pulls/{pr}/reviews/$REVIEW_ID --method DELETE

# 4. Get new commit SHA
NEW_COMMIT=$(gh pr view {pr} --json headRefOid --jq '.headRefOid')

# 5. Recreate review with new commit and restore comments
NEW_REVIEW=$(cat << EOF | gh api repos/{owner}/{repo}/pulls/{pr}/reviews --method POST --input - --jq '.node_id'
{
  "commit_id": "$NEW_COMMIT",
  "comments": $(cat pending_comments_backup.json | jq '[.[] | {path, line, body, side: "RIGHT"}]')
}
EOF
)

echo "Review recreated. Verify comments at correct lines - code may have shifted."
```

**If code changed significantly:**
- Line numbers may have shifted - verify each comment location against new diff
- Files may be renamed - check with `gh api repos/{owner}/{repo}/pulls/{pr}/files`
- Some comments may no longer apply - review diff manually before submitting

**Alternative: Convert to regular comments (simpler, loses review grouping):**
```bash
# If you don't need pending review state, convert to standalone comments
jq -c '.[]' pending_comments_backup.json | while read comment; do
  BODY=$(echo $comment | jq -r '.body')
  PATH=$(echo $comment | jq -r '.path')
  gh pr comment {pr} --body "**$PATH**: $BODY"
done
```

**Trade-off:** Maintain review state (recommended approach) vs. convert to regular comments (simpler recovery, but loses batched review structure).

**Prevention:** Submit partial reviews frequently rather than accumulating a large pending review.

## Reference

### Comment Parameters (REST)

```json
{
  "path": "src/File.cs",
  "line": 45,
  "side": "RIGHT",
  "body": "Comment text"
}
```

- `side`: `"RIGHT"` = new/added lines, `"LEFT"` = old/deleted lines
- `line`: File line number (from NEW file for RIGHT, OLD file for LEFT)

**Multi-line comments:**
```json
{
  "path": "src/File.cs",
  "start_line": 45,
  "line": 50,
  "side": "RIGHT",
  "body": "Spans lines 45-50"
}
```

For LEFT side ranges, you MUST include both:
- `"side": "LEFT"`
- `"start_side": "LEFT"`

### Verification

```bash
# List comments on PR
gh api repos/{owner}/{repo}/pulls/{pr}/comments --jq '.[] | {path, line, body}'

# Check what lines are commentable
gh api repos/{owner}/{repo}/pulls/{pr}/files --jq '.[].patch'
```

### Checking for Existing Pending Review

Before creating a new review, check if one exists:
```bash
EXISTING=$(gh api repos/{owner}/{repo}/pulls/{pr}/reviews --jq '.[] | select(.state=="PENDING") | .node_id')
if [ -n "$EXISTING" ]; then
  # Add to existing via GraphQL
else
  # Create new via REST
fi
```

## API Selection Guide

### Decision Tree

```
Need simple approval/request changes?
├─ YES → Use CLI: gh pr review --approve
└─ NO → Continue

Adding to EXISTING pending review?
├─ YES → Must use GraphQL (REST always creates new review)
└─ NO → Continue

Need programmatic control or JSON output?
├─ YES → Use REST API
└─ NO → Use CLI for simplicity
```

### REST vs GraphQL Comparison

| Scenario | REST | GraphQL | Recommendation |
|----------|------|---------|----------------|
| Simple approval | ✅ Works | ✅ Works | CLI simplest |
| Create pending review | ✅ Works | ✅ Works | REST simpler |
| Add to existing pending | ❌ Fails | ✅ Required | GraphQL only |
| Multi-line comments | ✅ Works | ✅ Works | REST simpler |
| Bot automation | ✅ Easy | ⚠️ Complex | REST preferred |
| Batch mutations | ⚠️ Multiple calls | ✅ Single call | GraphQL for batches |

### line vs position Parameters

| Parameter | Used In | Meaning | Example |
|-----------|---------|---------|---------|
| `line` | REST | Actual line number in file | Line 45 = `line: 45` |
| `position` | GraphQL | Offset in diff hunk | Count from `@@` header |

**These are NOT interchangeable.** Using wrong parameter places comments on wrong lines.

**Trade-off:** REST's `line` parameter is simpler (just use the line number). GraphQL's `position` requires parsing the diff. Prefer REST when possible.
