---
name: code-commenting
description: Use proactively whenever writing or auditing inline code comments, doc comments, or docstrings. Explains why over what, preserves non-obvious contracts and rationale, removes narration and stale comments, evaluates suppressions, and prefers types, tests, naming, or structure when they can encode a constraint more reliably. Use technical-writing, not this skill, for standalone READMEs, guides, API pages, or other documentation.
---

# Code Commenting

## Overview

Enforce effective code commenting principles and provide a systematic workflow for documenting code. This skill ensures comments explain reasoning and non-obvious behavior while avoiding redundancy and outdated documentation.

## When to Use This Skill

Use this skill:
- **Proactively** whenever writing a comment in code
- When the user asks to add or review inline comments, doc comments, or
  docstrings in code
- When adding comments to existing uncommented code

Use `technical-writing` for standalone documentation such as README files,
guides, RFCs, and API pages.

## Core Principles

Apply these principles to **every** comment written:

### 1. Explain "Why" Over "What"

Explain reasoning, decisions, trade-offs, and context. The code already shows *what* it does.

**Examples:**
```javascript
// Bad: Loop through users
for (const user of users) { ... }

// Good: Process users sequentially to avoid overwhelming the email API rate limit
for (const user of users) { ... }
```

### 2. Document Non-Obvious Behavior

Document edge cases, gotchas, performance implications, and side effects. Explain surprising behavior that isn't immediately clear from the code.

**Examples:**
```python
# Bad: Calculate total
total = sum(items)

# Good: Sum excludes canceled items - they're already refunded
total = sum(item.price for item in items if item.status != 'canceled')
```

```typescript
// Returns null when market is closed (weekends, holidays)
// Callers must handle null before dereferencing the result
function getCurrentPrice(): number | null { ... }
```

### 3. Avoid Redundant Comments

Never write comments that just restate the code in English. If the code is self-explanatory, no comment is needed.

**Examples:**
```java
// Bad: Increment counter by 1
counter++;

// Good: No comment needed - code is self-explanatory
counter++;
```

### 4. Keep Comments Fresh

Comments must stay synchronized with code. Outdated comments are worse than no comments. When editing code, update or remove affected comments immediately.

## The Workflow

Follow this process for any commenting task:

### 1. Understand the Code

Read and analyze what needs documentation.

### 2. Identify What Needs Comments

Find areas where principles apply:
- Where is the "why" missing?
- What behavior is non-obvious?
- What gotchas or edge cases exist?

### 3. Write Comments

Apply principles to each area:
- Explain "why" over "what"
- Document non-obvious behavior
- Avoid redundant comments
- Keep comments fresh

### 4. Validate

Check each comment against principles before moving on.

## Comment Audit Mode

Use this mode when the user asks to review, remove, clean up, or reduce
comments. Stay within the requested files or diff.

Classify each material comment:

| Classification | Meaning |
|---|---|
| `KEEP` | Preserves information code cannot express reliably |
| `DELETE` | Narration, decoration, dead code, stale text, or redundant type information |
| `REWRITE` | Important information expressed inaccurately or excessively |
| `ENCODE` | A type, test, assertion, lint rule, name, or API can enforce the claim |
| `INVESTIGATE` | The comment may encode a real constraint, but evidence is missing |

### Keep

Preserve:

- legal and license headers;
- public API contracts;
- externally imposed platform, protocol, or compatibility behavior;
- concise rationale for non-obvious algorithms, concurrency, performance, or
  safety decisions;
- issue or decision-record links that preserve relevant history;
- tool suppressions whose necessity has been verified.

### Delete

Remove:

- comments that restate the next line;
- decorative banners that add no navigation value;
- commented-out code recoverable from source control;
- stale descriptions and obsolete warnings;
- TODOs already completed or no longer actionable;
- long workaround defenses after the workaround is gone.

### Encode or refactor

Prefer an enforceable mechanism when it communicates the constraint better:

- a type instead of a nullable-value warning;
- a regression test instead of "do not change this";
- an assertion instead of an undocumented precondition;
- a descriptive symbol instead of a narration comment;
- a lint rule instead of a repeated style warning.

Recommend application-code changes separately. Do not expand a comment-only
request into refactoring without user approval.

### Investigate uncertainty

Read nearby code, history, tests, dependency documentation, and callers before
deleting a possible constraint. If the evidence remains incomplete, preserve
the comment and report what must be verified. Uncertainty is not evidence that
the comment is safe to delete.

### Review suppressions

For `eslint-disable`, `@ts-ignore`, analyzer suppressions, and similar comments:

1. Identify the exact rule.
2. Determine whether it protects correctness, safety, compatibility, generated
   code, or only style.
3. Verify whether the underlying issue can be fixed in scope.
4. Keep, narrow, replace, or remove the suppression based on that evidence.

Do not treat every suppression as either harmless or defective.

### Audit output

Report counts by classification, then list every non-`KEEP` item with its
location, classification, rationale, and evidence. Apply deletions or rewrites
only when the user asked for edits.

## When NOT to Comment

**Don't add comments when:**

### The Code is Self-Documenting

```javascript
// Bad: Get user by ID
function getUserById(id) { ... }

// Good: No comment needed - function name is clear
function getUserById(id) { ... }
```

### The Code Could Be Improved Instead

```javascript
// Bad: Loop counter
for (let i = 0; i < x.length; i++) { ... }

// Good: No comment, better variable name
for (let userIndex = 0; userIndex < users.length; userIndex++) { ... }
```

### The Comment Would Repeat Type Information

```typescript
// Bad: The user's email address
email: string;

// Good: No comment needed - type and name are clear
email: string;
```

**Prefer:** Clear code over comments. Only add comments when code alone cannot express the intent, reasoning, or non-obvious behavior.
