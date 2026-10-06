---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying
issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom
fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```text
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you have not completed Phase 1, you cannot propose fixes.

## When to Use

Use for any technical issue: test failures, production bugs, unexpected
behavior, performance problems, build failures, and integration issues.

Use this especially when time pressure makes guessing tempting, a quick fix
seems obvious, multiple fixes have already failed, or you do not fully
understand the issue. Do not skip this process because the issue seems simple or
urgent.

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

Before attempting any fix:

1. **Read error messages carefully.** Read stack traces completely and note line
   numbers, file paths, warnings, and error codes.
2. **Reproduce consistently.** Capture exact steps. If it is not reproducible,
   gather more data instead of guessing.
3. **Check recent changes.** Inspect diffs, recent commits, dependencies,
   configuration changes, and environment differences.
4. **Gather evidence across component boundaries.** For multi-component systems,
   instrument each boundary so you can see what data enters, what exits, how
   environment/config propagates, and where state changes.
5. **Trace data flow.** When the error is deep in the call stack, find where the
   bad value originated and fix the source, not the symptom.

Open `references/root-cause-tracing.md` when a bug appears deep in a call stack,
invalid data origin is unclear, or you need to find which test or code path
triggers pollution. Use `scripts/find-polluter.sh` from the skill directory when
that reference calls for bisection.

### Phase 2: Pattern Analysis

Find the pattern before fixing:

1. Locate similar working code in the same codebase.
2. Read reference implementations completely before applying their pattern.
3. List differences between working and broken paths, however small.
4. Identify required dependencies, settings, config, environment, and
   assumptions.

### Phase 3: Hypothesis and Testing

⚠️ **COGNITIVE CHECKPOINT: Before proposing a hypothesis**

You must be able to articulate:

- **WHY** you believe X is the root cause, not a symptom.
- **WHAT** evidence from Phase 1 supports this hypothesis.
- **HOW** your proposed test will confirm or refute this hypothesis.

If you cannot explain this with evidence, return to Phase 1.

Then apply the scientific method: form one specific hypothesis, make the
smallest possible test change, verify the result, and either proceed to Phase 4
or form a new hypothesis. Do not stack fixes.

### Phase 4: Implementation

Fix the root cause, not the symptom:

1. Create the simplest failing test case before fixing.
2. Implement one root-cause fix. No unrelated improvements or bundled
   refactoring.
3. Verify the targeted test passes and no relevant tests broke.
4. If the fix does not work, stop and re-analyze. If three fixes have failed,
   question the architecture before attempting another fix.

Open `references/defense-in-depth.md` when invalid data caused the bug and the
fix needs validation at multiple layers. Open
`references/condition-based-waiting.md` when tests use arbitrary sleeps,
timeouts, or timing guesses; its example helper lives at
`scripts/condition-based-waiting-example.ts`.

## Three-Failed-Fixes Architecture Rule

After three failed fixes, stop treating the situation as a normal bug. Repeated
fixes that reveal new shared state, coupling, or symptoms in different places
indicate a possible architecture problem. Question whether the pattern is sound
and discuss the architecture with your human partner before attempting fix #4.

## Red Flags: Stop and Return to Phase 1

- "Quick fix for now, investigate later."
- "Just try changing X and see if it works."
- "Add multiple changes, run tests."
- "Skip the test, I'll manually verify."
- "It's probably X, let me fix that."
- "I don't fully understand but this might work."
- "Pattern says X but I'll adapt it differently."
- Listing solutions before tracing data flow.
- "One more fix attempt" after two failed fixes.
- Each fix reveals a new problem in a different place.

Open `references/debugging-rationalizations.md` when you need the detailed
rationalization table, human-partner warning signals, quick-reference success
criteria, or guidance for environmental issues.

## Supporting References

- `references/root-cause-tracing.md` traces bugs backward through a call stack to
  find the original trigger.
- `references/defense-in-depth.md` adds validation at multiple layers after the
  root cause is known.
- `references/condition-based-waiting.md` replaces arbitrary timeouts with
  condition polling.
- `references/debugging-rationalizations.md` lists common excuses, partner
  signals, success criteria, and impact data.

## Output Contract

When reporting debugging work, include:

- the reproduced symptom and exact evidence;
- the root cause hypothesis and why evidence supports it;
- the minimal test used to confirm or refute it;
- the fix applied at the source;
- validation results;
- any architecture concern if multiple fixes failed.
