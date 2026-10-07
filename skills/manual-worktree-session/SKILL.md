---
name: manual-worktree-session
description: Create a Git worktree manually and attach an in-place Copilot child session when large repositories such as the dotnet VMR exceed native session/worktree initialization timeouts, or when the user explicitly requests this parent-managed workflow. Use for manual worktree session creation and guarded recovery of this workflow's interrupted initialization, not ordinary isolation or worktree cleanup.
compatibility: Requires PowerShell 7+, Git, long-running shell execution, and app create_project/create_session tools.
---

# Manual Worktree Session

Create and verify the checkout before asking the app to create a session.
Native initialization can time out after 300 seconds on large repositories,
leaving a registered but incomplete worktree. A project or session ID does not
prove that Git finished checking out files.

This is an intentional exception to `using-git-worktrees`' native-first policy.
Do not retry native worktree creation for a repository already known to hit
that timeout. Do not create another worktree when the user asks to work in the
existing checkout.

## Prepare the parent

1. Capture the user's actual task verbatim, intended base commit, and child
   mode. Preserve explicit choices; otherwise use the source checkout's HEAD
   and `plan` mode. Do not infer permission to commit, push, or open a PR.
2. Select a new branch and nonexistent absolute worktree path **outside all
   existing checkouts**. Use an existing parent directory, preferably a sibling
   of the source checkout. Keep the state JSON in the parent's session artifact
   directory, outside checkouts. The helper refuses overlaps, reparse-point
   ancestors, existing targets, and submodule trees.
3. Resolve `scripts\Initialize-ManualWorktree.ps1` from this skill's installed
   root, not the user's repository. The helper requires PowerShell 7 and
   resolves Git's executable explicitly; it does not use cmd.exe or depend on
   cmd.exe's PATH lookup.

## Create and verify the worktree

Run through a long-running shell tool, with a generous initial wait:

```powershell
pwsh -NoProfile -File <absolute-helper-path> -Action Create `
  -RepoPath C:\repos\dotnet -WorktreePath C:\repos\dotnet-task `
  -Branch manual-task -StartPoint HEAD `
  -StatePath <absolute-session-artifacts-path>\manual-task.json
```

The helper pins the commit before creation and records recovery state before
running Git. It uses per-command long-path, filesystem-monitoring, sparse
checkout, submodule recursion, and hook overrides, never shared/global config
changes. It does not fetch, copy dirty source files, switch the source branch,
reset, force checkout, remove worktrees, or delete a failed checkout.
The empty `<StatePath>.lock` guard stays beside the state file; its existence
does not mean an operation is active. An exclusive file handle guards each run.

If the shell returns a running handle, retain it and wait for that same
operation. Read its output after completion. A tool wait expiring is not a Git
failure, and the helper has no 300-second cutoff. Do not launch another Create
or recovery while the original operation is still running.

Require exit success and JSON with `status: "ready"`. Then run:

```powershell
pwsh -NoProfile -File <absolute-helper-path> -Action Verify `
  -StatePath <absolute-session-artifacts-path>\manual-task.json
```

Require `ready` again. Verification checks repository/worktree registration,
branch and pinned HEAD, initialization locks, complete index tree, missing
tracked files, unexpected changes, and flags that could conceal edits.
Errors emit `status: "error"` with a message and terminate unsuccessfully.
Never treat partial output or a registered path alone as success.

## Register the existing checkout and delegate

Use app tools in this order; there is no established script API for them:

1. Call `create_project(path: <verified worktree_path>)`, not a clone URL.
   Registering this existing checkout is part of the user's requested workflow.
2. Call `create_session(project_id: <returned project ID>,
   workspace_type: "branch", kickoff: {prompt: <task>, mode: <selected mode>})`.
   **Omit `base_branch`.** Supplying it can trigger prepared-branch behavior.
   Do not use `workspace_type: "worktree"`; that repeats native initialization.
3. Inspect the child with `get_session`. Confirm its workspace is the exact
   worktree path and its branch matches the verified branch. If registration
   reused a project with a different checkout, or the child points elsewhere,
   stop delegation and report the mismatch rather than claim success. Direct
   the child not to edit while a mismatched session is being investigated.
4. Require child evidence that its cwd, branch, and HEAD match the verified
   checkout before it modifies files. Pass the expected path, branch, and
   commit in the kickoff prompt together with this instruction.

Keep the user's task as a separate verbatim quote in the kickoff. Add only
execution context, expected checkout identity, coordination instructions, and
the user's restrictions. Do not expand the requested scope.

If registration/session creation fails, keep the verified checkout and state.
Retry only the failed app step; do not recreate the worktree. Record project
and session IDs in parent session artifacts so subsequent attempts can inspect
and reuse them rather than duplicate sessions.

## Recover interrupted initialization conservatively

Recovery supports only an initialization recorded by this helper, in
`initializing` or `failed` phase. It deliberately does not adopt arbitrary
existing worktrees or previously ready worktrees. Native app failures without
such a record need a separate investigation, not a manufactured state file.

Before recovery, establish all three facts:

- This exact checkout is a failed initialization with no user/child work.
- Its session is stopped (or no session was created).
- No Git writer remains active. Wait on the retained shell handle or stop
  only the owned process tree with its tool handle; inspect uncertain process
  ownership rather than killing Git processes by name.

The switches below attest these facts; the helper cannot inspect app sessions
or prove that unrelated processes will not write. It takes an exclusive state
guard and refuses ambiguous checkout contents. Do not assert these switches
merely because an app timeout occurred.

```powershell
pwsh -NoProfile -File <absolute-helper-path> -Action Recover `
  -StatePath <absolute-session-artifacts-path>\manual-task.json `
  -FailedInitializationConfirmed -SessionStopped -NoActiveWriter
```

The helper checks surviving tracked files against a temporary HEAD index,
refuses unexpected files (including ignored files), staged changes other than
deletions, reparse-point or non-directory ancestors of missing files, other
administrative locks, and nonempty or held index locks. Checking parents both
before index reconstruction and immediately before restoration prevents a
directory junction from redirecting restored files outside the checkout. Only
an exclusive-openable, zero-byte stale `index.lock` can be removed.

It rebuilds the real index with `read-tree HEAD` **without modifying files**,
then pipes the raw bytes from `ls-files --deleted -z` to
`checkout-index --stdin -z --quiet`, without force. NUL-delimited binary
transfer preserves Unicode, whitespace, and special filename bytes. Existing
files are never intentionally overwritten. If an index is corrupt rather than
absent or readable, recovery refuses it.

Require `ready`, then repeat Verify and the app registration workflow. Refusals
leave files for investigation; never escalate to reset, clean, forced checkout,
index deletion, worktree removal, or global filesystem-monitor configuration.

## Handoff

Report the verified path, branch, pinned commit, child session link/ID, and
whether creation or guarded recovery was used. State any incomplete app step
plainly. Do not claim the user's delegated task is complete just because its
session started.

Focused deterministic tests in this repository:

```powershell
Invoke-Pester -Path tests\manual-worktree-session -Output Detailed
```
