# Skill Review Criteria

The detailed rubric the skill-reviewer applies. It encodes established skill-authoring best practices so a review measures a skill against how skills are actually meant to be written — not just personal taste.

## How to use this rubric

Walk every category. For each, note what holds up and what doesn't, assign a severity, and give a concrete fix. Severity is a **default per category**, not a rule — judge real impact in context. A clean skill earns a short "Approved" with its strengths; do not manufacture findings to fill sections.

### Severity definitions

- **Blocking** — the skill won't be discovered, will misfire constantly, breaks when run, or actively misleads the agent. Must fix before merge.
- **Important** — the skill works, but a real user or agent will predictably hit friction, confusion, or wrong behavior. Should fix.
- **Minor** — advisory: wording, ordering, formatting, optional additions. Never blocks approval.

Litmus test for "is this Minor?": *Would this cause an agent to fail to trigger the skill, or to do the wrong thing once triggered?* If no, it's Minor.

### Classify the invocation model first

Before judging the description, decide how the skill is meant to be invoked — it changes the standard you hold the description to:

- **Model-invoked (auto-discovered).** The agent reads the description and decides on its own whether to load the skill. This is the default for most skills. The description is a router entry and must work hard to trigger correctly (category 2, model-invoked branch).
- **Explicitly-invoked.** A human or another skill invokes it deliberately — signaled by `disable-model-invocation: true`, a command/slash wrapper, or a description/body framed as "run this when you want to…". Examples: skill *creators*, one-shot generators, command-style skills. The agent does **not** route to these from the description, so triggering "pushiness" is irrelevant and must not be flagged.

If the invocation model is ambiguous, state your assumption in the review and evaluate accordingly. A frequent, real defect is a **mismatch**: a skill that should be explicitly-invoked but lacks `disable-model-invocation` (so it auto-fires unexpectedly), or one that should auto-discover but is gated off.

### The two failure modes to keep front of mind

Almost every serious skill defect reduces to one of these:

1. **Discovery failure** *(model-invoked skills only)* — the skill exists but the agent never loads it (weak/absent triggers), or loads it at the wrong time (over-broad description). Owned mostly by category 2. Not applicable to explicitly-invoked skills.
2. **Execution failure** *(all skills)* — the skill loads/runs but the agent can't follow it, follows it into the wrong behavior, or wastes effort (vague steps, rigid noise, broken references, bloat). Owned by categories 4–9.

Weight your review toward these outcomes.

## Categories

1. Frontmatter validity
2. Description quality and triggering *(highest leverage; standard depends on invocation model)*
3. Structure and clarity
4. Instructional writing quality
5. Actionability
6. Scope and focus
7. Progressive disclosure and token efficiency
8. Bundled resources: organization and existence
9. Examples and output formats
10. Repo and convention consistency
11. Completeness
12. Safety and lack of surprise

---

## 1. Frontmatter validity — *Blocking*

- Opens with `---` and closes with a matching `---`.
- The YAML parses: no tabs, no unbalanced quotes, no unescaped colon breaking a value (quote descriptions that contain colons).
- `name` is present, kebab-case, and **matches the skill's directory name exactly**. A mismatch can stop the skill from resolving.
- `description` is present and non-empty (see category 2).
- Optional keys are used correctly:
  - `disable-model-invocation: true` **only** for skills meant to be invoked explicitly (creators, one-shot generators, commands), and it **should** be present on those — its absence on a skill that clearly shouldn't auto-fire is a real defect (the skill will trigger unexpectedly). Conversely, it must not be set on a skill that's meant to auto-discover. Cross-check against the invocation model you classified above.
  - `compatibility` (required tools/deps) only when genuinely needed — it's rare.
  - No unknown or misspelled keys.
- The description isn't so long it reads as a body paragraph; the metadata block is meant to be lightweight (~100 words is the mental model). Over-long is *Minor*; missing triggers is *Blocking* (category 2).

## 2. Description quality and triggering — *Blocking to Important (highest leverage)*

**Apply the standard that matches the invocation model you classified.** Both kinds of skill need a description that states **what the skill does** (first clause) and **when to reach for it**; they differ in whether the description also has to *trigger* the skill.

### Common to every skill

- States what it does up front, and the situations it's for.
- Written about the situation, imperative/third-person ("Use when…"), not first person.
- Names artifacts/nouns a reader would recognize ("a SKILL.md", "a PR diff", "a .docx").
- Isn't so long it becomes a body paragraph.
- Draws a boundary against any confusable sibling ("do not use this to author a skill — that's skill-creator").

### Model-invoked skills — judge the description like a router

The description is the **only** text the agent sees when deciding whether to load the skill. Both halves must carry, and triggering is on the line.

- **Bias toward triggering.** The dominant real-world failure is **under-triggering** — agents skip skills that would have helped. So descriptions should lean slightly *pushy*: enumerate the situations and phrasings that should fire it, including implicit ones ("…use this whenever the user mentions X, Y, or Z, even if they don't explicitly ask for it"). A description that only restates the title is the most common defect — *Blocking to Important*.
- **But stay bounded.** Pushiness is *coverage of the right situations*, not firing on everything. A description so broad it matches unrelated work ("helps with code") is also broken — it fires at the wrong times and crowds out better-matched skills.
- Includes real trigger phrases a user would actually type.

**Weak:** `description: Reviews skills.` — nothing to match on; will under-trigger badly.
**Over-broad:** `description: Helps you with skills and prompts and related tasks.` — matches almost anything; fires at the wrong times.
**Strong:** `description: Use when reviewing a newly authored or modified skill (a SKILL.md and its bundled files) before merge. Checks frontmatter, description/trigger quality, structure, actionability, scope, and broken references. Triggers on "review this skill", "check my SKILL.md", or right after a skill is created — even if the user doesn't say the word "review".` — names the artifact, situations, explicit trigger phrases, a pushy-but-bounded net, and an implicit-trigger cue.

### Explicitly-invoked skills — judge the description for the caller, not the router

The agent does not route to these from the description; a human or another skill invokes them deliberately. So:

- **Do not** flag the description for lacking pushy trigger phrases, implicit-trigger cues, or "even if the user doesn't say…" hooks. That standard doesn't apply.
- **Do** confirm the description clearly tells a human/caller *what the skill produces and when to choose it*, so the person deciding to invoke it can tell it apart from alternatives.
- **Do** confirm the invocation gating is consistent: `disable-model-invocation: true` (or the equivalent wrapper) is actually present, matching the intent. A description written as explicitly-invoked but left model-invokable is a *Blocking* mismatch (it'll auto-fire).
- Over-broad wording matters less here (nothing auto-matches on it), but clarity for the human still matters — *Minor to Important*.

**Fine for an explicitly-invoked creator:** `description: Create new skills, modify and improve existing skills, and measure skill performance. Use when the user wants to create a skill from scratch, edit an existing one, or benchmark a skill.` — clear what/when for a human invoker; needs no trigger-phrase padding.

## 3. Structure and clarity — *Important*

- A single clear H1 title.
- An overview/purpose near the top: a reader knows the point in one paragraph.
- A "When to use" section, and — where a confusable neighbor exists — a "when not to".
- A logical, sequenced workflow (numbered steps or clear headings) rather than undifferentiated prose.
- Headings are meaningful and navigable; a reader can skim to the part they need.
- "When to use" information lives in the **description**, not buried only in the body — the body can elaborate, but the situational signal (and, for model-invoked skills, the trigger signal) must be in the metadata.

## 4. Instructional writing quality — *Important*

How the body talks to the model matters as much as what it says. Modern models follow reasoning better than rules.

- **Imperative voice.** Instructions are commands to the agent ("Read the file", "List the siblings"), not descriptions of what happens.
- **Explain the *why*.** Prefer a sentence of rationale over a bare command. An agent that understands *why* generalizes to cases the skill didn't foresee.
- **Rigid-directive smell.** Frequent all-caps `MUST` / `ALWAYS` / `NEVER`, or heavy rigid scaffolding, is a **yellow flag**. Flag it and suggest reframing as an explained reason — unless the constraint is genuinely safety-critical or a hard external requirement, where emphasis is warranted. This is advisory (*Minor*) unless the rigidity is actively causing wrong or wasteful behavior.
- **Theory of mind / generality.** The skill should read as guidance a capable agent can apply broadly, not a script overfit to two examples. Instructions that only make sense for one specific input are a smell.
- **Leanness.** Every sentence should pull its weight. Padding, restated context, and motivational filler dilute the signal and cost context budget. Flag bloat.
- **No overfitting.** Skills are meant to be used across many prompts. Hardcoded specifics that won't generalize (one repo's file names, one example's exact values baked into the instructions) should be generalized or moved to examples. *Important* when it would break reuse.

## 5. Actionability — *Blocking to Important*

- Steps are concrete enough to execute without guessing.
- Steps name the tools/commands/files to use where relevant.
- Decision points state the criteria for each branch, not "decide appropriately".
- Aspirational verbs ("be thorough", "handle edge cases") are backed by *how*.
- Red flag: a step that sounds meaningful but gives the agent nothing to run ("analyze the situation and respond accordingly"). *Blocking* if a core step is like this; *Important* if peripheral.

## 6. Scope and focus — *Important*

- **One clear responsibility.** If the skill bundles several unrelated jobs, recommend splitting.
- **No duplication.** Skim sibling skill descriptions; if another skill already owns this job, recommend deferring to it rather than shipping a near-duplicate.
- **Invoke, don't reinvent.** If a task is another skill's specialty, this skill should call that skill by name instead of re-implementing it.
- **Right-sized.** Not so trivial it's a one-line command that needs no skill; not so sprawling it crams a whole methodology into one SKILL.md (that wants decomposition + progressive disclosure).

## 7. Progressive disclosure and token efficiency — *Important to Minor*

Skills load in three levels; respect them:

1. **Metadata** (name + description) — always in context (~100 words). Keep it tight.
2. **SKILL.md body** — loaded whenever the skill triggers. **Target < ~500 lines.** If it's approaching that, that's a signal to add a layer of hierarchy and push detail into references.
3. **Bundled resources** — loaded only when needed; effectively unlimited.

Check:
- `SKILL.md` stays lean; long rubrics, catalogs, and domain detail live in `references/`, not inline.
- References are pointed to **with guidance on *when* to read them** ("Read `references/x.md` before step 3"), not just listed.
- Large reference files (> ~300 lines) include a table of contents.
- Multi-domain skills organize references **by variant** (`references/aws.md`, `gcp.md`, `azure.md`) so the agent loads only the relevant one.
- No large content inlined that will be pulled into context on every consideration of the skill.

Walls of always-loaded text are a token-efficiency smell — recommend extraction. Severity scales with size: a genuinely bloated SKILL.md is *Important*; a slightly long one is *Minor*.

## 8. Bundled resources: organization and existence — *Blocking (existence) / Minor (organization)*

**Existence (Blocking).** Every relative path the skill mentions (`references/…`, `assets/…`, `scripts/…`) must actually exist in the skill directory, at the correct relative path. A dangling reference breaks the skill the moment it runs. If the skill claims to bundle N files, N files are present. Links to sibling skills use names that exist.

**Organization (Minor to Important).** Resources should sit in the right bucket:
- `scripts/` — executable code for deterministic or repetitive work. If the guidance implies every invocation would re-write the same helper (e.g., each run builds the same `create_docx.py`), recommend bundling it as a script instead. (*Important* — it wastes every future run.)
- `references/` — docs loaded into context as needed.
- `assets/` — files used in the *output* (templates, icons, fonts), not instructions.
Misfiled resources (a script pasted inline as prose, a reference that should be an asset) are *Minor* unless they cause execution problems.

## 9. Examples and output formats — *Minor to Important*

- Where a step's output has a required shape, the skill defines it explicitly (a template block the agent copies), rather than describing it loosely. Missing a needed format spec is *Important*.
- Non-obvious steps include a concrete example (input → output). Examples are one of the highest-value, lowest-cost additions; their absence on a subtle step is *Minor to Important*.
- Examples are illustrative, not the whole spec — they shouldn't be so specific the skill only works for them (ties back to category 4's overfitting).

## 10. Repo and convention consistency — *Minor to Important*

- Directory name and `name` follow the repo's style (e.g., gerund names like `writing-plans`, or noun names like `code-review`, `adr-generator`).
- File layout matches siblings (`SKILL.md`, `references/`, `assets/`, `scripts/`).
- Terminology and tool references match how the rest of the repo describes them.
- Reviewer/prompt-template patterns, if the repo has them, are followed rather than reinvented.

## 11. Completeness — *Blocking to Important*

- No placeholders: `TODO`, `TBD`, `FIXME`, `[FILL IN]`, `lorem ipsum`, empty sections, or "see below" with nothing below.
- Every started section is finished.
- The skill's result is defined — the agent knows what "done" looks like.

## 12. Safety and lack of surprise — *Blocking*

- **Intent matches description.** The skill does what its name/description imply, with no hidden or surprising behavior.
- **No malicious content.** No malware, exploit code, data-exfiltration, or instructions to gain unauthorized access. (Benign roleplay/persona skills are fine.)
- **Guards destructive actions.** Steps that force-push, delete, rewrite history, expose secrets, or hit external systems are gated with a check or an explicit confirmation, not issued blindly.
- **Accurate mechanics.** Tool names, commands, flags, and paths are real and correct; claims about how other skills/systems behave are true. (Wrong mechanics are also an execution bug — *Blocking*.)

---

## Fast checklist (quick pass)

- [ ] Frontmatter parses; `name` == directory; `description` present.
- [ ] Invocation model identified (model-invoked vs explicitly-invoked); `disable-model-invocation` matches intent.
- [ ] Description says **what** + **when**. For model-invoked skills: real trigger phrases, pushy-but-bounded, boundary vs. neighbors. For explicitly-invoked skills: clear to a human caller (don't demand trigger pushiness).
- [ ] Clear title, overview, "when to use", sequenced workflow.
- [ ] Imperative voice; explains *why*; not a wall of all-caps MUSTs; not overfit.
- [ ] Steps are executable; branches have criteria.
- [ ] One responsibility; doesn't duplicate a sibling; invokes rather than reinvents.
- [ ] SKILL.md lean (< ~500 lines); detail in `references/` with when-to-read pointers; big refs have a TOC.
- [ ] Every referenced file exists at the right path; resources in the right bucket.
- [ ] Output formats specified where needed; examples on subtle steps.
- [ ] Matches repo naming/layout conventions.
- [ ] No placeholders; result is defined.
- [ ] Intent matches description; destructive actions guarded; mechanics accurate.

## Reviewer stance

- Lead with what the skill does well — especially a sharp, discoverable description. Authors calibrate on positive signal too.
- Every finding gets **location + why it matters + suggested fix**. A finding without a fix is a complaint, not a review.
- Prefer the smallest change that resolves the issue.
- Reframe, don't pile on: if the skill leans on rigid MUSTs, show the explained-reasoning alternative rather than just flagging.
- Don't invent problems to fill the template. A clean skill gets a short "Approved" plus its strengths, and that's a complete review.
