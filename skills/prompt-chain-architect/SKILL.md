---
name: prompt-chain-architect
description: Use when tasks require multiple steps, need human decisions mid-workflow, exceed single context window, or have validation requirements - designs reliable multi-step AI workflows with explicit input/output contracts, context compression, and validation gates. Benefits include reduced context bloat, systematic validation between steps, clear error recovery, and ability to resume interrupted work.
---

# Prompt Chain Architect

## Overview

**Multi-step AI workflows fail without explicit chain design.** This skill teaches how to orchestrate complex tasks as chains with clear inputs, outputs, validation gates, and context management.

**Core principle:** Describing phases ≠ designing chains. Chains have explicit input/output contracts, validation gates, context extraction, and error recovery.

## When to Use This Skill

Use when tasks have ANY of these characteristics:
- **Multiple perspectives needed** (analyze → design → implement)
- **Human decisions mid-workflow** (get approval before proceeding)
- **Context exceeds single window** (can't fit all information in one prompt)
- **Validation requirements** (check quality before next step)
- **Investigation required** (reproduce → trace → hypothesize → fix)

**Don't use for:**
- Single-shot tasks with obvious implementation
- Simple clarification questions
- Straightforward bug fixes with clear solution

## Chain Design Process

### Step 1: Decompose Into Chain Steps

**Not phases. Chain steps with explicit contracts.**

**Example: Vague phases vs explicit chain contracts**
```
❌ BAD: Vague phases
Phase 1: Analyze codebase
Phase 2: Design solution
Phase 3: Implement

✅ GOOD: Chain with contracts
Step 1: Analyze codebase
  Input: User requirements
  Output: { current_auth: "none", db: "postgresql", files: [...] }

Step 2: Design solution options
  Input: Structured findings from Step 1
  Output: { options: [{approach, pros, cons}], recommendation }

Step 3: Get human decision
  Input: Options from Step 2
  Output: { chosen_approach, constraints }

Step 4: Implement
  Input: Decision from Step 3, findings from Step 1
  Output: Code changes
```

**Each step must specify:**
1. What it consumes (input)
2. What it produces (output)
3. What format (structured data preferred)

### Step 2: Design Context Extraction

**Problem:** Step 1 produces 50KB analysis. Step 2 can't consume all of it.

**Solution: Extract structured data.**

**Example: Context bloat vs structured extraction**
```
❌ BAD: Pass raw output forward
Step 1 output: [Long prose analysis of codebase architecture,
  file-by-file review, detailed observations...]
Step 2 input: [All 50KB from Step 1]

✅ GOOD: Extract structured findings
Step 1 output (compressed):
{
  "current_state": "no authentication",
  "database": "postgresql with sequelize",
  "session_mgmt": "express-session already installed",
  "relevant_files": ["src/server.js", "src/models/User.js"],
  "constraints": ["must work with existing sessions"]
}

Step 2 input: This 200-byte JSON (not 50KB prose)
```

**Context compression strategies:**
- **Structured extraction**: Convert findings to JSON/tables
- **Summarization**: Key points only, discard exploration
- **Reference by location**: "See findings in file X" instead of repeating

### Step 3: Design Validation Gates

**Validation gates check quality before proceeding.**

**Example: Validation gate with error recovery**
```
After Step 2 (Design solution):
✓ Check: Does design reference actual files from codebase?
✓ Check: Are security requirements addressed?
✓ Check: Is approach compatible with constraints?

If NO → Retry Step 2 with specific feedback
If YES → Proceed to Step 3
```

**Validation gate checklist for each step:**
1. What could go wrong in this step?
2. How do I detect if it went wrong?
3. What do I do if validation fails? (Retry? Abort? Alternative path?)

### Step 4: Plan Human Checkpoints

**When to pause for human decision:**
- Multiple valid approaches with significant tradeoffs
- Architectural decisions (auth method, database schema, API design)
- Scope clarification (priorities, constraints)
- Risk acceptance (breaking changes, security tradeoffs)

**Use AskUserQuestion for checkpoints:**

**Example: Human checkpoint for architectural decision**
```
After Step 2 (Analysis complete):
"I've identified 3 approaches for authentication:

A) JWT with Redis session store
   ✓ Stateless, scalable
   ✗ Requires Redis setup

B) OAuth2 with third-party
   ✓ No credential management
   ✗ External dependency

C) Session-based with existing express-session
   ✓ Minimal changes
   ✗ Less scalable

Which approach fits your needs?"

[PAUSE - Get human decision]

Step 3 continues with chosen approach
```

### Step 5: Track Chain State

**Use TodoWrite to track chain progress:**

**Example: TodoWrite for chain state tracking**
```
TodoWrite todos:
[
  { content: "Analyze existing auth patterns", status: "completed" },
  { content: "Design auth options with tradeoffs", status: "completed" },
  { content: "Get user decision on approach", status: "in_progress" },
  { content: "Implement chosen auth method", status: "pending" },
  { content: "Validate security requirements", status: "pending" }
]
```

**Benefits:**
- User sees progress
- Can resume if interrupted
- Clear what's done vs pending

## Common Chain Patterns

### Pattern 1: Research → Decide → Execute

**Use when:** Requirements clear but approach needs decision

**Example: Research → Decide → Execute chain pattern**
```
Step 1: Analyze current state
  Output: Structured findings

Step 2: Generate options with tradeoffs
  Input: Findings
  Output: { options: [...], recommendation }

Step 3: Human decision
  Input: Options
  Output: { chosen_option, rationale }

Step 4: Execute
  Input: Decision + findings
  Output: Implementation

Step 5: Validate
  Input: Implementation
  Output: Verification results
```

### Pattern 2: Investigate → Hypothesize → Validate → Fix

**Use when:** Debugging, root cause analysis

**Example: Investigation chain for debugging**
```
Step 1: Reproduce & gather evidence
  Output: { symptoms, logs, patterns }

Step 2: Form hypotheses
  Input: Evidence
  Output: { hypotheses: [{cause, likelihood, test}] }

Step 3: Test hypotheses
  Input: Hypotheses
  Output: { confirmed_hypothesis, evidence }

Step 4: Implement fix
  Input: Confirmed hypothesis
  Output: Code changes

Step 5: Verify fix
  Input: Changes
  Output: Validation results
```

### Pattern 3: Clarify → Plan → Execute

**Use when:** Requirements vague or ambiguous

**Example: Clarification chain for vague requirements**
```
Step 1: Ask clarifying questions
  Output: { requirements, constraints, priorities }

Step 2: Design approach
  Input: Requirements
  Output: { plan, steps, validation_criteria }

Step 3: Get approval
  Input: Plan
  Output: { approved: true/false, modifications }

Step 4: Execute plan
  Input: Approved plan
  Output: Implementation

Step 5: Validate against criteria
  Input: Implementation + validation_criteria
  Output: Results
```

## Error Recovery Patterns

### When Validation Fails

**Example: Validation failure recovery**
```
Step 3 validation failed:
  → Check: Is failure recoverable?
     YES → Retry Step 3 with specific feedback
     NO  → Backtrack to Step 2, redesign
```

### When Step Produces Poor Output

**Example: Quality recovery pattern**
```
Step 2 output quality too low:
  → Add explicit quality requirements
  → Retry with refined prompt
  → If 2nd attempt fails, reconsider decomposition
```

### When Context Overflows

**Example: Context overflow recovery**
```
Step 1 produced too much context:
  → Apply compression (extract structured data)
  → Split step into sub-steps
  → Use files to store intermediate results
```

## Red Flags - You're Not Designing Chains

- Describing "phases" without input/output contracts
- Passing entire outputs forward without extraction
- No explicit validation gates
- Not using TodoWrite to track chain state
- Vague about what each step consumes/produces
- No plan for error recovery
- Missing human checkpoints for decisions

**If you catch yourself doing these:** Stop. Design the chain explicitly.

## Chain vs Single-Shot Decision

| Use Chain When | Use Single-Shot When |
|----------------|---------------------|
| Multiple perspectives needed | Clear implementation path |
| Human decision required | No ambiguity |
| Context exceeds window | Fits in context |
| Validation critical | Simple verification |
| Investigation required | Known solution |

**When unsure:** Design the chain. Overhead is small, benefits are large.

## Implementation Checklist

When using this skill:

- [ ] Identified chain steps (not just phases)
- [ ] Designed input/output contracts for each step
- [ ] Planned context extraction between steps
- [ ] Created validation gates with error recovery
- [ ] Identified human checkpoint locations
- [ ] Created TodoWrite todos for chain steps
- [ ] Documented what each step consumes/produces

## Example: Adding Authentication (Full Chain)

```
User request: "Add authentication to my app"

Chain Design:

Step 1: Analyze current state
  Input: Codebase
  Actions: Search for existing auth, db, session handling
  Output: {
    current_auth: "none",
    database: "postgresql",
    session_library: "express-session installed",
    relevant_files: ["src/server.js"]
  }
  Validation: Found DB and session library

Step 2: Design options
  Input: Structured findings from Step 1
  Actions: Generate 3 approaches with tradeoffs
  Output: {
    options: [
      {approach: "JWT + Redis", pros: [...], cons: [...]},
      {approach: "OAuth2", pros: [...], cons: [...]},
      {approach: "Session-based", pros: [...], cons: [...]}
    ],
    recommendation: "Session-based (builds on existing)"
  }
  Validation: Each option has concrete pros/cons

Step 3: Human checkpoint
  Input: Options from Step 2
  Actions: Use AskUserQuestion
  Output: { chosen: "Session-based", constraints: ["must support 2FA later"] }
  Validation: Got explicit decision

Step 4: Implement
  Input: Decision from Step 3 + findings from Step 1
  Actions: Write auth middleware, routes, tests
  Output: Code changes
  Validation: Tests pass, security checks pass

Step 5: Security review
  Input: Implementation
  Actions: Check for common vulnerabilities
  Output: { secure: true, issues: [] }
  Validation: No critical issues

TodoWrite tracking:
[
  {content: "Analyze current auth setup", status: "completed"},
  {content: "Design auth options", status: "completed"},
  {content: "Get user decision on approach", status: "completed"},
  {content: "Implement session-based auth", status: "completed"},
  {content: "Security review implementation", status: "completed"}
]
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Phase 1, Phase 2, Phase 3" without contracts | Define input/output for each |
| Passing 50KB prose between steps | Extract structured data |
| No validation gates | Add explicit quality checks |
| Skipping human checkpoints | Pause for decisions |
| Not tracking with TodoWrite | Create todos for chain steps |
| Vague about what steps consume/produce | Be explicit about data formats |

## The Bottom Line

**Chains are a design pattern, not just a sequence of steps.**

Good chain design means:
1. Explicit input/output contracts
2. Context extraction between steps
3. Validation gates with error recovery
4. Human checkpoints for decisions
5. State tracking with TodoWrite

When you design chains this way, complex multi-step tasks become reliable and maintainable.
