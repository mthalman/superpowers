# Technical writing style guide

## Document modes

### Tutorial

A tutorial teaches through a successful experience.

- Open with what the learner will build or accomplish.
- Produce a visible result early.
- Keep the path controlled and concrete.
- Explain only what the learner needs at that moment.
- State what the learner should observe after important steps.

### How-to

A how-to guide solves one practical problem for a competent reader.

- Name the guide for the goal.
- Give actions, prerequisites, and relevant decisions.
- Skip conceptual teaching and exhaustive option catalogs.
- Link to explanation and reference material.

### Reference

Reference material supports lookup.

- Mirror the structure of the system being described.
- State facts, defaults, limits, errors, and compatibility.
- Prefer generated facts when the source can produce them.
- Avoid persuasion and procedural hand-holding.

### Explanation

Explanation builds understanding.

- Cover one bounded topic.
- Start from a real "why" question.
- Include history, constraints, alternatives, and tradeoffs.
- Separate evidence from interpretation.

## Sentence-level guidance

### Address the reader directly

Use `you` when it makes an instruction clearer. Write commands as commands.

Weak:

> The configuration should then be updated.

Strong:

> Update `config.json`.

### Put conditions first

Weak:

> Delete the cache directory if the schema version changed.

Strong:

> If the schema version changed, delete the cache directory.

### Name the actor

Weak:

> Requests are validated before processing.

Strong:

> The gateway validates requests before the worker processes them.

Passive voice is appropriate when the actor is unknown or irrelevant.

### Use one term per concept

If the code calls a component `EvaluationAdapter`, use "evaluation adapter"
throughout the document. Do not alternate between "runner", "bridge", and
"adapter" unless they are different concepts.

### Prefer mechanisms to claims

Weak:

> The new cache significantly improves performance.

Strong:

> The cache reduces median startup time from 420 ms to 260 ms.

### Keep uncertainty accurate

Do not remove `may`, `likely`, or `appears to` when the evidence is indirect.
Reduce stacked hedges, but preserve the actual confidence level.

## Ambiguity checks

- Put `only` next to the word or phrase it limits.
- Replace an ambiguous `this`, `it`, or `they` with the noun.
- Give every clause a verb.
- Break long noun stacks into clauses.
- Repeat articles when they distinguish separate objects.
- Replace `and/or` with `a, b, or both`.
- Use `either...or` and `both...and` when grouping is otherwise unclear.

## Lists and headings

- Use numbered lists for sequences.
- Use bullets for unordered sets.
- Introduce lists with a complete sentence.
- Keep list items grammatically parallel.
- Use sentence case headings.
- Use task headings as verb phrases and concept headings as noun phrases.
- Do not skip heading levels.

## Review questions

1. Does the document have one primary mode?
2. Can the intended reader find the common path immediately?
3. Does each instruction contain one action?
4. Are conditions and warnings placed before guarded actions?
5. Does every technical term match the code or get defined?
6. Can any sentence be parsed in two materially different ways?
7. Are commands, paths, counts, examples, and links current?
8. Does the document state facts and opinions as different things?
