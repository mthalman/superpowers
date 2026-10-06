---
name: claude-extension-type-identifier
description: Use when determining what type of Claude Code extension (command, skill, or agent) a prompt or description should be classified as. This skill should be used when users ask "should this be a command, skill, or agent", when designing new extensions, or when there is ambiguity about the correct extension type for a given use case.
---

# Extension Type Identifier

## Overview

Correctly classify prompts and descriptions as commands, skills, or agents in Claude Code. Apply systematic criteria and ask clarifying questions when needed.

## When to Use This Skill

Use this skill when:

- User asks "Should this be a command, skill, or agent?"
- User describes functionality and needs guidance on extension type
- Designing new Claude Code extensions
- There is ambiguity about which extension type fits a use case

## Core Distinctions

| Type | Invocation | Complexity | Context | Structure | Best for |
|------|------------|------------|---------|-----------|----------|
| **Command** | User types `/command` | Simple prompt | Shared | Single `.md` file | Quick, explicit, frequently-used prompts |
| **Skill** | Claude auto-detects | Complex workflow | Shared | Directory with `SKILL.md` plus resources | Methodologies, multi-step guidance, bundled references/scripts |
| **Agent** | Claude delegates | Specialized expertise | Independent | `.md` with custom prompt and tool config | Focused expert analysis that can run separately |

Choose **Command** when explicit user control and a single prompt are enough. Choose **Skill** when Claude should auto-activate a workflow that shares the main context. Choose **Agent** when the work can be delegated to an independent specialist and returned as results.

## Compact Delegatability Rule

For Skill versus Agent, ask: **Can Claude complete this independently and return results?**

- If yes, choose **Agent** when independent context or specialist focus helps.
- If no, choose **Skill** because the work requires ongoing collaboration in the main conversation.

Expertise depth alone does not make something an Agent. TDD and architecture decision support can be complex, but they remain Skills when the human must participate throughout. Security audits and code reviews are Agents when Claude can analyze independently and return findings.

## Classification Process

### Step 1: Load Detailed Criteria

Open `references/classification-criteria.md` when you need edge cases, detailed decision trees, validated examples, clarifying-question patterns, or full implementation guidance.

### Step 2: Analyze the Description

Identify:

- **Invocation pattern:** user-invoked, auto-detected, or delegated
- **Complexity:** simple prompt, structured workflow, or specialized expertise
- **Structure:** single file, resource directory, or configured agent prompt
- **Context needs:** shared context or independent context window
- **Tool access:** inherit all tools or restrict tools for focus/safety
- **Reusability:** one-off, repeated project pattern, or reusable specialist

### Step 3: Apply the Decision Framework

1. Is this explicitly user-invoked with `/command`? If yes, likely **Command**.
2. Does this need independent context or specialized expertise, and can the work be delegated? If yes, likely **Agent**.
3. Is this a complex workflow that should auto-activate? If yes, likely **Skill**.
4. Is this a simple, frequent prompt? If yes, likely **Command**.

### Step 4: Validate Against Existing Implementations

Search for similar commands, skills, or agents. Existing implementations reveal practical constraints and team patterns. If your theoretical classification contradicts an existing pattern, either revise the classification or explain why this case differs.

Example: systematic debugging may sound agent-like because it uses deep expertise, but it is a Skill in this repository because debugging requires ongoing collaboration through hypotheses, evidence, and fixes.

### Step 5: Resolve Ambiguity

If unclear, ask or infer the missing decision facts:

- Should the user explicitly invoke it, or should Claude detect it?
- Is it a simple prompt, a multi-step workflow, or deep specialist analysis?
- Does it need isolated context?
- Should tools be restricted?
- How often will the user repeat it?

Prefer a clarifying question when the classification depends on user workflow preference. If autonomy is required, state your assumption and proceed.

### Step 6: Provide Classification with Reasoning

Return the classification, reasoning, decisive factors, trade-offs if multiple options are valid, and concrete implementation guidance.

## Output Contract

```text
Classification: [Command/Skill/Agent, or Hybrid]

Reasoning: [Short explanation based on invocation, complexity, context, structure, and delegatability]

Key factors:
- [Decisive factor 1]
- [Decisive factor 2]
- [Decisive factor 3]

[Optional] Trade-offs:
| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| ... | ... | ... | ... |

Implementation guidance:
- Command: suggested name, usage pattern, storage location
- Skill: trigger patterns, workflow shape, needed resources
- Agent: delegation pattern, tool restrictions, result format
```

## Non-Negotiable Rules

- Do not classify by complexity alone.
- Do not ignore invocation pattern.
- Do not treat restricted tool access as the type determinant.
- Do not choose Agent unless the work can be delegated and returned as results.
- Validate against existing implementations before finalizing when comparable examples exist.
- If multiple classifications are valid, present trade-offs rather than forcing a false single answer.
