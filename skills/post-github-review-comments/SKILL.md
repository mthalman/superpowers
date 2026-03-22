---
name: post-github-review-comments
description: Post code review findings as pending review comments on a GitHub pull request using the GitHub CLI. Use when the user asks to "post review comments", "add PR comments", "submit review comments", "post findings to PR", or when code review output needs to be turned into GitHub PR review comments. Also triggers on requests to comment on specific files/lines in a pull request.
---

# Post Review Comments

Post structured code review findings as pending review comments on a GitHub pull request. Comments are created as a **pending review** so the user can finalize and submit them on GitHub.

## Prerequisites

- `gh` CLI installed and authenticated
- The PR must exist and the authenticated user must have access

## Workflow

1. **Determine owner, repo, and PR number** from conversation context:
   - Check git remotes in the current working directory: `git remote get-url origin`
   - Parse `owner/repo` from the remote URL
   - Check for a PR associated with the current branch: `gh pr view --json number --jq .number`
   - If any of these cannot be inferred, ask the user

2. **Structure the review comments** as a JSON file containing an array. Write it to a temporary location. Each comment object has these fields:

   | Field        | Required | Description |
   |-------------|----------|-------------|
   | `path`      | yes      | File path relative to repo root |
   | `body`      | yes      | Comment text (markdown supported) |
   | `line`      | yes      | Line number the comment applies to (end line for multi-line) |
   | `start_line`| no       | Start line for multi-line range comments. Omit for single-line. |
   | `side`      | no       | Diff side: `"RIGHT"` (default, new code) or `"LEFT"` (old code) |

   **Important:** `line` and `start_line` refer to line numbers in the file at the PR's HEAD commit, not diff positions. Lines must be within the diff hunks of the PR — comments on unchanged lines will be rejected by the API.

3. **Run the script**:

   ```bash
   python <skill-path>/scripts/post_review.py \
     --owner <owner> \
     --repo <repo> \
     --pr <pr_number> \
     --input <path-to-comments.json> \
     --body "Optional overall review summary"
   ```

4. **Report the result** to the user. The review is PENDING — remind them to visit the PR on GitHub to submit it (approve, request changes, or comment).

## Extracting Comments from Code Review Output

When converting code review findings (like output from the `code-review` skill) into review comments:

- Map each finding to the file and line(s) it references
- For findings that reference a range of lines, use `start_line` and `line`
- For findings that reference a single line, use only `line`
- Skip findings that don't reference specific file locations (e.g., holistic assessments)
- Use markdown formatting in the body for readability

### Examples

**Multi-line comment** — a finding spanning lines 15-22:

```
#### ⚠️ Error Handling — Missing validation in parse_config

`src/config.py` lines 15-22: The `parse_config` function doesn't validate
the input before accessing nested keys, which will raise a KeyError.
```

Write JSON and call the script:
```bash
echo '[{"path":"src/config.py","body":"⚠️ **Error Handling — Missing validation in parse_config**\n\nThe `parse_config` function doesn'\''t validate the input before accessing nested keys, which will raise a `KeyError`.","line":22,"start_line":15}]' > /tmp/comments.json

python <skill-path>/scripts/post_review.py \
  --owner contoso --repo webapp --pr 47 \
  --input /tmp/comments.json
```

**Single-line comment** — a finding on line 8:

```
#### 💡 Naming — Unclear variable name

`src/config.py` line 8: `x` is not descriptive. Consider renaming to `config_path`.
```

Write JSON and call the script:
```bash
echo '[{"path":"src/config.py","body":"💡 **Naming — Unclear variable name**\n\n`x` is not descriptive. Consider renaming to `config_path`.","line":8}]' > /tmp/comments.json

python <skill-path>/scripts/post_review.py \
  --owner contoso --repo webapp --pr 47 \
  --input /tmp/comments.json
```
