# Worktree Audit

This reference covers the conservative read-only worktree audit mode and bucket meanings.

When the user asks which worktrees are active, abandoned, or safe to inspect for
removal, run the bundled read-only audit.

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

When size collection is requested, `SizeComplete` reports whether every file was
readable. Do not treat an incomplete size as exact.

The script does not delete worktrees. Treat `safe-merged` as a recommendation to
inspect, not permission to remove. Require explicit approval before any cleanup.

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
