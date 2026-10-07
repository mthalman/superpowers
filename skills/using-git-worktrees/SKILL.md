---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current workspace, before executing implementation plans, or when auditing linked worktrees for active, unpublished, merged, or potentially removable work. Prefers host-native isolation, falls back to Git worktrees, and provides a conservative read-only PowerShell audit.
compatibility: Requires Git. Audit mode requires PowerShell 7 or later; GitHub PR enrichment optionally uses gh.
---

# Using Git Worktrees

## Overview

Ensure feature work happens in an isolated workspace. Prefer the platform's
native isolation tools. Fall back to manual Git worktrees only when no native
tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then
fall back to Git. Never fight the harness.

**Large-repository exception:** When native session/worktree initialization
has timed out, or the user explicitly requests a parent-managed manual
worktree session, use `manual-worktree-session` instead of retrying native
creation. It verifies a manually created checkout before registering it as an
existing project and attaching an in-place child session.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an
isolated workspace."

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

Use this order only after Step 0 says a new isolated workspace is appropriate.

1. **Native worktree tools first.** If the host provides `EnterWorktree`,
   `WorktreeCreate`, `/worktree`, a `--worktree` flag, or equivalent, use it and
   skip to Step 2. Native tools own placement, branch creation, and cleanup.
2. **Git worktree fallback only when no native tool exists.** Choose a location
   by priority: explicit user preference, existing `.worktrees`, existing
   `worktrees`, then default `.worktrees/` at the project root.
3. **Verify project-local paths are ignored before creation.** Run
   `git check-ignore -q "$LOCATION/"`. If it is not ignored, ask before editing
   `.gitignore`; do not commit that change without separate approval. If you
   cannot ask, work in place.
4. Create the path with `git worktree add <path> -b <branch-name>`, then move
   the working directory to the new worktree.

If `git worktree add` fails with a permission error, tell the user the sandbox
blocked worktree creation, then run setup and baseline tests in place.

Open `references/manual-worktree-fallback.md` when you need the detailed Git
fallback decision order, ignore-check rationale, or common fallback mistakes.

## Step 2: Project Setup

Auto-detect the project and use its documented setup command. Common signals
include `package.json`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, and
`go.mod`. Prefer lockfile-aware package-manager commands and existing
repository scripts over generic installation commands.

## Step 3: Verify Clean Baseline

Run the smallest existing test command that establishes a clean baseline for the
planned work.

If tests fail, report failures and ask whether to proceed or investigate. If
tests pass, report ready.

```text
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Audit Existing Worktrees

Open `references/worktree-audit.md` when the user asks which linked worktrees
are active, abandoned, safe to inspect for removal, or need a conservative
read-only audit. The audit script remains at `scripts/Get-WorktreeAudit.ps1`.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation; continue at Step 2 |
| In a submodule | Treat as normal repo after the submodule guard |
| Native worktree tool available | Use it instead of `git worktree add` |
| No native tool | Use Git fallback with ignored project-local path |
| Directory not ignored | Ask before editing `.gitignore`; commit only with separate approval |
| Permission error on create | Work in place and report the sandbox fallback |
| Tests fail during baseline | Report failures and ask before proceeding |
| No recognized setup instructions | Skip dependency installation |
| Need worktree cleanup | Run the audit; never delete without approval |

## Non-Negotiable Rules

**Never:**
- Create a worktree when Step 0 detects existing isolation.
- Use `git worktree add` when a working native worktree tool is available,
  except for the explicit `manual-worktree-session` timeout workflow.
- Skip Step 1a by jumping straight to Step 1b's Git commands.
- Create a project-local worktree without verifying it is ignored.
- Skip baseline test verification.
- Proceed with failing tests without asking.

**Always:**

- Run Step 0 detection first.
- Prefer native tools over Git fallback.
- Follow directory priority: explicit instructions, existing project-local
  directory, then default.
- Verify project-local worktree directories are ignored.
- Auto-detect and run project setup.
- Verify a clean test baseline.
