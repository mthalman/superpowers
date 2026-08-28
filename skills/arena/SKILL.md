---
name: arena
description: Generate multiple structurally distinct interface or module designs in parallel, compare them against a task-specific rubric, select one coherent base, and graft the strongest compatible ideas from the alternatives. Use when the user wants to design an API, explore module shapes, compare competing interfaces, "design it twice", or put a consequential design decision in the arena. This is design work, not implementation.
---

# Arena

Explore the design space before implementation locks in the first plausible
shape. Produce several complete alternatives, choose one base deliberately,
and integrate only compatible ideas.

## 1. Ground the design problem

Understand:

- the problem and desired outcome;
- callers and common usage;
- required operations and invariants;
- compatibility, performance, and platform constraints;
- what the interface should hide;
- existing repository patterns that constrain the design.

Inspect the relevant code when the repository can answer a question. Ask the
user about product or policy decisions that cannot be inferred safely.

## 2. Write the rubric first

Turn success into three to six task-specific, observable criteria before
generating candidates.

Concrete:

> A caller can stream results without buffering the complete response.

Vague:

> The interface is flexible.

Include general design qualities only where they matter:

- small, comprehensible public surface;
- depth, with substantial complexity hidden behind the interface;
- ease of correct use and resistance to misuse;
- compatibility with established callers and patterns;
- implementation freedom and efficiency;
- future extension without exposing internal rules.

The parent owns the rubric. Do not ask candidate agents to invent different
success criteria.

## 3. Generate distinct candidates

Use `dispatching-parallel-agents` to generate at least three candidates in
parallel when resources allow. If the host has no agent delegation, generate
the candidates sequentially and keep their assumptions separate. Give every
candidate the same requirements and rubric, then assign a different design
pressure to force structural diversity.

Examples:

- minimize concepts and methods;
- optimize the common path;
- maximize extensibility behind a stable boundary;
- use a functional, object-oriented, or data-oriented shape where appropriate.

Each candidate returns:

1. caller usage written before the interface;
2. types, methods, parameters, and module boundaries;
3. what the design hides;
4. how it satisfies each rubric criterion;
5. tradeoffs and failure modes;
6. alternatives considered and rejected.

Do not let candidates edit a shared path. Interface exploration normally needs
no writes. If artifacts are required, give every candidate an isolated output.

## 4. Read and compare

Read every candidate completely. Score each criterion using evidence from the
candidate rather than holistic familiarity.

Look for:

- convergence that indicates a strongly favored shape;
- meaningful differences in ownership, sequencing, or extensibility;
- temporal coupling that forces callers through a fragile call order;
- information leakage about internals;
- pass-through layers that add no abstraction;
- shallow modules with large interfaces and little hidden complexity.

If candidates diverge because they assumed different requirements, the problem
was under-specified. Clarify the requirements and rerun rather than averaging
incompatible designs.

## 5. Select one base

Choose the candidate with the most coherent mental model and the strongest
rubric performance. Prefer the design a future maintainer can extend without
learning hidden rules.

Name the base and explain why it won. The parent makes this judgment. Reviewer
or agent agreement is supporting evidence, not proof.

## 6. Graft selectively

Revisit every losing candidate and identify the small number of ideas worth
bringing into the base.

Re-express each graft within the base design. Do not paste together competing
abstractions or average incompatible interfaces. Reject a graft that makes the
base less coherent even if it was strong in isolation.

Record:

- the source candidate;
- the idea grafted;
- how it changed the base;
- important ideas rejected and why.

Rejection rationale prevents future designers from repeating the same search.

## 7. Present the synthesis

Return:

```markdown
## Rubric

<Task-specific criteria>

## Candidates

<Each design, usage example, and key tradeoffs>

## Selected base

<Chosen design and criterion-by-criterion rationale>

## Grafts

<Imported ideas and their source candidates>

## Rejected ideas

<Material alternatives and why they were not used>

## Final design

<Complete synthesized interface or module design>
```

Stop after the design. Do not implement unless the user separately requests
implementation.
