---
name: prompt-engineering
description: Use when crafting prompts for AI models, reviewing existing prompts for quality, or designing system prompts for agents and tools - provides expert guidance on structure, clarity, common patterns, and model-specific optimizations to create effective, token-efficient prompts
---

# Prompt Engineering

## Overview

**Effective prompts are specific, well-structured, and match task complexity to response needs.**

This skill provides expert knowledge for:
- Creating new prompts from scratch
- Reviewing and optimizing existing prompts
- Designing system prompts for AI agents and tools

**Core principle:** Specificity beats generality. Structure aids parsing. Examples clarify intent.

## When to Use This Skill

Use when:
- Crafting prompts for AI models or agents
- Reviewing prompts that give inconsistent results
- Designing system prompts for tools, agents, or extensions
- Optimizing prompts for token efficiency
- Need model-specific guidance (Claude, GPT-4, etc.)

Don't use for:
- General AI/ML questions unrelated to prompting
- Training or fine-tuning models
- Non-prompt writing tasks

## Core Principles

1. **Specificity beats generality** - "Analyze code" → "Identify security vulnerabilities in authentication code"
2. **Examples clarify intent** - Show what good output looks like
3. **Constraints enable focus** - Define boundaries, format, scope
4. **Structure aids parsing** - Use delimiters, headings, XML tags
5. **Token efficiency through precision** - Remove filler, use structured outputs
6. **Context placement matters** - Critical info near the instruction
7. **Output format specification is mandatory** - JSON schema, markdown template, bullet format

## Structural Elements

### Delimiters and Organization

**XML tags** (especially effective with Claude):
```
<instructions>
Task description here
</instructions>

<examples>
Example 1: input → output
Example 2: input → output
</examples>

<context>
Background information
</context>
```

**Markdown structure** (universal):
```
# Main Task
Brief overview

## Requirements
- Requirement 1
- Requirement 2

## Output Format
Specify exact structure here

## Examples
Show 1-2 examples
```

**Hierarchical organization:**
```
Overview (what you're asking)
  ↓
Details (specifics, constraints)
  ↓
Examples (desired output)
  ↓
Context (background info if needed)
```

### Output Format Specification

**ALWAYS specify output format.** This is the most common gap in weak prompts.

**Bad:**
```
"Review this code and tell me what's wrong"
```

**Good:**
```
"Review this code. Output format:
- Issue description
- Severity (Critical/High/Medium/Low)
- Line number
- Suggested fix"
```

**Even better with structure:**
```json
{
  "issues": [
    {
      "description": "string",
      "severity": "Critical|High|Medium|Low",
      "line": number,
      "fix": "string"
    }
  ]
}
```

## Clarity Techniques

### 1. Be Explicit About Assumptions
```
❌ "Analyze this function"
✅ "Analyze this Python function. Assume Python 3.10+. Focus on type safety and error handling."
```

### 2. Define Ambiguous Terms
```
❌ "Write clean code"
✅ "Write code following: single responsibility per function, descriptive names, <100 lines per function"
```

### 3. Specify Edge Cases
```
❌ "Parse this input"
✅ "Parse this input. If empty: return {}. If malformed: return error with specific line. If valid: return parsed object."
```

### 4. Use Positive Framing
```
❌ "Don't forget error handling"
✅ "Include error handling for: network failures, invalid input, timeout"
```

### 5. Quantify Vague Requirements
```
❌ "Brief summary"
✅ "Summary in 2-3 sentences, max 50 words"

❌ "Several examples"
✅ "3-5 examples showing common cases"
```

### 6. Separate Instructions from Context
```
<instructions>
Extract all IP references from the document below.
</instructions>

<context>
Legal documents typically reference IP in sections about licensing, warranties, and indemnification...
</context>

<document>
[Document here]
</document>
```

## Common Patterns

| Pattern | When to Use | Structure |
|---------|-------------|-----------|
| **Chain-of-thought** | Complex reasoning | "Think step-by-step: 1) Analyze X, 2) Consider Y, 3) Conclude Z" |
| **Few-shot learning** | Demonstrating format | "Example 1: input → output\nExample 2: input → output\nNow: [new input]" |
| **Role-based prompting** | Need specific expertise | "You are a [expert role] with expertise in [domain]..." |
| **Constrained generation** | Specific format required | "Output must be valid JSON matching: {schema}" |
| **Decomposition** | Multi-step tasks | "First X, then Y, finally Z. Show work for each step." |
| **Self-critique** | Quality checking | "Generate answer, review for [criteria], provide final version" |

### Pattern Examples

**Chain-of-thought:**
```
❌ Without: "Is this function optimized?"

✅ With: "Analyze this function step-by-step:
1. Identify time complexity
2. Find performance bottlenecks
3. Suggest specific optimizations
4. Estimate improvement impact"
```

**Few-shot learning:**
```
"Extract action items from meeting notes.

Example 1:
Input: 'John will send the report by Friday. Sarah needs to review before Monday.'
Output:
- [ ] John: Send report (Due: Friday)
- [ ] Sarah: Review report (Due: Monday)

Example 2:
Input: 'Team agreed to refactor auth module. Mike volunteered.'
Output:
- [ ] Mike: Refactor auth module (Due: Not specified)

Now extract from: [your text here]"
```

**Role-based:**
```
"You are a security engineer specializing in web application security with 10+ years experience in OWASP Top 10 vulnerabilities.

Review the authentication code below for security issues..."
```

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

## Token Efficiency

**Principle:** Precision reduces tokens more than brevity.

### Remove Filler
```
❌ "I would like you to please review the code and let me know what you think..." (17 words)
✅ "Review this code for security issues." (6 words)
```

### Use Structure
```
❌ Prose explanation (200 tokens)
✅ JSON object (50 tokens)

❌ "The function should accept a string parameter called name and return..."
✅
Parameters:
- name: string

Returns: string
```

### Leverage Examples Over Explanation
```
❌ "The output should be formatted as a JSON object with a 'summary' field containing
a brief description, an 'issues' array with objects that have 'description' and 'severity'
fields..." (30 words)

✅ "Output format:
{
  "summary": "brief description",
  "issues": [{"description": "...", "severity": "High"}]
}" (15 words + example)
```

### Avoid Redundancy
```
❌ "Check for bugs, errors, issues, or problems in the code"
✅ "Check for bugs and logical errors"
```

## Review Checklist

When reviewing prompts, check:

- [ ] **Clear task definition** - Can you restate what's being asked?
- [ ] **Specific success criteria** - What makes a good response?
- [ ] **Necessary context provided** - All required information present?
- [ ] **Output format specified** - Structure, length, style defined?
- [ ] **Edge cases addressed** - Empty/invalid/unusual inputs handled?
- [ ] **Examples included** - Demonstrated desired output (if complex)?
- [ ] **Ambiguity removed** - No terms with multiple meanings?
- [ ] **Constraints stated** - Boundaries, limitations, requirements clear?
- [ ] **Token efficiency** - No filler words or redundancy?
- [ ] **Proper structure** - Sections, delimiters, hierarchy used?
- [ ] **Model selection considered** - Right model for task?

## Common Mistakes

| Mistake | Why It's Bad | Fix |
|---------|--------------|-----|
| **Vague verbs** ("improve", "optimize") | Unclear what to optimize for | "Reduce time complexity from O(n²) to O(n log n)" |
| **Assumed context** | Model doesn't know your codebase | Provide relevant context explicitly |
| **Multiple tasks** | Dilutes focus, harder to evaluate | One clear task per prompt |
| **No output format** | Gets variable/unexpected responses | Specify JSON, markdown, bullets, etc. |
| **Overly verbose** | Wastes tokens, buries key info | Remove filler, use structure |
| **Missing examples** | Ambiguous intent | Show 1-2 examples of desired output |
| **Negative instructions** | Less effective than positive | "Do Y instead of don't do X" |
| **Undefined scope** | Endless or mismatched responses | Set clear boundaries |
| **Generic role** | Lack of expertise framing | "Security expert" not just "helpful assistant" |
| **Skipping edge cases** | Breaks on unusual input | "If empty, return X. If invalid, return Y." |

## Model-Specific Considerations

**Universal principles above apply to all models.** Different models have specific quirks and optimizations.

**See `model-notes.md` for detailed guidance on:**
- Claude (Sonnet/Opus/Haiku) - XML tags, thinking tokens, context handling
- GPT-4/GPT-3.5 - System messages, function calling
- Gemini - Multimodal prompting, context caching
- Open source models - Template formats, capability limits

**Quick model selection guide:**

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| Long document analysis (100K+ tokens) | Claude Opus/Sonnet | 200K context window |
| Code generation | GPT-4, Claude Sonnet | Strong code capabilities |
| Quick simple tasks | Claude Haiku, GPT-3.5 | Cost-effective, fast |
| Multimodal (text + images) | Gemini, GPT-4 Vision | Native multimodal support |
| Structured output | GPT-4 (function calling), Claude | Strong structure following |
| Complex reasoning | Claude Opus, GPT-4 | Superior reasoning capabilities |

## Quick Reference

**When crafting any prompt, ask yourself:**

1. ❓ What exactly am I asking for? (Specific task)
2. ❓ What does good output look like? (Examples)
3. ❓ What format should the output be? (Structure)
4. ❓ What constraints apply? (Boundaries)
5. ❓ What context is needed? (Background info)
6. ❓ What edge cases exist? (Error handling)
7. ❓ Which model fits this task? (Model selection)

**Template for quick prompts:**
```
[Role]: You are a [expert type]

[Task]: [Specific action on specific target]

[Constraints]:
- [Constraint 1]
- [Constraint 2]

[Output Format]:
[Exact structure specification]

[Example]:
Input: [example input]
Output: [example output]
```

## Red Flags - Stop and Revise

If your prompt has ANY of these, revise before using:

- "Analyze this" without specifying what to analyze for
- "Make it better" without defining "better"
- No output format specified
- Vague words: "important", "relevant", "appropriate", "good"
- Multiple unrelated tasks in one prompt
- No examples for complex/novel tasks
- Assumed knowledge about your specific context
- Generic role ("helpful assistant") for specialized tasks
- No edge case handling
- Overly polite filler ("I would appreciate if you could please...")

## The Bottom Line

**Effective prompts have three elements:**

1. **Specificity** - Exactly what you want, not vague requests
2. **Structure** - Clear organization and output format
3. **Examples** - Show desired output for complex tasks

**Start with these questions:**
- What exactly do I want?
- What does good output look like?
- What format should it be in?

**Then add:**
- Constraints and boundaries
- Edge case handling
- Context if needed

**Finally, remove:**
- Filler and redundancy
- Vague terms
- Unnecessary politeness

The goal: Minimal tokens for maximum clarity.
