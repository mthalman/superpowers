---
name: skill-reviewer
description: Use when reviewing a newly authored or recently modified skill (a SKILL.md and its bundled files) for quality before it is merged or adopted. Checks frontmatter validity, description and trigger quality, structure, actionability, scope, progressive disclosure, and broken references, then reports findings by severity. Triggers on "review this skill", "is this skill any good", "check my SKILL.md", "did I write this skill correctly", or right after a skill is created or edited.
---

# Skill Reviewer

Review a newly authored or modified skill and report concrete, actionable findings. The goal is to catch the problems that actually make a skill fail — a description that never triggers, instructions an agent can't follow, broken references, or scope that overlaps an existing skill — not to nitpick prose.

A skill's most important job is to be **discovered and then followed**. Bias your review toward those two outcomes.

## When to Use This Skill

Use this skill when:

- The user asks to review, critique, or sanity-check a skill or a `SKILL.md`.
- A skill has just been authored or edited (e.g., via skill-creator) and needs a quality pass before merge.
- The user asks "is this skill good / correct / discoverable?"

Do **not** use this skill to *author* a new skill from scratch — that is the skill-creator's job. Use this skill to evaluate one that already exists.

## Inputs to Collect

Before reviewing, determine the target:

1. **The skill to review** — a path to a `SKILL.md`, a skill directory, or the file(s) currently being discussed. If ambiguous (e.g., "review my skill" with several candidates), ask which one.
2. **Context** (optional) — anything the author wants weighted, such as "I'm worried it won't trigger" or "is the scope too broad?".

If only a directory is given, the target is that directory's `SKILL.md` plus every file it bundles.

## Review Process

Complete these steps in order:

1. **Read the whole skill.** Read the `SKILL.md` in full, then read every file it references (`references/*`, `assets/*`, scripts, prompt templates). You cannot judge actionability or broken references without reading what the skill points to.

2. **Classify the invocation model.** Decide whether this skill is **model-invoked** (auto-discovered by the agent from its description) or **explicitly-invoked** (a human or another skill invokes it deliberately — signaled by `disable-model-invocation: true`, a command wrapper, or a description/body that reads as "run this when you want to…" rather than "use when the situation arises"). This determines how you judge the description (step 6) and which failure modes matter. When unsure, state your assumption in the review.

3. **Load the criteria.** Read `references/review-criteria.md` for the detailed rubric and the severity definitions. Evaluate the skill against each category there.

4. **Verify referenced resources exist.** For every relative path the `SKILL.md` mentions, confirm the file is present in the skill directory. A dangling reference is a blocking issue.

5. **Check for overlap.** Glob the sibling skills (the other directories under `skills/`) and skim their descriptions. Flag if this skill substantially duplicates an existing one, or if it reinvents something it should invoke by name.

6. **Judge the description against the right standard for its invocation model.**
   - **Model-invoked skills:** the description is the only thing the agent sees when deciding whether to load the skill — judge it like a router entry. Ask: given only this description, would the agent fire it at the right times and *not* fire it otherwise? Weight toward **under-triggering** — the common failure is a skill that never loads because its description only restates the title. A good description is slightly *pushy*: it names the situations and phrasings that should trigger it, including implicit ones, while staying bounded enough not to fire on unrelated work. This is usually the highest-leverage finding.
   - **Explicitly-invoked skills:** triggering pushiness does **not** apply — the skill is chosen deliberately, not matched. Instead confirm the description clearly states what the skill does and when a human/caller should reach for it, that `disable-model-invocation: true` (or the equivalent) is actually set so it doesn't auto-fire, and that it draws a boundary against any model-invoked neighbor it could be confused with. Do not flag it for "not being pushy enough."

7. **Read the body as instructions to a model, not rules on a wall.** Check that it uses imperative voice, explains *why* rather than leaning on all-caps `MUST`/`ALWAYS`/`NEVER`, stays lean, and isn't overfit to one example. Confirm progressive disclosure: `SKILL.md` lean (target < ~500 lines), heavy detail in `references/` with when-to-read pointers, big references carrying a table of contents.

8. **Produce the report** in the output format below.

## Calibration

**Flag issues that stop the skill from being discovered, followed, or trusted. Ignore taste.**

- **Blocking / Important**: invalid or missing frontmatter; `name` that doesn't match the directory; for a model-invoked skill, a description with no trigger conditions (won't be discovered) or one so broad it fires constantly; a skill that should be explicitly-invoked but auto-fires (missing `disable-model-invocation`), or vice versa; broken/incorrect references; instructions too vague to act on; placeholders (`TODO`, `TBD`, `[FILL IN]`); scope that duplicates another skill; factually wrong tool names or commands; unguarded destructive actions or behavior that doesn't match the stated intent.
- **Minor (advisory)**: wording, ordering, formatting, over-reliance on rigid MUSTs where explained reasoning would serve, mildly long SKILL.md, "nice to have" additions.
- **Not an issue**: stylistic preferences, valid alternative phrasings, personal formatting choices, and — for an explicitly-invoked skill — a description that isn't "pushy" about triggering.

The dominant real-world failure **for model-invoked skills** is **under-triggering** (skills that should fire but don't); the next is **execution failure** (loads but can't be followed). For explicitly-invoked skills, discovery isn't in play — scrutinize execution quality and correct invocation gating instead.

Approve when the skill is discoverable, its instructions are followable, and nothing is broken — even if you'd have written some sentences differently.

## Output Format

```
## Skill Review: <skill-name>

**Status:** Approved | Changes recommended | Needs work

**Strengths:**
- <what the skill does well — especially a sharp, discoverable description>

**Blocking (must fix before merge):**
- [<file>:<location>]: <issue> — <why it breaks discovery/execution> — <suggested fix>

**Important (should fix):**
- [<file>:<location>]: <issue> — <why it matters> — <suggested fix>

**Minor (advisory, does not block):**
- [<location>]: <suggestion>
```

Omit any severity section that has no findings. If everything passes, say so plainly and keep the report short — don't invent problems to fill the template.

## Resources

### references/review-criteria.md

The comprehensive rubric, grounded in established skill-authoring best practices (progressive disclosure, description triggering, instructional writing style, resource organization, safety). Twelve per-category checks with severity defaults, worked strong/weak/over-broad description examples, and a fast checklist. **Read it in full before reviewing** — the SKILL.md above is the workflow; the criteria file is the standard you measure against.
