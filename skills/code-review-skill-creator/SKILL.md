---
name: code-review-skill-creator
description: Generate a repo-specific code-review skill (SKILL.md) for any GitHub repository by mining its PR history, issue history, and codebase, then synthesizing the findings into a reusable reviewer skill. Use whenever the user wants to "create a code review skill", "generate a review skill for my repo", "build a code reviewer for this repo", or asks for a skill/agent that knows the review standards of a specific repository — even if they don't use those exact words. Orchestrates two sub-agents — a discovery agent that produces an evidence report, then a generation agent that synthesizes that evidence into a final SKILL.md.
disable-model-invocation: true
---

# Code Review Skill Creator

This skill produces a **repo-specific code-review SKILL.md** for a target GitHub repository. The output is a reusable skill an AI coding agent can load whenever it reviews a PR for that repo.

The skill works in two phases, each run by an isolated sub-agent:

1. **Discovery** — Mine the target repo's PR review history, issue history, and codebase to produce an evidence report (`code-review-evidence.md`).
2. **Generation** — Synthesize that evidence into a self-contained skill (`code-review-skill.md`).

Discovery and generation are intentionally split so the synthesis step works only from cited evidence, never from the agent's prior assumptions about the repo.

## Bundled prompts and templates

This skill's `assets/` directory contains four supporting files. Pass them to sub-agents by absolute path:

- `assets/code-review-discovery-prompt.md` — The prompt the discovery sub-agent follows.
- `assets/code-review-evidence-template.md` — The structure the discovery sub-agent's report must match.
- `assets/code-review-skill-generation-prompt.md` — The prompt the generation sub-agent follows.
- `assets/code-review-skill-template.md` — The structure the generation sub-agent's output must match.

Treat them as read-only inputs to sub-agents. Do not inline their contents into your own context — sub-agents read them directly.

## When to use this skill

Use this skill when the user wants to bootstrap a code-review skill for a repository, including phrasings like:
- "Create a code review skill for `<repo>`."
- "Generate a SKILL.md for reviewing PRs in this repo."
- "Build a reviewer agent that knows this codebase's standards."
- "Mine the review patterns from `<repo>` and turn them into a skill."

Do **not** use this skill to *perform* a code review on a specific PR — for that, the user wants a `code-review` skill (the output of *this* skill), not the creator.

## Inputs to collect

Before starting, gather these from the user (ask if not provided):

1. **Target repository path** — Absolute local path to a checkout of the repo (the discovery sub-agent runs `gh` and inspects files there). Example: `C:\repos\runtime`.
2. **Target repository identifier** — The `owner/repo` form used by `gh` (e.g., `dotnet/runtime`). Usually inferable from the checkout's `origin` remote; confirm only if ambiguous.
3. **Output directory** — Where the final `code-review-skill.md` (and intermediate evidence report) should land. Default to `<target-repo>\.github\skills\code-review\` if the user has no preference; confirm before writing into the target repo.

If the user only gives a repo name or URL, ask for the local checkout path before proceeding — the discovery sub-agent needs a working tree to inspect.

## Workflow

Use the `task` tool with `agent_type: "general-purpose"` to run each phase. Run them **sequentially** — generation depends on the discovery output. Each sub-agent runs in a fresh context, so all needed file paths must be passed explicitly in the prompt.

### Phase 1: Discovery

**Before spawning the sub-agent, check whether `<output-dir>\code-review-evidence.md` already exists.** If it does, ask the user whether to reuse it or regenerate, and skip directly to Phase 2 if they choose reuse. Discovery is the long step; reuse is usually the right default when the file is recent and the target repo hasn't changed significantly.

Use the `ask_user` tool with choices like `["Reuse existing evidence (Recommended)", "Regenerate from scratch"]`. When showing the question, include the file's size and last-modified date so the user can judge freshness.

If the user chooses reuse, proceed to Phase 2 with the existing file.

Otherwise, spawn a discovery sub-agent with a prompt that instructs it to:

1. Change to the target repo's working directory.
2. Read `<this-skill-dir>\assets\code-review-discovery-prompt.md` in full and follow the instructions inside the fenced `## Prompt` block literally.
3. Use `<this-skill-dir>\assets\code-review-evidence-template.md` as the required output structure.
4. Write the final evidence report to `<output-dir>\code-review-evidence.md` (create the directory if needed). **Write the file as UTF-8 without BOM** — the report contains em-dashes and other non-ASCII characters that get mangled (e.g., `��` replacement chars) if the file is saved with a different encoding.
5. Reply with only the absolute path of the written file — no commentary.

Recommended mode: `background` (mining 100 PRs + 200 issues via `gh` is slow). Tell the user discovery is running and wait for the completion notification before launching Phase 2.

When the sub-agent completes, sanity-check the evidence file exists and is non-trivial in size (typically >10 KB). If it's missing or empty, surface the failure to the user rather than launching generation against bad input.

### Phase 2: Generation

Spawn a generation sub-agent with a prompt that instructs it to:

1. Read these files in full:
   - `<output-dir>\code-review-evidence.md` (the discovery output).
   - `<this-skill-dir>\assets\code-review-skill-generation-prompt.md` (the procedure to follow).
   - `<this-skill-dir>\assets\code-review-skill-template.md` (the required output structure).
2. **NOT** read any prior `SKILL.md` for the target repo, any web pages about its review standards, or any other code-review skill — its only inputs are the three files above. (This keeps the synthesis honest.)
3. Follow the generation prompt's Synthesis Rules, Hard Rules, Final Constraints, and Self-Audit Checklist literally.
4. Write the final skill to `<output-dir>\code-review-skill.md` (or `SKILL.md` if the user prefers). **Write the file as UTF-8 without BOM** — the skill contains emoji (🤖, ✅, ⚠️, ❌, 💡, 📝) and em-dashes that get mangled (e.g., `��` replacement chars) if the file is saved with a different encoding.
5. Reply with only the absolute path — no commentary.

Recommended mode: `background`.

When the sub-agent completes, briefly verify the output file exists, then surface to the user:
- The final path.
- The repo-specific categories generated (skim the change-area table in `## Step 3` and the leading repo-specific items under `### What to Flag`).
- Anything flagged in the evidence report's "Data limitations" section that the user may want to expand before adopting the skill.

## Output

The final deliverable is `<output-dir>\code-review-skill.md`. The intermediate `code-review-evidence.md` is also kept — it documents the basis for every rule and is useful when the user later wants to refine the skill or argue for/against a specific rule.

## Notes for the orchestrator

- **Do not inline** the discovery or generation prompts into your own context. They are large and meant for sub-agents.
- **Do not edit** the four bundled files as part of running this skill. They are the controlled inputs whose stability defines the skill's behavior. Refining them is a separate workflow (see `code-review-template-refinement-prompt.md` elsewhere in the repo).
- **Do not run the target repo's existing review skill** during this workflow — the goal is to *create* one, possibly to compare with what already exists.
- If the user wants iterative refinement of the generated skill against an existing one, that is a different task; offer to set it up but do not start it implicitly.
