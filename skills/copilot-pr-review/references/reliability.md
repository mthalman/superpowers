# Reliability

Use this reference for merge conflicts, polling, context budget, and unresolved-thread checks during Copilot PR review.

## Merge Conflict Resolution

If merge conflicts arise during this workflow:

1. Fetch and rebase: `git fetch origin && git rebase origin/<target-branch>`
2. Resolve conflicts
3. Force-push: `git push --force-with-lease`
4. Re-request review (Step 5)

## Reliability Notes

- **Context budget**: The Copilot review loop is context-intensive. If you've already done Phase 1 (local review) in this same agent context, be aware you have limited context remaining. Focus on the mechanical steps: read comment → fix → commit → reply → resolve. Do not re-investigate or re-analyze the broader PR — stay focused on what each comment asks for.
- **One round at a time**: Process one complete round (all comments from a single review) before re-requesting. Never batch re-requests. Never re-request review while there are still unprocessed comments from the current review.
- **Verify before re-requesting**: After resolving all threads, verify with `gh api graphql` that no unresolved threads remain before re-requesting review:
  ```bash
  UNRESOLVED=$(gh api graphql -f query='{ repository(owner: "{owner}", name: "{repo}") { pullRequest(number: {pr_number}) { reviewThreads(first: 100) { nodes { isResolved } } } } }' \
    --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length')
  echo "Unresolved threads: $UNRESOLVED"
  ```
  If `UNRESOLVED` > 0, go back and resolve them before proceeding to Step 5.
