---
name: prompt-engineering
description: Use when crafting prompts for AI models, reviewing existing prompts for quality, or designing system prompts for agents and tools - provides expert guidance on structure, clarity, common patterns, and model-specific optimizations to create effective, token-efficient prompts
---

# Prompt Engineering

## Overview

Effective prompts are specific, structured, scoped, and matched to task complexity. This skill helps craft new prompts, review weak prompts, and design system prompts for agents or tools.

**Core principle:** specificity beats generality, structure aids parsing, examples clarify intent, and output format specification is mandatory.

## When to Use This Skill

Use when crafting prompts for AI models or agents, reviewing prompts that give inconsistent results, designing system prompts for tools or extensions, optimizing prompts for token efficiency, or needing model-specific guidance.

Do not use for general AI/ML questions, model training or fine-tuning, or non-prompt writing tasks.

## Core Principles

1. **Specificity beats generality**: "Analyze code" becomes "Identify security vulnerabilities in authentication code."
2. **Examples clarify intent**: show what good output looks like when the task or format is novel.
3. **Constraints enable focus**: define boundaries, format, scope, and edge cases.
4. **Structure aids parsing**: use headings, delimiters, XML tags, or schemas.
5. **Token efficiency comes from precision**: remove filler and redundant instructions.
6. **Context placement matters**: keep critical instructions near the task and separate them from source material.
7. **Output format is mandatory**: specify JSON schema, markdown template, bullet format, or another exact contract.

## Crafting Workflow

1. **Define the job.** State the specific action, target, success criteria, and model or agent that will receive the prompt.
2. **Choose the structure.** Use markdown sections for universal compatibility, XML-style tags when Claude benefits from strict separation, or schemas when structure must be parsed. Open `references/prompt-structures-and-patterns.md` when you need detailed structures, clarity techniques, reusable patterns, or longer examples.
3. **Provide only necessary context.** Include assumptions, domain facts, inputs, and constraints needed for this task. Define ambiguous terms and quantify vague requirements.
4. **Specify the output contract.** Name the required fields, order, length, style, and failure behavior. For structured output, include a compact schema or exact example.
5. **Add examples when they reduce ambiguity.** Prefer one or two representative examples over long prose.
6. **Check edge cases.** State what to do for empty, invalid, conflicting, or insufficient input.
7. **Trim and test.** Remove filler, duplicate constraints, and generic politeness. Open `references/token-efficiency-and-review.md` when auditing a prompt for waste, common mistakes, or red flags.

### Tiny Example

```text
You are a security reviewer.
Task: Review the authentication function for authorization bypasses and unsafe session handling.
Constraints: Focus only on exploitable issues in the provided code.
Output:
- Finding
- Severity: Critical|High|Medium|Low
- Evidence: file:line and why it is exploitable
- Fix
If no issues are found, say "No exploitable findings found" and list assumptions.
```

## Review Workflow

When reviewing an existing prompt, check in this order:

1. Can the task be restated in one precise sentence?
2. Is the desired output format explicit enough to evaluate?
3. Is all necessary context present and separated from instructions?
4. Are scope, constraints, and edge cases stated positively?
5. Are examples present when the format or judgment is non-obvious?
6. Is the prompt free of vague verbs such as "improve," "optimize," and "make better" unless they are defined?
7. Is the chosen model appropriate for context length, modality, reasoning depth, and structured-output needs?

Open `references/quick-reference.md` when you need the compact checklist, template, model-selection table, or bottom-line summary.

## Agent and Tool Prompts

System prompts for agents must define identity, capabilities, boundaries, behavioral guidelines, tool-use rules, error recovery, and output format. Tool descriptions must include specific trigger conditions, parameters, returns, examples, and when not to use the tool.

Open `references/agent-and-tool-prompts.md` when designing system prompts, tool descriptions, context-management rules, validation gates, error recovery, or human checkpoints.

## Model-Specific Guidance

Universal prompt principles should come first. Add model-specific optimizations only when they matter for capabilities, cost, context handling, output reliability, or known quirks.

Open `references/model-notes.md` when you need detailed Claude, GPT, Gemini, open-source, context-window, tokenization, or model-selection notes.

## Non-Negotiables

- Always specify the output format.
- Define vague goals before asking the model to satisfy them.
- Separate instructions from context and examples.
- Prefer positive, concrete instructions over negative reminders.
- Use one clear primary task per prompt unless decomposition is explicitly part of the workflow.
- Do not rely on assumed product, codebase, or user context that is not included or retrievable by the model.
- Do not over-optimize for one provider's quirks before the universal prompt is clear and testable.

## Compact Checklist

- [ ] Specific task and target
- [ ] Success criteria
- [ ] Required context and assumptions
- [ ] Constraints and edge cases
- [ ] Exact output format
- [ ] Examples if complex or novel
- [ ] Appropriate model choice
- [ ] No filler, duplicated constraints, or undefined vague terms
