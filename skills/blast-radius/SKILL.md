---
name: blast-radius
description: Analyze what a proposed or completed code change could break outside the visible diff, identify the small set of safety assumptions the change depends on, and prove those assumptions with the strongest practical evidence. Use only when the user explicitly invokes blast-radius analysis, asks "what could this break?", or requests focused compatibility or change-impact proof across callers, data formats, lifecycle boundaries, dependencies, or downstream systems.
disable-model-invocation: true
---

# Blast Radius

Find consequential breakage that a diff and symbol search can miss. The goal is
not a longer risk list. The goal is to identify the facts that make the change
safe and prove them.

## Scope

Use this skill for a proposed change, a diff, a commit range, or a named code
path. Establish the exact scope before investigating.

This skill complements code review:

- Use blast radius before a change to discover constraints.
- Use it after a change when one compatibility assumption needs focused proof.
- Use `code-review` when deciding whether an entire change is safe to merge.

## Evidence scale

Record the highest level reached for every material safety fact:

1. **Assertion:** The agent stated the fact. This is not evidence.
2. **Source:** Authoritative code or documentation supports the fact.
3. **Path analysis:** The bad case was traced and shown not to reach the change.
4. **Execution:** A focused script or test exercised the real code.
5. **Live reproduction:** The behavior was demonstrated through the running
   product.

Target level 4 when practical. Label anything below level 4 with its actual
level and the evidence still missing. Never round an inference up to proven.

## Workflow

### 1. Establish the behavioral change

Read the complete diff and the surrounding source. Explain the old and new
behavior, including effects not stated directly in the diff.

Identify:

- added, changed, and removed symbols;
- changed inputs, outputs, errors, timing, or side effects;
- lifecycle or execution-context changes;
- data written or consumed outside the changed module.

### 2. Identify the safety facts

Ask which one or two facts would eliminate most plausible failures if true.
Write each as a falsifiable statement.

Good:

> Every persisted reader ignores the removed field.

Weak:

> The change looks backward compatible.

Prioritize facts that govern trust boundaries, compatibility, data loss,
concurrency, resource lifetime, or externally visible behavior.

### 3. Look beyond symbol references

Trace direct callers, then investigate contracts a code search may not reveal:

- pinned dependency source and local patches;
- serialized data, database schemas, and wire formats;
- consumers in other services, repositories, or languages;
- generated files and build outputs;
- event-loop, teardown, retry, or initialization ordering;
- configuration, feature flags, and deployment sequencing;
- older clients, persisted state, and partial rollouts.

Restrict searches to authorized repositories and systems. A search that found
nothing is useful only when its scope and terms are recorded.

### 4. Separate risks from cleared concerns

For each candidate failure:

- state the exact failure path;
- cite the governing source or observed behavior;
- estimate likelihood and impact using repository context;
- identify the cheapest test that would disprove or confirm it.

Keep confirmed risks. Put investigated and disproved concerns under
**Cleared**. Drop unsupported speculation.

### 5. Prove the safety facts

Run the smallest existing test or write the smallest temporary diagnostic that
calls the same code and contract used in production. Put temporary diagnostics
in the host's session or temporary storage, not the user's repository. Do not
substitute a mock for the behavior under investigation.

Clean up temporary diagnostics when the investigation ends. If a diagnostic
would make a useful tracked regression test, ask before adding it to the
repository. If execution is unsafe, unavailable, or disproportionately
expensive, stop at the strongest lower evidence level and say why.

For a wide investigation, use `dispatching-parallel-agents` only for
independent evidence sources. The parent remains responsible for reconciling
the results and proving the final safety facts.

## Report

Use this structure:

```markdown
## What changes

<Old behavior, new behavior, and non-obvious effects.>

## Safety facts

1. <Falsifiable fact>
   - Evidence level: <1-5>
   - Evidence: <citation, command, or artifact>
   - Status: proven | unproven

## Confirmed risks

- <Failure path, location, likelihood, impact, and verification method>

## Cleared

- <Concern checked and the evidence that cleared it>

## Before merging

<The cheapest remaining test or reproduction that catches the material risk.>
```

If a material safety fact remains unproven, lead with that limitation instead
of presenting an approval verdict.
