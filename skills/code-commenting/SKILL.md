---
name: code-commenting
description: Use proactively whenever writing code comments, or when user requests code documentation. Enforces effective commenting principles (explain "why" over "what", document non-obvious behavior, avoid redundancy, keep comments fresh) and provides systematic workflow for documenting existing code.
---

# Code Commenting

## Overview

Enforce effective code commenting principles and provide a systematic workflow for documenting code. This skill ensures comments explain reasoning and non-obvious behavior while avoiding redundancy and outdated documentation.

## When to Use This Skill

Use this skill:
- **Proactively** whenever writing a comment in code
- When user asks to "document this code/file/function"
- When adding comments to existing uncommented code

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
// Callers must handle null or risk NullPointerException
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
