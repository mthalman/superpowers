---
name: claude-extension-type-identifier
description: Use when determining what type of Claude Code extension (command, skill, or agent) a prompt or description should be classified as. This skill should be used when users ask "should this be a command, skill, or agent", when designing new extensions, or when there is ambiguity about the correct extension type for a given use case.
---

# Extension Type Identifier

## Overview

Correctly classify prompts and descriptions as commands, skills, or agents in Claude Code. Apply systematic criteria to determine the appropriate extension type, asking clarifying questions when needed to resolve ambiguities.

## When to Use This Skill

Use this skill when:
- User asks "Should this be a command, skill, or agent?"
- User describes functionality and needs guidance on extension type
- Designing new Claude Code extensions
- There is ambiguity about which extension type fits a use case

## Classification Process

Follow this workflow to determine the correct extension type:

### Step 1: Load Classification Criteria

Read `references/classification-criteria.md` to load the detailed characteristics, decision framework, and examples for each extension type.

### Step 2: Analyze the Description

Examine the user's description or prompt and identify:
- **Invocation pattern**: User-invoked vs model-invoked
- **Complexity**: Simple prompt vs complex workflow vs specialized expertise
- **Structure**: Single file vs directory with resources
- **Context needs**: Shared context vs independent context window
- **Tool access**: Inherit all tools vs restricted tools
- **Reusability**: One-off vs repeatable across projects

### Step 3: Apply Decision Framework

Use the decision tree from the classification criteria:

1. **Is this explicitly user-invoked?** → If yes, likely **Command**
2. **Does this need independent context/specialized expertise?** → If yes, likely **Agent**
3. **Is this a complex workflow that should auto-activate?** → If yes, likely **Skill**
4. **Is this a simple, frequent prompt?** → If yes, likely **Command**

### Step 4: Identify Ambiguities

If the classification is unclear, identify what additional information would help:
- How should this be triggered? (explicit vs automatic)
- How complex is the workflow? (steps, decision points)
- Does this need separate context? (to prevent pollution)
- Should tool access be restricted? (security, focus)
- How frequently used? (one-off vs repeated)

### Step 5: Ask Clarifying Questions

When ambiguous, use the AskUserQuestion tool to gather missing information:

**Question patterns:**
- "How should this functionality be invoked?" (Options: User types a command, Claude detects and activates automatically)
- "How complex is the workflow?" (Options: Simple one-step prompt, Multi-step process with guidance, Deep specialized expertise)
- "Should this operate in separate context?" (Options: Yes - needs isolation, No - can share main context)

**Example clarification:**

```
User: "Help me write git commit messages"

Ambiguity: Could be a command (explicit /commit) or skill (auto-activates when committing)

Ask: "How should this be triggered?"
- Option 1: "I type /commit when ready" → Command
- Option 2: "Claude detects when I need commits" → Skill
```

### Step 6: Provide Classification with Reasoning

Once determined, provide:
1. **Classification**: Command, Skill, or Agent
2. **Reasoning**: Explain why based on characteristics
3. **Key factors**: List 2-3 decisive criteria
4. **Alternative considerations**: Mention edge cases if relevant

**Output format:**

```
Classification: [Command/Skill/Agent]

Reasoning: [Explanation based on invocation, complexity, context, etc.]

Key factors:
- [Factor 1]
- [Factor 2]
- [Factor 3]

[Optional: Alternative considerations or edge cases]
```

## Edge Cases and Common Ambiguities

**Command vs Skill:**
- If it could work either way, prefer **Skill** for complex workflows, **Command** for simple prompts
- User preference matters: some teams prefer explicit commands, others prefer auto-activation

**Skill vs Agent:**
- Use **Agent** when deep expertise or context isolation is critical
- Use **Skill** when workflow guidance is needed but can share context

**Multiple classifications:**
- Some functionality could legitimately be multiple types (e.g., both command and skill versions)
- Consider team workflow preferences and existing patterns

## Quick Reference

| Type | Invocation | Complexity | Context | Structure |
|------|-----------|-----------|---------|-----------|
| **Command** | User types `/command` | Simple prompt | Shared | Single .md file |
| **Skill** | Claude auto-detects | Complex workflow | Shared | Directory with SKILL.md + resources |
| **Agent** | Delegated by Claude | Specialized expertise | Independent | .md with custom prompt + tools |

## Resources

### references/classification-criteria.md

Detailed documentation including:
- Comprehensive characteristics of each extension type
- Decision framework with examples
- Key differentiators between types
- Validated example classifications
- Edge cases and ambiguities
