---
name: unslop
description: Remove recognizable AI-writing patterns from existing prose while preserving its meaning, evidence, uncertainty, and intended voice. Use only when the user explicitly asks to unslop, de-AI, humanize, or remove AI tells from text. Applies to documentation, messages, PR descriptions, reports, and other prose, but never rewrites code, commands, identifiers, or quotations.
disable-model-invocation: true
---

# Unslop

Rewrite existing prose so it sounds deliberate, specific, and human.

## Workflow

1. Identify the intended audience, tone, and purpose.
2. Mark unsupported claims, filler, formulaic structure, inflated language, and
   chatbot mannerisms.
3. Rewrite without changing facts, conclusions, citations, or confidence.
4. Restore natural rhythm and a point of view appropriate to the document.
5. Ask what still makes the result look generated and revise once more.

Read [references/patterns.md](references/patterns.md) for the full review
catalog.

## Non-negotiable preservation rules

Do not change:

- quoted text;
- code, commands, paths, identifiers, flags, or API names;
- formal terminology that is precise in context;
- measurements or citations;
- warnings and material caveats;
- uncertainty language required by the evidence.

Do not introduce new facts or arguments.

## Editing rules

- State the concrete fact instead of praising its importance.
- Name sources instead of using vague authority.
- Prefer plain words when they preserve precision.
- Remove filler, generic conclusions, and automatic conversational openings.
- Avoid forced symmetry and repetitive sentence shapes.
- Vary sentence length according to the thought being expressed.
- Use first person and opinion when they fit the source's intended voice.
- Keep necessary complexity instead of pretending every tradeoff is simple.
- Remove every em dash from editable prose. Rewrite with a period or comma. Do
  not substitute an en dash, hyphen used as a dash, or parenthetical aside.
- Preserve em dashes inside protected verbatim quotations, code, commands,
  paths, or identifiers. Do not repeat them outside that protected content.

Treat the pattern catalog as diagnostic guidance except for the ban on em
dashes in editable prose. A listed word may be correct technical vocabulary in
context.

## Output

Return only the revised prose unless the user asks for an edit rationale. If
the source contains an unsupported claim that cannot be repaired without new
research, flag it instead of inventing support.
