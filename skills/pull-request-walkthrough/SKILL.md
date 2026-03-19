---
name: pull-request-walkthrough
description: Use when walking through a pull request interactively, checking out PRs, examining diffs file by file, or guiding a structured PR review session. Handles PR platform detection, checkout, diff extraction, and interactive file-by-file walkthrough for both GitHub and Azure DevOps. Use this whenever a PR number or URL is mentioned in the context of reviewing or examining changes, when the user says things like "look at this diff", "review these changes", "check this PR", "walk me through the PR", or "what changed in PR #N". For the actual code analysis criteria, this skill delegates to the code-review skill.
---

# Reviewing Pull Request

Guide a structured, interactive walkthrough of a pull request. This skill handles the mechanics — detecting the platform, checking out the PR, extracting diffs, and orchestrating a file-by-file review session with the user. For the actual analysis (what to look for, how to evaluate findings, severity classification), apply the guidance from the **code-review** skill.

The user maintains full control over what gets posted. This skill does not post comments automatically.

## Prerequisites

- **GitHub PRs:** `gh` CLI installed and authenticated
- **Azure DevOps PRs:** `az` CLI installed and authenticated
- Must be in a git repository (or able to clone one)
- **code-review** skill should be available for analysis criteria — if unavailable, apply general code review best practices (correctness, safety, performance, readability) inline

## Handling Checkout Conflicts

If `git checkout` fails due to uncommitted local changes conflicting with the PR branch, stash changes first (`git stash`), proceed with the checkout, and remind the user to `git stash pop` when done. If the PR branch has merge conflicts with the base, note this in the opening summary as a risk factor.

## Navigable Links

When referencing files and code lines throughout the review, use navigable links so the reviewer can jump directly to the relevant code.

**Link types (prefer PR diff view for changed files):**

- **PR diff view (changed files):** Link to the file in the PR's diff view so the reviewer sees the change in context. Use the `Get-PrFileUrl.ps1` helper script to generate these URLs:
  ```powershell
  pwsh -File "<skill-path>/scripts/Get-PrFileUrl.ps1" `
    -Platform $platform.platform -Org $platform.org -Repo $platform.repo `
    -PrNumber $platform.prNumber -FilePath "src/Foo.cs" -LineNumber 42 `
    -Project $platform.project
  ```
  - **GitHub:** `https://github.com/{org}/{repo}/pull/{prNumber}/files#diff-{sha256hex(filePath)}R{line}` — the anchor is the SHA256 hex digest of the file path; append `R{line}` for right-side (new file) line numbers.
  - **Azure DevOps:** `https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{prNumber}?_a=files&path=/{filePath}&line={line}`
- **Blob view (unchanged files or files outside the PR):** For files not in the PR diff (e.g., affected callers discovered during analysis), link to the source at the head commit:
  - **GitHub:** `https://github.com/{org}/{repo}/blob/{headRefOid}/{filePath}#L{line}`
  - **Markdown files:** add `?plain=1` before the fragment: `.../{filePath}?plain=1#L{line}`
  - **Azure DevOps:** `https://dev.azure.com/{org}/{project}/_git/{repo}?path=/{filePath}&version=GC{headRefOid}&line={line}`
- **VS Code terminal links (local files):** Use `{relativePath}:{line}` format (e.g., `src/Foo.cs:42`) — VS Code terminals auto-detect these as clickable links.

**Formatting rules:**
- Use markdown link syntax: `[display text](url)` for GitHub/Azure DevOps links.
- For local file references in terminal output, plain `path:line` is sufficient (VS Code will make it clickable).
- Construct links from the PR metadata collected in Step 1 (`org`, `repo`, `prNumber`, `headRefOid`).
- **All file and line references must be navigable links** — not just files in the PR diff. This includes files discovered during analysis (e.g., stale references, affected callers, related code). Every table cell containing a file path or line number should be a link.
- **Prefer PR diff view links for changed files** so the reviewer sees the diff context. Use blob view links only for files not in the PR.

## Workflow

### Step 0: Detect Review Scope (Full vs. Incremental)

Before starting the review, determine whether this is a **full review** or an **incremental review** of new changes since a previous review.

**Detection — check these in order:**

1. **User explicitly provides a commit:** If the user says something like "review since commit abc123" or "review the new changes on PR #42", treat this as an incremental review starting from that commit. Skip the prompt below.

2. **Context history shows a prior review of this PR:** Search the conversation history for a previous review of the same PR (same org/repo/prNumber). If found, ask the user:
   - "I found a previous review of this PR (at commit `{previousHeadRefOid}`). The PR now has new commits. Would you like to:"
   - Choice 1: "Review only the new changes since my last review" (incremental)
   - Choice 2: "Start the review over from scratch" (full)
   - If the user chooses incremental, present the list of new commits (between the previous head and the current head) and let them confirm or pick a different starting point.

3. **No prior review found:** Proceed with a full review.

**Incremental review behavior:**

When doing an incremental review, use the selected commit as the base ref instead of the PR's base branch. This scopes the diff to only the changes made since that commit. The opening summary should note this is an incremental review and state the commit range. The closing summary should cover only the new changes, but may reference findings from the prior review if relevant.

For GitHub, `gh pr diff` does not support commit ranges. Use `git diff <sinceCommit>..<headRefOid>` for the incremental diff instead.

### Step 1: Detect Platform & Fetch PR Info

Run the helper scripts to gather PR data. The user provides a PR URL or number.

```powershell
# 1. Detect platform (GitHub vs Azure DevOps)
$platformJson = pwsh -File "<skill-path>/scripts/Get-PrPlatform.ps1" -PrInput "<url-or-number>"
$platform = $platformJson | ConvertFrom-Json

# 2. Fetch PR metadata (title, description, comments, linked issues)
$metadataJson = pwsh -File "<skill-path>/scripts/Get-PrMetadata.ps1" `
  -Platform $platform.platform -Org $platform.org -Repo $platform.repo `
  -PrNumber $platform.prNumber -Project $platform.project
$metadata = $metadataJson | ConvertFrom-Json

# 3. Checkout PR locally
pwsh -File "<skill-path>/scripts/Checkout-Pr.ps1" `
  -Platform $platform.platform -Org $platform.org -Repo $platform.repo `
  -PrNumber $platform.prNumber -Project $platform.project `
  -BaseRef $metadata.baseRefName -HeadRef $metadata.headRefName

# 4. Extract diff data
$diffJson = pwsh -File "<skill-path>/scripts/Get-PrDiff.ps1" `
  -BaseRef $metadata.baseRefOid -HeadRef $metadata.headRefOid `
  -Platform $platform.platform -Org $platform.org -Repo $platform.repo `
  -PrNumber $platform.prNumber -Project $platform.project
$diff = $diffJson | ConvertFrom-Json
```

Replace `<skill-path>` with the actual path to this skill's directory.

### Step 2: Present Opening Summary

Before starting the file-by-file walkthrough, present a summary built from the PR metadata and diff data collected in Step 1.

**PR Purpose:**
- Title and description from the PR metadata
- Linked issues or work items (if any)
- What the PR is trying to accomplish

**Scope:**
- Total files changed, lines added/removed
- Categorize files: source code, tests, configuration, documentation, infrastructure

**Risk Assessment:**
Flag anything that warrants extra scrutiny:
- Security-sensitive changes (auth, crypto, input handling, permissions)
- Complex algorithmic or business logic changes
- Public API or interface changes (breaking change potential)
- Database migrations or schema changes
- Changes to critical paths (payment, data integrity)

**Existing Review Activity:**
- Summarize existing review comments or approvals from the PR metadata
- Note any unresolved threads

**Recommended Review Order:**
Present a numbered file list with brief rationale, ordered by review priority:
1. Core logic — models, business rules, algorithms
2. API/interface changes — external contracts, public surface
3. Tests — verify coverage and correctness
4. Configuration/infrastructure — build, CI/CD, config files
5. Documentation — README, inline docs, changelogs

After presenting the summary, ask the reviewer if they want to adjust the order or skip any files.

### Step 3: Interactive File-by-File Walkthrough

Present **one file at a time** (or one group, if files are grouped — see below). After presenting each file or group, pause and wait for the reviewer before continuing. This keeps each response focused and easy to digest.

**Grouping:** When multiple files follow the same pattern (e.g., several files all applying the same mechanical change), they may be presented together as a single group. State why they are grouped and review them collectively. A group counts as one "turn" — pause after presenting the group, not after each file within it.

For each file (or group) in the review order:

**File Header:**
Display the filename as a navigable link (GitHub/Azure DevOps permalink to the file at the head commit, or `path:line` for VS Code), change type (modified/added/deleted/renamed), and line count (e.g., "+15 / -3").

**Read Context:**
- Read the full file for surrounding context — you need to understand the code to review it well
- Get the file-specific diff using `git diff <baseRef>..<headRef> -- <file>`
- **Complete code-review Step 0 (Gather Code Context) for this file before presenting any analysis.** This includes tracing callers/consumers, data producers, execution context, and related code. Do not present a file walkthrough that only describes what changed — the description exists to frame the analysis, not replace it.

**Change Explanation:**
Provide a plain-English walkthrough of what changed and why. Focus on the intent behind the changes, not line-by-line narration. Reference specific line numbers as navigable links (see Navigable Links section).

**Analysis & Review Comments:**
Apply the **code-review** skill's analysis guidance to generate review comments for the changed code. Use its severity classification (❌ Error, ⚠️ Warning, 💡 Suggestion, ✅ Verified) and follow its process for forming an independent assessment, verifying against the PR narrative, and avoiding false positives.

For each issue found, provide:
- **Line number(s)** as navigable links — permalink to the line(s) in the source at the head commit, or `path:line` for VS Code
- **Severity** — per the code-review skill's classification
- **Description** of the issue
- **Suggested fix** when applicable (code snippet or approach)

Restrict all review comments to lines within the PR diff. Read surrounding code for context, but do not flag pre-existing issues in unchanged lines.

**Pause after each file or group.** Ask the reviewer:
- "Any questions about this file, or should I continue to the next one?"
- If they want to dig deeper into something, explore it before moving on

### Step 4: Closing Summary

After all files have been reviewed, present:

**Overall Assessment:**
One paragraph on the PR's quality, completeness, and readiness. Be direct.

**Recommendation:**
One of:
- ✅ **LGTM** — changes are sound, no blocking issues
- ⚠️ **Needs Changes** — blocking issues must be addressed before merging
- ⚠️ **Needs Human Review** — concerns that require human judgment
- ❌ **Reject** — fundamental problems with the approach

Follow the code-review skill's verdict rules for consistency between findings and recommendation.

**Collected Review Comments:**
Consolidated table of all comments made during the walkthrough. File names and line numbers should be navigable links (see Navigable Links section):

| File | Line(s) | Severity | Comment |
|------|---------|----------|---------|

**Key Risks:**
- Interaction effects between files that might not be obvious from individual file reviews
- Missing test coverage for changed behavior
- Potential regression risks

**Questions for the Author:**
Suggest questions about ambiguous design choices or unclear intent — things the reviewer might want to ask the PR author.

**Remind the reviewer:** This skill does not post comments automatically. The reviewer decides what to post and how, using the `github-pr-reviews` or `azure-devops-pr-reviews` skills if needed.

## Handling Large PRs

For PRs with many files (>20):
- Group files by component or module in the review order
- Offer to focus on highest-risk files first and skim lower-risk ones
- Ask the reviewer if they want the full walkthrough or a targeted review of specific areas

