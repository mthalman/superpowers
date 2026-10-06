# Manual Worktree Fallback

This reference covers the manual Git fallback path when no native worktree tool
exists.

## Native Tool Preference

Do you already have a way to create a worktree? It might be a tool with a name
like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree`
flag.

Native tools handle directory placement, branch creation, and cleanup
automatically. Using `git worktree add` when you have a native tool creates
phantom state your harness can't see or manage.

Only proceed to the manual Git fallback if you have no native worktree tool
available.

## Directory Priority

Explicit user preference always beats observed filesystem state.

Check your instructions for a declared worktree directory preference. If the
user has already specified one, use it without asking.

Check for an existing project-local worktree directory. Prefer `.worktrees`;
otherwise use `worktrees`.

If there is no other guidance available, default to `.worktrees/` at the project
root.

## Safety Verification for Project-Local Directories

Must verify directory is ignored before creating worktree:

```bash
git check-ignore -q "$LOCATION/"
```

Run the check for the selected directory only. The trailing separator tests
directory rules even before the directory exists.

If not ignored: ask before changing `.gitignore`. If the user approves, add the
selected directory rule. Do not commit that change without separate commit
approval.

If the user declines the `.gitignore` change, ask whether to use an external
worktree path or continue in the current workspace.

Do not create an unignored project-local worktree. If the host cannot ask
interactively, do not change `.gitignore` or create the project-local worktree.

Why critical: prevents accidentally committing worktree contents to repository.

## Manual Creation

Create the path under the selected location, then run:

```bash
git worktree add <path> -b <branch-name>
```

Move the working directory to the new worktree.

Sandbox fallback: if `git worktree add` fails with a permission error (sandbox
denial), tell the user the sandbox blocked worktree creation and you're working
in the current directory instead.

## Common Mistakes

| Problem | Fix |
|---|---|
| Using `git worktree add` when the platform already provides isolation | Use the native tool. This is the #1 mistake; if you have it, use it. |
| Creating a nested worktree inside an existing one | Always run Step 0 before creating anything. |
| Worktree contents get tracked and pollute `git status` | Always use `git check-ignore` before creating a project-local worktree. |
| Creating inconsistency or violating project conventions | Follow explicit instructions, then existing project-local directory, then default. |
| Can't distinguish new bugs from pre-existing issues | Report baseline failures and get explicit permission to proceed. |
