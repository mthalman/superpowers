---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current workspace, before executing implementation plans, or when auditing linked worktrees for active, unpublished, merged, or potentially removable work. Prefers host-native isolation, falls back to Git worktrees, and provides a conservative read-only PowerShell audit.
compatibility: Requires Git. Audit mode requires PowerShell 7 or later; GitHub PR enrichment optionally uses gh.
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

Use `git rev-parse --git-dir`, `git rev-parse --git-common-dir`, and
`git branch --show-current` through the host's shell. Resolve both Git
directories to absolute paths before comparing them.

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

Run `git rev-parse --show-superproject-working-tree`. If it returns a path, the
checkout is a submodule rather than an isolated worktree.

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.
If the host cannot ask interactively, work in place without changing repository
configuration.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory.** Prefer
   `.worktrees`; otherwise use `worktrees`.
   If found, use it. If both exist, `.worktrees` wins.

3. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

Run `git check-ignore -q "$LOCATION/"` for the selected directory only. The
trailing separator tests directory rules even before the directory exists.

**If NOT ignored:** Ask before changing `.gitignore`. If the user approves,
add the selected directory rule. Do not commit that change without separate
commit approval.

If the user declines the `.gitignore` change, ask whether to use an external
worktree path or continue in the current workspace. Do not create an unignored
project-local worktree.

If the host cannot ask interactively, do not change `.gitignore` or create the
project-local worktree. Work in place.

**Why critical:** Prevents accidentally committing worktree contents to repository.

#### Create the Worktree

Create the path under the selected location, then run
`git worktree add <path> -b <branch-name>` and move the working directory to
the new worktree.

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 2: Project Setup

Auto-detect the project and use its documented setup command. Common signals
include `package.json`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, and
`go.mod`. Prefer lockfile-aware package-manager commands and existing
repository scripts over generic installation commands.

## Step 3: Verify Clean Baseline

Run tests to ensure workspace starts clean:

Use the smallest existing test command that establishes a clean baseline for
the planned work.

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Audit Existing Worktrees

When the user asks which worktrees are active, abandoned, or safe to inspect
for removal, run the bundled read-only audit:

Resolve this skill's installed directory, then run its bundled script. Do not
resolve `scripts/` relative to the user's repository:

```powershell
$audit = Join-Path <skill-root> 'scripts' 'Get-WorktreeAudit.ps1'
pwsh -File $audit -RepoPath <repo>
```

The audit combines:

- tracked and untracked changes;
- `assume-unchanged` and `skip-worktree` index flags that can hide edits;
- local merge reachability from the base branch;
- ahead, behind, diverged, detached, or unpushed branch state;
- GitHub pull request state when a GitHub remote is available;
- optional activity timestamps supplied by the host;
- optional directory size.

When size collection is requested, `SizeComplete` reports whether every file
was readable. Do not treat an incomplete size as exact.

The script does not delete worktrees. Treat `safe-merged` as a recommendation
to inspect, not permission to remove. Require explicit approval before any
cleanup.

The script detects the upstream remote and its default branch. Pass
`-RemoteName` or `-BaseBranch` when detection is ambiguous. It never fetches or
updates remote-tracking refs. Refresh them separately only with user approval.

Useful options:

```powershell
# Include directory sizes
pwsh -File $audit -RepoPath <repo> -IncludeSize

# Emit structured JSON
pwsh -File $audit -RepoPath <repo> -AsJson

# Supply host activity as { "<absolute-path>": "<ISO-8601 timestamp>" }
pwsh -File $audit `
  -RepoPath <repo> `
  -ActivityDataPath <activity.json>
```

The buckets are conservative:

| Bucket | Meaning |
|---|---|
| `hold-wip` | Tracked edits exist |
| `hold-open-pr` | An open PR exists |
| `hold-locked` | Git marks the worktree as locked |
| `verify-recent-activity` | The host reports recent worktree activity |
| `review-prunable` | Git reports a missing or prunable worktree |
| `review-index-flags` | Index flags can hide working-tree changes |
| `review-pr-unknown` | GitHub PR lookup failed unexpectedly |
| `review-scratch` | Untracked files require inspection |
| `review-closed-pr` | A PR closed without verified merge evidence |
| `review-unpublished` | Detached, unpushed, ahead, diverged, or remote-unknown state |
| `review` | No signal proves the worktree disposable |
| `safe-merged` | The exact HEAD is reachable from base or covered by a merged PR |

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Ask before editing `.gitignore`; commit only with separate approval |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No recognized setup instructions or manifest | Skip dependency installation |
| Need worktree cleanup | Run the audit; never delete without approval |

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: explicit instructions > existing project-local directory > default

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

## Red Flags

**Never:**
- Create a worktree when Step 0 detects existing isolation
- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
- Skip Step 1a by jumping straight to Step 1b's git commands
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Run Step 0 detection first
- Prefer native tools over git fallback
- Follow directory priority: explicit instructions > existing project-local directory > default
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline
