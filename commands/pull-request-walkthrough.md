---
description: Walk through a pull request interactively, explaining code changes to help you understand how everything works. Supports GitHub and Azure DevOps.
---

# Pull Request Walkthrough

Guide a conversational, interactive walkthrough of a pull request. Act as a knowledgeable colleague sitting next to the reader, explaining what's happening in the code, why it's happening, and how the pieces fit together. The goal is understanding, not evaluation — help the reader build a clear mental model of the changes.

The reader controls the pace. Present one file (or group) at a time and wait before moving on.

## Prerequisites

- **GitHub PRs:** `gh` CLI installed and authenticated
- **Azure DevOps PRs:** `az` CLI installed and authenticated
- Can be run from any directory — if not inside the target repository, the repo will be cloned to a temp directory automatically (requires a PR URL, not just a number)

## Handling Checkout Conflicts

If `git checkout` fails due to uncommitted local changes conflicting with the PR branch, stash changes first (`git stash`), proceed with the checkout, and remind the user to `git stash pop` when done. If the PR branch has merge conflicts with the base, note this in the opening summary as a risk factor.

## Navigable Links

When referencing files and code lines throughout the review, use navigable links so the reader can jump directly to the relevant code.

**Link types (prefer PR diff view for changed files):**

- **PR diff view (changed files):** Link to the file in the PR's diff view so the reader sees the change in context.
  - **GitHub:** `https://github.com/{org}/{repo}/pull/{prNumber}/files#diff-{sha256hex}R{line}` — the anchor is the SHA256 hex digest of the file path; append `R{line}` for right-side (new file) line numbers.

    Compute the SHA256 anchor in PowerShell:
    ```powershell
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($filePath)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    $hex = [System.BitConverter]::ToString($hash).Replace('-', '').ToLower()
    # URL: https://github.com/{org}/{repo}/pull/{prNumber}/files#diff-{hex}R{line}
    ```
  - **Azure DevOps:** `https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{prNumber}?_a=files&path=/{filePath}&line={line}`
- **Blob view (unchanged files or files outside the PR):** For files not in the PR diff (e.g., related code explored during the walkthrough for context), link to the source at the head commit:
  - **GitHub:** `https://github.com/{org}/{repo}/blob/{headRefOid}/{filePath}#L{line}`
  - **Markdown files:** add `?plain=1` before the fragment: `.../{filePath}?plain=1#L{line}`
  - **Azure DevOps:** `https://dev.azure.com/{org}/{project}/_git/{repo}?path=/{filePath}&version=GC{headRefOid}&line={line}`
- **VS Code terminal links (local files):** Use `{relativePath}:{line}` format (e.g., `src/Foo.cs:42`) — VS Code terminals auto-detect these as clickable links.

**Formatting rules:**
- Use markdown link syntax: `[display text](url)` for GitHub/Azure DevOps links.
- For local file references in terminal output, plain `path:line` is sufficient (VS Code will make it clickable).
- Construct links from the PR metadata collected in Step 1 (`org`, `repo`, `prNumber`, `headRefOid`).
- **All file and line references must be navigable links** — not just files in the PR diff. This includes files explored for context during the walkthrough (e.g., callers, related code, dependencies).
- **Prefer PR diff view links for changed files** so the reader sees the diff context. Use blob view links only for files not in the PR.

## Workflow

### Step 0: Detect Walkthrough Scope (Full vs. Incremental)

Before starting, determine whether this is a **full walkthrough** or an **incremental walkthrough** covering only new changes since a previous session.

**Detection — check these in order:**

1. **User explicitly provides a commit:** If the user says something like "walk me through the changes since commit abc123" or "explain the new changes on PR #42", treat this as an incremental walkthrough starting from that commit. Skip the prompt below.

2. **Context history shows a prior walkthrough of this PR:** Search the conversation history for a previous walkthrough of the same PR (same org/repo/prNumber). If found, ask the user:
   - "I walked through this PR before (at commit `{previousHeadRefOid}`). The PR now has new commits. Would you like to:"
   - Choice 1: "Just explain the new changes since last time" (incremental)
   - Choice 2: "Start from the beginning" (full)
   - If the user chooses incremental, present the list of new commits (between the previous head and the current head) and let them confirm or pick a different starting point.

3. **No prior walkthrough found:** Proceed with a full walkthrough.

**Incremental walkthrough behavior:**

When doing an incremental walkthrough, use the selected commit as the base ref instead of the PR's base branch. This scopes the diff to only the changes made since that commit. The opening summary should note this is an incremental walkthrough and state the commit range. The closing wrap-up should cover only the new changes, but may reference context from the prior walkthrough if relevant.

For GitHub, `gh pr diff` does not support commit ranges. Use `git diff <sinceCommit>..<headRefOid>` for the incremental diff instead.

### Step 1: Detect Platform & Fetch PR Info

The user provides a PR URL or number. Execute the following substeps to gather all PR data.

#### Step 1a: Detect Platform

Determine whether the PR is on GitHub or Azure DevOps. Store the platform info (`platform`, `org`, `repo`, `project`, `prNumber`) for use in later steps.

**If the user provides a URL:**

- **GitHub:** Match `github.com/{org}/{repo}/pull/{number}` → platform = "github"
- **Azure DevOps:** Match `dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{number}` → platform = "azuredevops"
- **Azure DevOps (legacy):** Match `{org}.visualstudio.com/{project}/_git/{repo}/pullrequest/{number}` → platform = "azuredevops"

**If the user provides just a PR number:**

Inspect the git remote to detect the platform:

```bash
git remote -v
```

Match the origin fetch URL against these patterns:

- `github.com[:/]{org}/{repo}` → platform = "github"
- `dev.azure.com/{org}/{project}/_git/{repo}` → platform = "azuredevops"
- `{org}.visualstudio.com/{project}/_git/{repo}` → platform = "azuredevops"
- `ssh.dev.azure.com/v3/{org}/{project}/{repo}` → platform = "azuredevops"

Strip any trailing `.git` from the repo name.

#### Step 1b: Ensure Local Repository

After detecting the platform, verify that the current working directory is inside the target repository. If not, clone the repository to a temporary directory.

**Check if already in the target repo:**

```bash
git remote -v
```

If the current directory is a git repository whose origin remote matches `{org}/{repo}`, proceed directly to Step 1c — no clone needed.

**If the current directory is not a git repository or the remote doesn't match:**

- **If the user provided only a PR number** (no URL), stop with an error: "Not in a git repository for this PR. Please provide a full PR URL so I can clone the repo, or run this command from within the repository."
- **If the user provided a URL**, clone the repository (see below).

**Clone to a temporary directory:**

Use a path that uniquely identifies the repo and PR to avoid collisions with other reviews:

```
{TEMP}/pr-review/{org}-{repo}/pr-{prNumber}
```

Where `{TEMP}` is the system temporary directory (`$env:TEMP` on Windows, `/tmp` on Unix).

If the directory already exists from a previous session, remove it first to ensure a clean state.

**GitHub:**

```bash
gh repo clone {org}/{repo} "{clonePath}"
```

**Azure DevOps:**

```bash
git clone "https://dev.azure.com/{org}/{project}/_git/{repo}" "{clonePath}"
```

After cloning, `cd` into the clone directory for all subsequent steps.

**Track the clone state** — remember whether a clone was performed and the clone path so that cleanup can be offered at the end of the walkthrough (Step 4).

#### Step 1c: Fetch PR Metadata

**GitHub:**

```bash
gh pr view {prNumber} --repo "{org}/{repo}" --json title,body,comments,reviews,labels,headRefName,baseRefName,headRefOid,files,state,author,url
```

Also fetch `baseRefOid` separately (not available via `gh pr view --json`):

```bash
gh api "repos/{org}/{repo}/pulls/{prNumber}" --jq '.base.sha'
```

**Azure DevOps:**

```bash
az repos pr show --id {prNumber} --org "https://dev.azure.com/{org}" --output json
```

Extract the repository ID from the response, then fetch review threads:

```bash
az devops invoke --area git --resource threads \
  --route-parameters project="{project}" repositoryId="{repoId}" pullRequestId={prNumber} \
  --http-method GET --org "https://dev.azure.com/{org}" --api-version 7.1 --output json
```

**Key metadata to extract (both platforms):**

- `title`, `body`, `author`, `state`
- `baseRefName`, `headRefName`, `baseRefOid`, `headRefOid`
- Review comments/threads and review activity
- PR URL

For Azure DevOps, derive branch names by stripping `refs/heads/` prefix. Use `lastMergeTargetCommit.commitId` for `baseRefOid` and `lastMergeSourceCommit.commitId` for `headRefOid`.

#### Step 1d: Checkout PR Locally

**GitHub:**

```bash
gh pr checkout {prNumber} --repo "{org}/{repo}"
```

**Azure DevOps:**

```bash
# Fetch both branches
git fetch origin "{baseRef}"
git fetch origin "{headRef}"
git checkout "origin/{headRef}" -B "pr-{prNumber}"
```

If fetching the head ref fails, try the Azure DevOps PR ref format:

```bash
git fetch origin "+refs/pull/{prNumber}/merge:pr-{prNumber}"
git checkout "pr-{prNumber}"
```

#### Step 1e: Extract Diff Data

**GitHub:**

```bash
gh pr diff {prNumber} --repo "{org}/{repo}"
```

**Azure DevOps:**

Use the commitDiffs API to get the list of changed files:

```bash
az devops invoke --area git --resource commitDiffs \
  --route-parameters project="{project}" repositoryId="{repoId}" \
  --query-parameters baseVersion={baseRefOid} baseVersionType=commit targetVersion={headRefOid} targetVersionType=commit diffCommonCommit=true \
  --http-method GET --org "https://dev.azure.com/{org}" --api-version 7.1 --output json
```

Then get the per-file unified diff using the common commit returned by the API:

```bash
git diff --no-color "{commonCommit}..{headRefOid}" -- "{filePath}"
```

**Fallback (any platform):**

```bash
git merge-base {baseRef} {headRef}
git diff --no-color "{mergeBase}..{headRef}"
```

**Parse the unified diff output** to extract per-file data:

- File path and change type (added, deleted, modified, renamed, copied)
- Original file path (if renamed or copied)
- Lines added and removed per file
- Hunk locations (start line, end line, context)

### Step 2: Set the Stage

Before diving into files, set context so the reader knows what they're looking at and why.

**What This PR Does:**
- Summarize the purpose in plain language — what problem does it solve, what feature does it add, or what does it improve?
- Reference the PR title, description, and any linked issues
- If the PR description explains the approach or motivation, paraphrase it — don't make the reader go find it

**Scope at a Glance:**
- Total files changed, lines added/removed
- Categorize files: source code, tests, configuration, documentation, infrastructure

**Key Concepts:**
Before reading the code, give the reader any background they'll need:
- Domain concepts, patterns, or architectural ideas that the changes rely on
- The role of the parts of the codebase being touched — what do these modules/components do in the system?
- If the PR introduces a new pattern or changes an existing one, explain the pattern

**Reading Order:**
Present a numbered file list organized for progressive understanding — order files so each one builds on what came before:
1. Foundational changes (data models, types, interfaces) that other changes depend on
2. Core logic that implements the main behavior
3. Integration points — how the new code connects to existing code
4. Tests — which also serve as documentation of expected behavior
5. Configuration, build, and documentation changes

After presenting, ask the reader if they want to adjust the order or skip anything.

### Step 3: Interactive File-by-File Walkthrough

Present **one file at a time** (or one group, if files are grouped — see below). After each file or group, pause and wait for the reader before continuing.

**Grouping:** When multiple files follow the same pattern (e.g., several files all applying the same mechanical change), present them together. Explain the pattern once, show how it applies across the files, and note any interesting differences. A group counts as one "turn."

For each file (or group):

**File Header:**
Display the filename as a navigable link, change type (modified/added/deleted/renamed), and line count (e.g., "+15 / -3").

**Build Context:**
- Read the full file to understand its role in the system, not just the changed lines
- Get the file-specific diff using `git diff <baseRef>..<headRef> -- <file>`
- Understand what this file does — its purpose, its relationships to other files, how it's called or used
- If this file connects to something discussed in a previous file, make that connection explicit: "Remember the `UserService` interface we saw earlier? This is the implementation."

**Walk Through the Changes:**

This is the heart of the walkthrough. Explain the changes conversationally, as if sitting next to the reader and narrating what you see. Aim for clarity and insight — not exhaustive line-by-line narration and not surface-level description.

- **Start with intent.** What is this file change trying to accomplish? How does it serve the overall PR goal?
- **Explain the "what" and the "why."** Don't just describe that code was added or removed — explain what it does and why it's written this way. "This adds a retry loop around the HTTP call, so transient failures don't immediately bubble up to the caller."
- **Highlight design choices.** When the author made a non-obvious decision, point it out and explain the reasoning if you can infer it. If there were plausible alternatives, mention why this approach was likely chosen. "They're using a channel here instead of a shared list — that avoids the need for locking."
- **Connect the dots.** Show how this file's changes relate to changes in other files already discussed or coming up. "This new `validate()` method is what gets called from the handler we'll see next."
- **Explain unfamiliar patterns.** If the code uses a pattern, library feature, or idiom that might not be immediately obvious, explain it briefly. Don't assume the reader knows every pattern.
- **Call out what's unchanged but important.** If understanding a change requires knowing about surrounding code that didn't change, explain that context. "The existing `processQueue()` function runs on a timer — this change adds items to the queue that it will pick up."
- **Use concrete language.** Refer to specific functions, variables, and types by name. Use navigable links (see Navigable Links section) for all file and line references.

**Pause and invite questions.** After each file or group, check in naturally:
- "Does this make sense? Any questions before we move on?"
- If the reader wants to go deeper on something, follow their curiosity — that's the point of the walkthrough
- If a question leads to exploring related code outside the PR, go there — understanding the context is part of the goal

### Step 4: Wrap Up

After all files have been walked through:

**The Big Picture:**
Tie everything together. Now that the reader has seen all the individual changes, explain how they work as a whole:
- How do the pieces connect? Walk through the flow end-to-end. (e.g., "A request comes in at the handler, gets validated by the new validator, processed by the updated service, and the result is cached using the new cache layer we saw.")
- What's the net effect on the system's behavior? What will be different for users or other developers after this PR?
- If there are interesting architectural or design themes that emerged across multiple files, summarize them

**Key Takeaways:**
List 3–5 things the reader should remember — the most important concepts, patterns, or decisions introduced by this PR. Think of these as what you'd want someone to know if they asked "what was that PR about?" in a week.

**Things You Might Want to Ask the Author:**
Suggest questions about areas where the intent wasn't clear from the code alone — design decisions that could go either way, trade-offs that aren't documented, or behavior that depends on context you couldn't determine.

**Offer a Code Review:**
After the walkthrough wrap-up, ask the reader if they'd like you to perform a code review analysis on the changes. If they accept, apply the superpowers:code-review skill to analyze the PR diff for correctness, performance, safety, and quality issues. Present the review findings using the superpowers:code-review skill's severity classification and format.

**Cleanup (cloned repos only):**

If the repository was cloned to a temporary directory in Step 1b, ask the reader:

- "The repository was cloned to `{clonePath}` for this walkthrough. Would you like me to delete it?"
- If yes: remove the clone directory and confirm deletion
- If no: inform the user of the path so they can clean it up later or reuse it

## Handling Large PRs

For PRs with many files (>20):
- Group files by component or module
- Offer to focus on the most important or complex areas first, and summarize simpler changes at a higher level
- Ask the reader what they most want to understand — let their curiosity guide the depth
