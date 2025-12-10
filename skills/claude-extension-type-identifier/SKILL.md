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
2. **Does this need independent context/specialized expertise AND can be delegated?** → If yes, likely **Agent**
   - **Delegatability test:** Can Claude complete this independently and return results? Or does it require ongoing human collaboration?
3. **Is this a complex workflow that should auto-activate?** → If yes, likely **Skill**
4. **Is this a simple, frequent prompt?** → If yes, likely **Command**

### Step 4: Validate Against Existing Implementations

Before finalizing your classification, check if similar functionality already exists:

**How to validate:**
1. Search the codebase for existing commands, skills, or agents with similar purposes
2. Examine how they're implemented (Command, Skill, or Agent)
3. If your classification differs from existing patterns, reconsider your reasoning

**Why this matters:**
- Real implementations reveal practical constraints theory might miss
- Existing patterns show what works in practice
- Inconsistency might indicate a misunderstanding

**Example:**
- Theory: "Systematic debugging needs deep expertise → Agent"
- Reality check: `systematic-debugging` exists as a Skill in this codebase
- Reconsider: Why is it a Skill? Because debugging requires ongoing collaboration - developer and Claude work together through hypothesis testing

**Red flag:** Your theoretical classification contradicts existing implementation without clear justification

**If no similar functionality exists:** Proceed with your classification, but note this is a new pattern

### Step 5: Identify Ambiguities

If the classification is unclear, identify what additional information would help:
- How should this be triggered? (explicit vs automatic)
- How complex is the workflow? (steps, decision points)
- Does this need separate context? (to prevent pollution)
- Should tool access be restricted? (security, focus)
- How frequently used? (one-off vs repeated)

### Step 6: Ask Clarifying Questions

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

### Step 7: Provide Classification with Reasoning

Once determined, provide:
1. **Classification**: Command, Skill, or Agent (or multiple if applicable)
2. **Reasoning**: Explain why based on characteristics
3. **Key factors**: List 2-3 decisive criteria
4. **Trade-offs** (when multiple options exist): Systematically present pros/cons
5. **Alternative considerations**: Mention edge cases if relevant
6. **Implementation guidance**: Concrete suggestions for how to build it

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

**When multiple valid options exist, add trade-offs:**

```
Trade-offs:

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| [Option 1] | [Benefits] | [Costs] | [Context where appropriate] |
| [Option 2] | [Benefits] | [Costs] | [Context where appropriate] |
| [Option 3] | [Benefits] | [Costs] | [Context where appropriate] |
```

**Include implementation guidance:**

For **Commands:**
- Suggested command name (e.g., `/commit`, `/review`)
- Example usage pattern
- Storage location (.claude/commands/ vs ~/.claude/commands/)

For **Skills:**
- Trigger patterns (what should activate it)
- Behavioral mode (light-touch vs structured workflow)
- Resource needs (templates, references, scripts)

For **Agents:**
- Delegation pattern (when Claude should invoke it)
- Tool restrictions (if any)
- Result format (what it returns)

For **Hybrid (Skill + Command):**
```
skill: [name]-guidance (auto-activates)
├── Triggers: [specific patterns]
├── Behavior: [what it does]
└── References: [/command] for explicit mode

command: [name] (explicit invocation)
├── Use case: [when to invoke]
├── More structured/invasive approach
└── Shares principles with skill
```

## Edge Cases and Common Ambiguities

**Command vs Skill:**
- If it could work either way, prefer **Skill** for complex workflows, **Command** for simple prompts
- User preference matters: some teams prefer explicit commands, others prefer auto-activation

**Skill vs Agent:**
- Use **Agent** when deep expertise or context isolation is critical **AND** the work can be delegated
- Use **Skill** when workflow guidance is needed but can share context
- **Critical test:** Can Claude complete this independently and return results (Agent), or does it require ongoing human collaboration (Skill)?

**Multiple classifications:**
- Some functionality could legitimately be multiple types (e.g., both command and skill versions)
- Consider team workflow preferences and existing patterns

## The Delegatability Test (Skill vs Agent)

When choosing between Skill and Agent, the critical question is: **Can this work be delegated?**

### Can be delegated (Agent)

Work that Claude can complete independently and return results:
- "Review code and return findings"
- "Analyze security vulnerabilities in the codebase"
- "Generate performance report with recommendations"
- "Research five caching strategies and write comparison"
- "Audit entire codebase for architecture anti-patterns"

**Characteristics:**
- Claude can work independently
- Human receives results after completion
- Analysis can happen in isolation
- Deep dive doesn't require human input throughout

### Requires collaboration (Skill)

Work that requires ongoing human participation:
- "Help me make architectural decisions"
- "Guide me through TDD process"
- "Brainstorm design options with me"
- "Refine my rough idea into a design"
- "Create ADRs during design discussions"

**Characteristics:**
- Human must participate throughout
- Iterative back-and-forth required
- Decisions need human judgment
- Context builds up during conversation

### Critical: Expertise depth alone doesn't determine type

**Even if expertise is deep, if the human must be involved throughout, it's a Skill, not an Agent.**

**Example - Test-Driven Development:**
- ❌ Superficial thinking: "Complex methodology + expertise in testing = Agent"
- ✓ Delegatability test: "Developer must write tests and code iteratively with guidance = Skill"

TDD requires ongoing collaboration - the developer writes tests, sees them fail, implements code, and refactors with continuous guidance. This iterative, collaborative nature makes it a Skill, despite being a complex methodology.

**Example - Security Audit:**
- ✓ Delegatable: "Scan codebase for OWASP Top 10 vulnerabilities and report findings = Agent"
- Human receives report after completion, reviews independently

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
