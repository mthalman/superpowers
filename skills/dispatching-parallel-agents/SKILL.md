---
name: dispatching-parallel-agents
description: Use when facing 2+ substantial tasks that can run without shared state or sequential dependencies, or when a high-value uncertain task justifies an explicitly bounded race. Covers partition, race, and mixed parallelism; self-contained briefs; isolated writes; and PASS, ISSUES, or BLOCKED result aggregation.
---

# Dispatching Parallel Agents

## Overview

Use isolated agents when 2+ substantial tasks can proceed without shared state
or sequential dependency, or when a high-value uncertain task merits a bounded
race. You construct each worker's context explicitly; workers do not inherit
your session history.

**Core principle:** choose the parallel shape before dispatch, isolate writable
state, and require every worker to report an evidenced outcome.

## When to use

Use when:

- 2+ substantial test files, failures, subsystems, or evidence sources have
  plausibly independent root causes.
- Each slice can be understood from a self-contained brief.
- Workers can run without editing the same paths, sharing mutable resources, or
  requiring each other's discoveries.
- A consequential, uncertain task justifies multiple independent attempts.

Do not use when failures are likely related, one fix may resolve all symptoms,
full-system tracing is required, the work fits in a few direct tool calls, or
workers would interfere through shared state.

## Choose the shape

Declare one shape before launching workers.

### Partition

Give each worker a different independent slice. Use this for coverage across
subsystems, platforms, test files, repositories, or evidence sources. Every
required slice must return a result.

### Race

Give workers the same brief so they produce independent attempts. Use a race
only when duplication is worth the cost because the task is uncertain,
contested, or high risk.

Choose the selection rule before dispatch:

- **first-pass:** accept the first result that satisfies the done predicate.
- **rank-all:** wait for all results and rank them against the same criteria.
- **best-of:** wait for all results, select the strongest base, and synthesize
  compatible improvements.

Do not treat worker agreement as proof. Verify the selected result
independently. Route interface and module design competitions to `arena`.

### Mixed

Partition the task, then race multiple workers on one unusually uncertain or
important slice. State both the coverage slices and the race rule.

## Non-negotiable invariants

- **Self-contained briefs:** include scope, context, constraints, verification,
  and expected output. Do not rely on hidden session history.
- **Isolated writes:** parallel editing requires separate worktrees, output
  paths, or a read-only scope. Never let workers write the same file.
- **Explicit done predicate:** define what counts as done before dispatch.
- **Bounded objective:** each worker gets one concrete scope and a stop point.
- **Evidenced status:** every worker returns `PASS`, `ISSUES`, or `BLOCKED`.
- **Coordinator verification:** integrate and validate results; do not outsource
  the final verdict.

Open `references/agent-briefs.md` when writing worker prompts or examples of
self-contained briefs.

## Dispatch workflow

1. **Identify independent domains.** Group work by root-cause boundary, file,
   subsystem, platform, or evidence source. If boundaries are unclear, trace
   directly until they are.
2. **Select shape.** Choose partition, race, or mixed. Record the race selection
   rule or coverage slices before dispatch.
3. **Write focused briefs.** Each brief names scope, goal, constraints,
   verification command or evidence, writable boundaries, and output contract.
4. **Dispatch together.** Use the host's supported batching or background-agent
   mechanism. If concurrency is unavailable, process slices sequentially and say
   so.
5. **Aggregate results.** Read every returned status and evidence. Identify
   missing slices, conflicts, dropouts, and blockers.
6. **Integrate safely.** Accept compatible partition results, or keep only the
   selected race result plus deliberate synthesis. Discard unselected attempts.
7. **Validate.** Run the smallest integration validation that covers the combined
   changes, escalating when risk or policy requires it.

Open `references/integration-checklist.md` when aggregating worker outputs,
checking coverage, or validating combined changes.

Open `references/anti-patterns.md` when deciding whether not to dispatch, or
when auditing a proposed parallel plan for broad prompts, shared writes, or
undeclared races.

## Output contract

Report one coordinator outcome:

- **PASS:** all required slices returned PASS, integration was validated, and no
  unresolved conflicts or blockers remain.
- **ISSUES:** work produced actionable findings, partial fixes, conflicts, or
  validation failures. Include evidence and next steps.
- **BLOCKED:** a required slice could not proceed. Include the blocker, attempts,
  and evidence needed to continue.

For each worker include: assigned scope, status, evidence, files changed or read
when relevant, validation result, and integration decision.
