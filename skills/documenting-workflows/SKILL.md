---
name: documenting-workflows
description: Use when the user wants to document a workflow, process, or procedure through an interview - asks questions one at a time to thoroughly capture steps, prerequisites, edge cases, and troubleshooting, then validates understanding before writing markdown
---

# Documenting Workflows Through Interview

## Overview

Interview the user to thoroughly document a workflow, process, or procedure. Ask questions one at a time until you have complete understanding, then repeat back your understanding for validation before writing the final markdown document.

## Choosing Your Interview Approach

Before settling on an approach, consider the trade-offs:

| Approach | Benefit | Risk |
|----------|---------|------|
| Storytelling ("walk me through...") | Surfaces natural flow | Expert skips "obvious" parts |
| Structured checklist | Ensures coverage | Misses implicit steps |
| Scenario-based probing | Reveals decision logic | Can feel like testing |
| Novice stance ("explain like I'm new") | Permission to state obvious | May feel tedious |

**Recommended blend**: Start with storytelling to get the narrative arc, then use scenario-based probing to surface exceptions, then "novice stance" selectively for compressed steps.

Adapt based on context:
- Long-tenured expert → More failure probing (they'll skip "obvious" steps)
- Non-technical subject → Fewer abstract questions, more concrete examples
- Complex process → More decision point exploration

## The Interview Process

**Starting the interview:**
1. If the workflow is already known, skip "what workflow" and establish scope: "When does [X] actually start and end?"
2. Ask about the purpose - why does this workflow exist? What problem does it solve?
3. Ask who performs this workflow (role, skill level required)

**Capturing prerequisites:**
- What must be true before starting?
- Required tools, access, permissions, accounts
- Required knowledge or training
- Environment setup needed

**Walking through the main steps:**
- Ask for a recent real example: "Think about the last time you did this..."
- For each step ask:
  - What exactly do you do?
  - How do you know when this step is complete?
  - What can go wrong here?
  - Are there variations depending on circumstances?
- Continue asking "What's the next step?" until complete
- Ask about decision points - when does the process branch?

**Capturing edge cases and exceptions:**
- What situations require a different approach?
- What are the common mistakes people make?
- What shortcuts do experienced people take?
- What looks obvious but trips up newcomers?

**Troubleshooting:**
- What are the most common problems?
- How do you diagnose each problem?
- What are the fixes?
- When should someone escalate vs. try to fix themselves?

**Validation:**
- When you believe you understand the full workflow, present a structured summary
- Ask the user to confirm accuracy or correct any misunderstandings
- Iterate until they confirm the summary is accurate

## Listening Strategy: Trigger Phrases

Watch for phrases that signal hidden complexity and probe deeper:

| Trigger Phrase | What It Signals | Follow-up Probe |
|----------------|-----------------|-----------------|
| "usually" / "normally" | There are exceptions | "What happens when it's not usual?" |
| "just" / "simply" | Compressed steps | "Can you break that down into smaller pieces?" |
| "everyone knows" | Tacit knowledge | "Pretend I'm brand new - what would I need to know?" |
| "the usual way" | Undocumented variation | "Can you unpack what 'the usual way' includes?" |
| "I check" / "I verify" | Hidden quality gate | "What specifically do you check? What would make you stop?" |
| "it depends" | Decision logic | "What does it depend on? How do you decide?" |
| "Mike handles that" | Handoff point | "How does Mike know when to do his part?" |

## Questions to Avoid Early

- **"Can you give me a checklist?"** - Forces premature structure before you understand actual practice
- **"What's the official policy?"** - Gets aspirational process, not actual behavior
- **Any audit-sounding questions** - Shuts down honesty about workarounds and shortcuts

Let the structure emerge from stories. Ask for checklists only after you've heard the narrative.

## Validation Format

Before writing the document, present your understanding:

```
## My Understanding

**Purpose:** [Why this workflow exists]

**Who performs this:** [Role and skill level]

**Prerequisites:**
- [List each prerequisite]

**Steps:**
1. [Step with key details]
2. [Step with key details]
...

**Decision points:**
- If [condition], then [variation]

**Common problems and fixes:**
- [Problem]: [Fix]

Does this accurately capture the workflow? What needs correction?
```

## Writing the Document

After validation, write the markdown document to the current directory.

**Filename:** Use kebab-case based on workflow name, e.g., `deploying-to-production.md`

**Document structure:**
```markdown
# [Workflow Name]

## Purpose
[Why this workflow exists and what problem it solves]

## Who Should Use This
[Role, skill level, when to use this workflow]

## Prerequisites
- [Prerequisite 1]
- [Prerequisite 2]

## Steps

[Mermaid flowchart showing the high-level workflow]

### [Step Name]
[Detailed instructions]

### [Step Name]
...

## Decision Points
[Document any branching logic or variations]

## Troubleshooting

### [Problem Name]
**Symptoms:** [How to recognize this problem]
**Cause:** [Why it happens]
**Fix:** [How to resolve it]

## Common Mistakes
- [Mistake and how to avoid it]

## Tips from Experts
- [Non-obvious insights that help]
```

## Key Principles

- **Exhaust the topic** - keep asking until there's nothing more to learn
- **Capture tacit knowledge** - experts forget what's not obvious to newcomers
- **Listen for triggers** - "just," "usually," "everyone knows" signal hidden complexity
- **Validate before writing** - misunderstandings are cheaper to fix in conversation
- **Be concrete** - specific commands, exact values, real examples
- **Structure for scanning** - headers, bullets, and formatting for quick reference
