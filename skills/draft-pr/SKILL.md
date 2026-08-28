---
name: draft-pr
description: Draft a ready-to-paste pull request title and description from repository changes, commits, linked issue or work-item context, and the target GitHub repository's PR template when one exists. Use when the user asks to draft, write, improve, or regenerate a PR title, PR description or body, pull request summary, or change description, including a PR that fixes a linked issue or work item. For bug fixes, captures the observed error or behavior, root cause, and fix. Use this instead of technical-writing for PR-specific drafts. Do not use it to create, update, or post a pull request.
---

# Drafting Pull Requests

Produce a factual, reviewer-oriented PR title and description without creating or
updating a pull request.

## Workflow

### 1. Establish the change scope

Inspect the available evidence before drafting:

1. Read the user's explanation and any referenced issue or work-item URL.
2. Inspect the diff against the intended base branch, including staged and
   unstaged changes when they are part of the requested PR.
3. Read the relevant commit messages and tests when they clarify intent,
   behavior, or validation.
4. Consult linked issue or work-item details when authorized tools and access are
   available.
5. Determine the target repository and hosting provider.

Separate facts supported by the change from assumptions. Ask one focused
question at a time when a material detail, such as the root cause or intended
issue relationship, cannot be established from the available evidence.

### 2. Select the description structure

When the target is a GitHub repository, inspect its default branch for:

- `pull_request_template.md` in the repository root, `docs/`, or `.github/`;
- Markdown files in `PULL_REQUEST_TEMPLATE/` under the repository root,
  `docs/`, or `.github/`.

Use authorized GitHub tools when the target repository is not available
locally. Do not silently fall back to the generic format when access prevents
checking whether a GitHub template exists; explain the limitation and ask the
user to provide the template.

Use a single default template when one exists. When multiple templates exist,
prefer a template explicitly named by the user or selected in a GitHub URL's
`template` query parameter. Otherwise, select one only when its file name and
instructions clearly match the change type. Ask the user to choose when more
than one template remains relevant.

Copy the complete selected template as the starting description, then populate
its answer fields. Do not reconstruct it from its headings or delete its HTML
comments: preserve the headings, section order, instructions, comments,
checklists, and required fields exactly. Fill every applicable section from the
available evidence. Do not check an attestation unless the evidence proves it
is true. Ask for missing information when the template marks it as required;
write `N/A` only when the section genuinely does not apply and the template
does not prescribe another response.

If the target is not GitHub, or no GitHub PR template exists, use the generic
format in step 5.

### 3. Classify the change

Treat the PR as a bug fix when it corrects an error, regression, or behavior that
violates an existing expectation. A bug-fix draft needs to explain:

- the error or observed behavior and the expected behavior;
- the root cause, at the level necessary to understand why the behavior
  occurred;
- the fix and why it addresses that root cause.

For features, maintenance, refactoring, and documentation changes, explain the
problem or need and then describe the implemented change.

Do not claim a root cause merely because the changed code suggests one. If the
evidence establishes only a hypothesis, ask for confirmation before presenting
it as the root cause.

### 4. Write the title

Write one concise, imperative title that describes the user-visible or
engineering outcome. Prefer the purpose of the change over low-level
implementation details. Omit a trailing period.

### 5. Write the description

Keep each section proportional to the change and omit process narration and
claims not supported by evidence.

When using a repository template, place the required content in its closest
matching sections:

- state the problem or need in the template's problem, motivation, context, or
  equivalent section;
- for a bug fix, identify the error or behavior and root cause in that section;
- describe the change, including the fix for a bug, in the template's change,
  solution, description, or equivalent section.

Use explicit `**Error or behavior:**`, `**Root cause:**`, and `**Fix:**` labels
when the repository template does not otherwise make those facts
unambiguous. Add a minimal `## Problem` or `## Description` section only when
the template has no suitable place for required content.

Without a repository template, use this format for a bug fix:

```markdown
## Problem

**Error or behavior:** <What happened and what should have happened instead.>

**Root cause:** <Why the incorrect behavior occurred.>

## Description

**Fix:** <What changed and why it corrects the root cause.>
```

Without a repository template, use this format for any other change:

```markdown
## Problem

<The limitation, need, or opportunity that motivated the change.>

## Description

<What changed and how it addresses the problem.>
```

When the user identifies an issue or work item as context for the PR, place this
trailer in the template's issue-linking section or append it to the description
when no such section exists:

```markdown
Fixes <issue-or-work-item-URL>
```

Preserve the complete URL rather than shortening it to an issue number. Put each
additional URL on its own `Fixes <URL>` line. A reference found only in branch
history or a commit message may be incidental; confirm that relationship rather
than claiming the PR fixes it.

### 6. Return the draft

Return only the draft in this form:

```markdown
**Title**

<PR title>

**Description**

<PR description>
```

Do not create, update, post, or push the pull request. The user asked for a
draft, so remote side effects would be surprising.
