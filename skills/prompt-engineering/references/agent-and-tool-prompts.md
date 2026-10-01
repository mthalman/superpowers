# Agent and Tool Prompts

Guidance for system prompts, tool descriptions, agent context management, and recovery gates.

## Agent-Specific Guidance

### System Prompts for Agents

**Key elements:**
1. **Identity & capabilities** - What the agent is and can do
2. **Boundaries** - What it should/shouldn't do
3. **Behavioral guidelines** - Tone, style, decision-making
4. **Tool integration** - How to use available tools
5. **Error handling** - What to do when stuck

**Example structure:**
```
# [Agent Name] System Prompt

You are a [role] that [primary purpose]. Your capabilities include [list].

## Core Responsibilities
1. [Responsibility 1]
2. [Responsibility 2]

## Decision-Making Framework
When faced with [situation], you should [approach].

## Tool Usage
- [Tool 1]: Use when [trigger condition]
- [Tool 2]: Use when [trigger condition]

## Error Handling
If [error type], then [recovery approach].

## Output Format
Always structure responses as:
[Format specification]
```

### Tool Descriptions

**Effective tool descriptions need:**

```
tool-name: Brief one-line summary

Use when: [Specific trigger conditions - when this tool applies]

Parameters:
- param1 (required): type, format, constraints
- param2 (optional): type, default value

Returns: [What the tool outputs]

Examples:
- [Common use case 1]
- [Common use case 2]

When NOT to use:
- [Alternative tool for different case]
- [What this tool doesn't do]
```

**Bad tool description:**
```
search-code: searches for code
```

**Good tool description:**
```
search-code: Find functions, classes, or patterns in codebase using regex

Use when:
- Finding where a function is defined
- Locating all uses of a specific API
- Identifying code patterns across files

Parameters:
- pattern (required): regex pattern to match
- file_type (optional): filter by extension (js, py, etc.)
- context_lines (optional): lines before/after match (default: 0)

Returns: List of matches with file path, line number, and context

When NOT to use:
- Reading entire files (use read-file)
- Broad exploration (use explore-codebase)
```

### Context Management for Agents

**Problem:** Agents deal with limited context windows and need to manage information flow.

**Techniques:**

**1. Compression - Extract structured data:**
```
❌ Pass forward: "The codebase uses Express with PostgreSQL. Authentication is handled
by passport.js. There are 47 routes spread across 8 files. The database has 12 tables..."

✅ Extract structure:
{
  "framework": "Express",
  "database": "PostgreSQL",
  "auth": "passport.js",
  "routes": {"count": 47, "files": 8},
  "db_tables": 12
}
```

**2. Reference strategies:**
```
❌ "The User model at src/models/User.js line 15-47 has fields: id, name, email, password, created_at..."

✅ "User model: src/models/User.js:15-47 (5 fields: id, name, email, password, created_at)"
```

**3. State tracking:**
```
What to persist:
- Decisions made
- Validations passed
- Errors encountered
- Files modified

What to discard:
- Exploration paths not taken
- Detailed logs from successful operations
- Redundant context
```

### Agent Communication Patterns

**Validation gates:**
```
After [step], check:
✓ [Criterion 1] - if fail: [recovery]
✓ [Criterion 2] - if fail: [recovery]
✓ [Criterion 3] - if fail: [recovery]

If all pass → Proceed to [next step]
```

**Error recovery:**
```
If [error type]:
1. Log error details
2. Attempt [recovery approach]
3. If recovery fails: [fallback]
4. Report to user: [what information]
```

**Human checkpoints:**
```
Pause for human decision when:
- Multiple valid approaches with tradeoffs
- Architectural decisions
- Scope clarification needed
- Risk acceptance required

Format:
"I've identified [N] approaches:
A) [Approach] - Pros: [X], Cons: [Y]
B) [Approach] - Pros: [X], Cons: [Y]

Which fits your needs?"
```
