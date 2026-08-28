---
name: technical-writing
description: Use when authoring or substantively reviewing the content of technical documentation, READMEs, RFCs, design explanations, tutorials, how-to guides, reference material, PR descriptions, or other engineering prose. Helps choose the document mode, organize information for the reader, write direct instructions, maintain precise terminology, and remove ambiguity. Do not use for GFM syntax, Markdown formatting, links, tables, or structural validation alone; use markdown-toolkit for those mechanics.
---

# Technical Writing

Write for an engineer who needs to understand the text correctly on the first
read.

## Workflow

### 1. Identify the reader and job

Determine:

- who will read the document;
- what they are trying to do or understand;
- what they already know;
- what evidence, commands, or reference material they need.

Do not invent missing product or system facts. Inspect the repository or ask
for information that cannot be observed.

### 2. Choose one document mode

Classify the document before drafting:

| Mode | Reader's job | Author's job |
|---|---|---|
| Tutorial | Learn by completing a guided experience | Protect the learning path and show visible progress |
| How-to | Complete a specific task | Give direct steps and relevant branches |
| Reference | Look up facts | Describe options, limits, errors, and contracts completely |
| Explanation | Understand a bounded topic | Explain context, constraints, alternatives, and rationale |

Keep one primary mode per document. Split and link when readers need a
different mode. For example, link from a how-to guide to complete reference
details instead of interrupting the procedure.

### 3. Build the structure

Put the common path and essential facts first. Use headings that communicate
the section's point or task. Keep prerequisites before steps and warnings
before the actions they constrain.

For procedures:

1. State the outcome.
2. List prerequisites.
3. Give one action per step.
4. Show expected results where they help the reader detect failure.
5. Put optional branches after the common path.
6. End with a check that confirms the task succeeded.

For explanations, anchor the document on a real question and distinguish facts,
constraints, decisions, alternatives, and opinion.

### 4. Write precisely

Use the repository's real symbol, command, flag, and component names. Do not
rotate synonyms for variety.

Prefer:

- present tense;
- active voice when the actor matters;
- direct commands for instructions;
- conditions before the action they govern;
- concrete mechanisms and measurements;
- descriptive link text;
- one coherent thought per sentence.

Retain passive voice, longer sentences, or specialized terms when they improve
precision. Explain necessary unfamiliar terms once.

### 5. Remove ambiguity

Check that:

- `only`, `not`, and similar modifiers sit beside what they modify;
- each pronoun points to one clear noun;
- each clause has an explicit subject and verb;
- long noun strings are unpacked;
- `and` and `or` group terms unambiguously;
- one concept has one name throughout the document;
- examples, counts, paths, and commands are valid for the current revision.

### 6. Apply the appropriate final pass

- Use `markdown-toolkit` for GFM structure and syntax validation.
- Use `unslop` only when the user requests an AI-pattern and voice cleanup.
- Preserve citations, evidence-calibrated uncertainty, quoted text, and formal
  terminology through every editorial pass.

## Detailed guidance

Read [references/style-guide.md](references/style-guide.md) when drafting a
substantial document or diagnosing unclear prose. It contains mode-specific
guidance, sentence-level checks, and examples.

## Output

When authoring, return or write the requested document. When reviewing, report
the highest-impact structural and clarity problems first, with concrete
rewrites. Do not turn a writing review into a Markdown lint report.
