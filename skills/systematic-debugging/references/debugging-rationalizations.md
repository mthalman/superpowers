# Debugging Rationalizations

This reference covers common excuses, human-partner warning signals, phase success criteria, environmental cases, and impact data.

## Human Partner Signals You're Doing It Wrong

Watch for these redirections:

- "Is that not happening?" - You assumed without verifying.
- "Will it show us...?" - You should have added evidence gathering.
- "Stop guessing" - You're proposing fixes without understanding.
- "Ultra-think this" - Question fundamentals, not just symptoms.
- "We're stuck?" (frustrated) - Your approach isn't working.

When you see these, stop and return to Phase 1.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is faster than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms is not understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures means architectural problem. Question pattern, don't fix again. |

## Architecture Problem Signals

Pattern indicating architectural problem:

- Each fix reveals new shared state/coupling/problem in different place.
- Fixes require "massive refactoring" to implement.
- Each fix creates new symptoms elsewhere.

Stop and question fundamentals:

- Is this pattern fundamentally sound?
- Are we "sticking with it through sheer inertia"?
- Should we refactor architecture vs. continue fixing symptoms?

Discuss with your human partner before attempting more fixes. This is NOT a failed hypothesis - this is a wrong architecture.

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand what failed and why |
| **2. Pattern** | Find working examples, compare | Identify relevant differences |
| **3. Hypothesis** | Form theory, test minimally | Hypothesis confirmed or replaced |
| **4. Implementation** | Create test, fix, verify | Bug resolved and tests pass |

## When Process Reveals "No Root Cause"

If systematic investigation reveals the issue is truly environmental,
timing-dependent, or external:

1. Complete the process.
2. Document what you investigated.
3. Implement appropriate handling such as retry, timeout, or clearer error.
4. Add monitoring or logging for future investigation.

But 95% of "no root cause" cases are incomplete investigation.

## Real-World Impact

From debugging sessions:

- Systematic approach: 15-30 minutes to fix.
- Random fixes approach: 2-3 hours of thrashing.
- First-time fix rate: 95% vs 40%.
- New bugs introduced: near zero vs common.
