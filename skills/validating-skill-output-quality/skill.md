---
name: validating-skill-output-quality
description: Use after pressure testing passes to validate that skills produce expert-level output quality, not just process compliance - uses expert-agent comparison to detect missing tacit knowledge, mechanical application, and quality gaps, generating actionable feedback for skill improvement
---

# Validating Skill Output Quality

## Overview

**Testing-skills-with-subagents validates process compliance under pressure. This skill validates output quality and expertise transfer.**

Agents can follow a skill perfectly but still produce mediocre work if the skill:
- Misses tacit knowledge that experts apply instinctively
- Enables mechanical template application without context adaptation
- Captures WHAT to do but not WHEN, HOW, or WHY

This skill uses expert-agent comparison testing to detect these gaps and generate actionable feedback for skill improvement.

**Core principle:** If skill-guided output quality doesn't match expert-level output quality, the skill is missing expertise.

## When to Use

Use this skill when:
- Agents follow your skill but output lacks sophistication or judgment
- Work is "technically correct" but not actually good
- Solutions feel formulaic or generic across different contexts
- Skills pass pressure testing but real-world results disappoint

Don't use for:
- Pure reference documentation (no expertise to transfer)
- Skills that haven't passed pressure testing yet (fix compliance first)
- Skills where output quality isn't the goal (coordination, project management)

## The Problem This Solves

**Common failure pattern:**
1. Skill passes RED-GREEN-REFACTOR pressure testing ✓
2. Agents resist rationalization under stress ✓
3. Agents follow the process correctly ✓
4. BUT output quality is poor ✗

**Root causes:**
- **Missing tacit knowledge:** Skill captures steps but not expert judgment
- **Template thinking:** Agents apply formulaically without adapting to context
- **No trade-off reasoning:** Decisions appear arbitrary even when correct

**This skill detects these gaps and shows you exactly what to add to your skill.**

## Expert-Agent Comparison Testing

### Core Method

Run identical scenarios through two agents:

**Agent A (Expert Baseline):** No skill, pure domain expertise
- Uses highest-capability model
- Applies expert-level reasoning and judgment
- Shows what quality looks like

**Agent B (Skill-Guided):** With skill being tested
- Same model as Agent A (fair comparison)
- Follows the skill you're validating
- Shows what skill produces

**Agent C (Analyzer):** Compares outputs, identifies gaps
- Generates specific, actionable feedback
- Categories: missing knowledge, mechanical application, quality delta

### What This Reveals

**If Agent B output matches Agent A:** Skill successfully transfers expertise ✓

**If Agent B output is worse than Agent A:** Skill has gaps ✗
- Missing tacit knowledge (what expert considered but skill didn't prompt)
- Mechanical application (template used regardless of context)
- Quality gaps (reasoning depth, trade-off articulation, appropriateness)

## Phase 1: Design Scenario Set

**Create 3-5 scenarios that test context-adaptation:**

### Scenario Design Template

```markdown
## Scenario [N]: [Brief Title]

### Context
[Detailed scenario with all relevant context]
- Domain: [what domain/area]
- Scale: [size/scope indicators]
- Constraints: [time, resources, team]
- Special factors: [anything unusual]

### Task
[Specific task/problem to solve]

### Success Criteria
[What good output looks like - for later comparison]
```

### Scenario Variation Strategy

**Design scenarios to vary along key dimensions:**

1. **Scale variation:** Same problem, different scale
   - Small team vs large organization
   - 100 users vs 1M users
   - Prototype vs production system

2. **Constraint variation:** Same problem, different constraints
   - Tight deadline vs ample time
   - Limited resources vs well-resourced
   - Junior team vs expert team

3. **Context variation:** Same problem, different situation
   - New code vs legacy code
   - High-risk vs low-risk
   - Stable requirements vs exploratory

4. **Edge cases:** Valid but unusual situations
   - Conflicting requirements
   - Incomplete information
   - Exceptional circumstances

**Goal:** If agent applies same solution across all scenarios, reveals mechanical thinking.

**Example for TDD skill:**
- Scenario 1: Implement new feature in mature codebase (baseline)
- Scenario 2: Add capability to legacy code with no tests (scale)
- Scenario 3: Fix critical production bug, customers affected (constraint)
- Scenario 4: Build prototype for user research, may be discarded (context)
- Scenario 5: Refactor complex module, code already exists (edge case)

## Phase 2: Run Expert Baseline (Agent A)

**Create expert baseline for each scenario:**

### Expert Agent Prompt Template

```markdown
You are an expert in [domain with specific expertise areas].

Apply your full expertise to this scenario. Show expert-level thinking:
- What factors would you consider first?
- What trade-offs exist?
- How would different contexts change your approach?
- What alternatives exist and why choose one over another?

Think through your reasoning explicitly before providing recommendation.

Scenario:
[Full scenario context]

Provide your expert analysis and recommendation with complete reasoning.
```

### Capture Expert Baseline

For each scenario, document:
- **What expert considers:** Factors, questions, checks
- **How expert reasons:** Trade-offs, alternatives, principles
- **What expert notices:** Context factors that influence approach
- **How solution varies:** What changes across scenarios

**Store this as the quality target for skill-guided output.**

## Phase 3: Run Skill-Guided Agent (Agent B)

**Test agent with skill being validated:**

### Skill-Guided Agent Prompt Template

```markdown
You have access to: [skill-being-tested]

Scenario:
[Identical scenario context as Agent A]

Apply the skill to address this scenario.
```

### Capture Skill-Guided Output

For each scenario, document:
- Agent's solution/recommendation
- Reasoning provided (or lack thereof)
- Factors mentioned (or omitted)
- Context adaptation (or mechanical application)

## Phase 4: Automated Gap Analysis (Agent C)

**Compare expert vs skill-guided outputs systematically:**

### Gap Analysis Prompt Template

```markdown
You are evaluating skill quality by comparing expert baseline vs skill-guided outputs.

EXPERT OUTPUT (Agent A - what expert-level reasoning looks like):
[Agent A's full response]

SKILL-GUIDED OUTPUT (Agent B - what the skill produced):
[Agent B's full response]

Analyze gaps and generate actionable feedback:

## A. Missing Tacit Knowledge

For each knowledge gap, provide:

### Gap [N]: [Name]
**What expert considered:**
[Quote expert's reasoning verbatim]

**What skill-guided agent did:**
[Quote agent's behavior verbatim]

**Why this matters:**
[Explain impact of missing knowledge]

**Suggested skill improvement:**
[Specific, concrete addition to skill]
- Add principle: [exact wording]
- Add check: [specific prompt]
- Add example: [illustration]

---

## B. Mechanical Application Patterns

For each pattern detected across multiple scenarios:

### Pattern [N]: [Description]
**Scenarios affected:** [list]

**Agent behavior across scenarios:**
[Show same approach used inappropriately]

**Expert behavior across scenarios:**
[Show how expert adapted to context]

**Context factors agent ignored:**
[List factors that should have influenced approach]

**Suggested skill improvement:**
[Specific guidance for context-adaptation]
- Add decision matrix: [when to do what]
- Add context assessment: [factors to check]
- Add examples: [same principle, different contexts]

---

## C. Quality Delta Analysis

Score both outputs on each dimension (0-5 scale):

| Dimension | Expert | Skill | Gap | Status |
|-----------|--------|-------|-----|--------|
| Trade-off articulation | X | Y | Z | PASS/FAIL |
| Context incorporation | X | Y | Z | PASS/FAIL |
| Alternative exploration | X | Y | Z | PASS/FAIL |
| Reasoning depth | X | Y | Z | PASS/FAIL |
| Appropriateness | X | Y | Z | PASS/FAIL |

For each dimension with gap >1, provide:

### Dimension: [Name]

**Expert example:**
[Quote showing expert-level quality]

**Skill-guided example:**
[Quote showing skill-guided quality]

**Quality gap explanation:**
[What makes expert output better, specifically]

**Suggested skill improvement:**
[How to prompt for this quality dimension]

---

## Summary Report

### Overall Assessment
- Scenarios passing quality threshold (gap <1.0): X/Y
- Overall status: PASS / FAIL

### Top 3 Priority Improvements
1. [Highest impact improvement with rationale]
2. [Second priority with rationale]
3. [Third priority with rationale]

### Re-test Criteria
After improvements, success means:
- Quality gap <1.0 on all scenarios
- Context adaptation evident (solutions vary appropriately)
- Trade-off reasoning present (score >3.5 on all scenarios)
- No mechanical application patterns detected
```

## Phase 5: Skill Improvement Loop

**Use generated feedback to improve skill systematically:**

### Improvement Protocol

For each feedback item from gap analysis:

#### 1. Classify Improvement Type

Determine what needs to be added:
- **Missing principle/check:** Expert considers X, skill doesn't prompt for it
- **Context-adaptation guidance:** Need decision matrix or contextual framework
- **Reasoning template:** Need structure for articulating trade-offs
- **Examples:** Need illustration of expert vs novice application

#### 2. Locate Insertion Point

Where in skill does this belong:
- **Core principles section:** Fundamental concepts, when skill applies
- **Process steps:** Specific checks within workflow
- **Examples section:** Concrete illustrations
- **Red flags section:** What mechanical application looks like
- **Context assessment section:** How to recognize when to adapt

#### 3. Draft Specific Addition

Write the actual skill improvement:

**For missing tacit knowledge:**
```markdown
## [Principle Name]

Before [deciding X], always assess [factor Y]:
- If [condition A], then [approach 1] because [reasoning]
- If [condition B], then [approach 2] because [reasoning]

**Why this matters:** [Explain consequences of ignoring this]

**Example - Expert check:**
"I'd first look at [X factor] to determine whether [Y approach] is appropriate here."

**Example - Missing check:**
"Proceeding with [Y approach] without checking [X factor] first."
```

**For mechanical application:**
```markdown
## Context Adaptation: [Domain Area]

The same principles apply differently in different contexts:

| Context | Approach | Rationale |
|---------|----------|-----------|
| [Context A] | [Approach 1] | [Why appropriate here] |
| [Context B] | [Approach 2] | [Why appropriate here] |
| [Context C] | [Approach 3] | [Why appropriate here] |

**Assessment questions:**
- What's the [scale/maturity/constraint] of this situation?
- What [context factors] should influence my approach?

**Red flag:** Applying [approach X] regardless of [context factor Y]
```

**For trade-off reasoning:**
```markdown
## Articulating Trade-offs

For decisions under constraints, explicitly state:

**Template:**
"I'm choosing [X] over [Y] because [context factors]. This trades [cost/downside] for [benefit]. I'm accepting [trade-off] because [reasoning]. If [condition changes], I'd reconsider."

**Good example:**
[Quote expert-level trade-off reasoning]

**Poor example:**
[Quote mechanical/arbitrary decision]

**Why trade-off articulation matters:**
[Explain value of explicit reasoning]
```

#### 4. Re-test Same Scenarios

**After adding improvements:**
- Run Agent B (skill-guided) through same scenarios
- Compare to previous Agent B output (pre-improvement)
- Compare to Agent A baseline (expert target)
- Generate new gap analysis

**Success criteria:**
- Quality gaps reduced (moving toward <1.0)
- New tacit knowledge now present in output
- Context adaptation now observed
- Trade-off reasoning now articulated

#### 5. Iterate Until Bulletproof

**Continue improvement loop until:**
- Quality gap <1.0 on ALL scenarios
- Agent B output matches Agent A quality level
- Context adaptation evident across scenarios
- No mechanical application patterns remain

## Integration with RED-GREEN-REFACTOR

**This skill extends existing testing-skills-with-subagents workflow:**

### Standard Flow (Pressure Testing)
1. **RED:** Test without skill → capture failures
2. **GREEN:** Write skill → verify compliance under pressure
3. **REFACTOR:** Close loopholes → add rationalization counters

### Enhanced Flow (Quality Validation)
1. **RED:** Test without skill → capture failures
2. **GREEN:** Write skill → verify compliance under pressure
3. **VERIFY QUALITY:** Run expert-agent comparison
   - If quality gaps exist → iterate on skill before claiming GREEN
4. **REFACTOR:** Close rationalization loopholes AND tacit knowledge gaps
5. **RE-VERIFY QUALITY:** Confirm gaps closed

### Bulletproof Criteria (Enhanced)
- ✓ Passes pressure testing (existing)
- ✓ Passes conflict test (existing)
- ✓ Passes meta-test (existing)
- ✓ **NEW: Passes quality validation (expert-level output)**
- ✓ **NEW: Passes context adaptation test (varies appropriately)**

## Common Patterns: Tacit Knowledge Gaps

**Patterns frequently missed by skills:**

### Pattern 1: Contextual Applicability
**Expert knows:** When principles apply vs don't apply
**Skill often lacks:** Guidance on context recognition

**Fix:** Add "When This Applies" section with conditions

### Pattern 2: Scale-Appropriate Solutions
**Expert knows:** Solution complexity should match problem scale
**Skill often lacks:** Decision matrix for different scales

**Fix:** Add scaling framework with context-specific approaches

### Pattern 3: Trade-off Consciousness
**Expert knows:** Every decision trades something for something
**Skill often lacks:** Prompts for explicit trade-off articulation

**Fix:** Add trade-off reasoning template and examples

### Pattern 4: Team Capability Assessment
**Expert knows:** Recommend what team can actually maintain
**Skill often lacks:** Prompts to assess operational capability

**Fix:** Add team capability checks before solution recommendations

### Pattern 5: Conditional Principles
**Expert knows:** "Generally X, but when Y, then Z"
**Skill often lacks:** Conditional guidance and exceptions

**Fix:** Add decision trees showing condition-dependent approaches

## Common Patterns: Mechanical Application

**Indicators of template thinking:**

### Indicator 1: No Variation Across Contexts
**Agent output:** Same solution for 5-person startup and 1000-person enterprise
**Fix:** Add context assessment step + decision matrix

### Indicator 2: No Trade-off Discussion
**Agent output:** States conclusion without reasoning
**Fix:** Require explicit trade-off articulation with template

### Indicator 3: Missing "Why" Reasoning
**Agent output:** "Use X because it's good practice"
**Fix:** Add "Why This Matters" sections explaining principles

### Indicator 4: Ignoring Constraints
**Agent output:** Ideal solution regardless of stated constraints
**Fix:** Add constraint assessment + context-appropriate alternatives

### Indicator 5: Over-Engineering for Context
**Agent output:** Enterprise architecture for MVP
**Fix:** Add proportionality principle + scaling examples

## Practical Example: TDD Skill Validation

### Scenario: Legacy Code with No Tests

**Agent A (Expert Baseline):**
```
This is existing, working code without tests. Test-first doesn't apply
here because the design already exists. Instead:

1. Write characterization tests documenting current behavior
2. Use tests to enable safe refactoring (not drive new design)
3. Focus on areas about to change (not comprehensive coverage)

The principle shifts from "tests drive design" to "tests enable change"
in legacy contexts. I'm adapting TDD principles to a context where
design pre-exists.
```

**Agent B (Skill-Guided - BEFORE improvement):**
```
Following TDD principles: Delete the legacy code and rewrite it test-first
to ensure clean design.
```

**Gap Analysis:**
- Missing: Context recognition (legacy vs new code)
- Missing: Principle adaptation (when test-first doesn't apply)
- Mechanical: Applied "write test first" rule rigidly
- Quality gap: Inappropriate recommendation for context

**Skill Improvement:**
```markdown
## When TDD Applies (Context Recognition)

TDD test-first principle serves different purposes in different contexts:

| Context | Approach | Purpose |
|---------|----------|---------|
| New code | Test-first | Tests drive design |
| Legacy working code | Characterization tests | Document behavior |
| Refactoring | Tests around change area | Enable safe changes |
| Prototypes | Minimal tests | Design unstable |
| Production bugs | Fix-first sometimes OK | Customer impact weighs |

**Before applying test-first, assess:**
- Does design already exist? (legacy code)
- Is design stable? (prototype vs production)
- What's the goal? (design vs documentation vs safety)

**Red flag:** "Delete working code to rewrite test-first" for legacy code
**Why:** Wastes working implementation to apply "test-first" where design exists
```

**Agent B (Skill-Guided - AFTER improvement):**
```
This is legacy code that already works. Test-first doesn't apply here
because design pre-exists. Instead, I'll write characterization tests
to document current behavior, then use tests to enable safe refactoring.

Focusing on areas we're about to change, not comprehensive coverage,
because the goal is "enable change safely" not "drive new design."
```

**Result:** Agent B now matches Agent A quality - context adaptation present ✓

## Validation Checklist

Before claiming skill is quality-validated:

### Scenario Design
- [ ] Created 3-5 scenarios covering key context variations
- [ ] Scenarios test scale, constraints, and edge cases
- [ ] Scenarios force context adaptation (not one-size-fits-all)

### Expert Baseline
- [ ] Ran expert agent (Agent A) on all scenarios
- [ ] Captured expert reasoning, factors, trade-offs
- [ ] Documented how expert adapts across contexts
- [ ] Established quality target for each dimension

### Skill Testing
- [ ] Ran skill-guided agent (Agent B) on identical scenarios
- [ ] Used same model as expert agent (fair comparison)
- [ ] Captured complete output for comparison

### Gap Analysis
- [ ] Identified missing tacit knowledge (specific items)
- [ ] Detected mechanical application patterns (across scenarios)
- [ ] Scored quality dimensions (expert vs skill)
- [ ] Generated actionable improvement suggestions

### Skill Improvement
- [ ] Added missing principles/checks from feedback
- [ ] Added context-adaptation guidance where needed
- [ ] Added trade-off reasoning templates/examples
- [ ] Inserted improvements at appropriate skill locations

### Re-testing
- [ ] Re-ran skill-guided agent on same scenarios
- [ ] Verified quality gaps reduced (moving toward <1.0)
- [ ] Confirmed context adaptation now present
- [ ] No mechanical application patterns remain

### Bulletproof Criteria
- [ ] Quality gap <1.0 on all scenarios
- [ ] Agent B output matches Agent A expert level
- [ ] Solutions vary appropriately across contexts
- [ ] Trade-off reasoning score >3.5 on all scenarios
- [ ] Passes both pressure testing AND quality validation

## Success Criteria

**A skill is quality-validated when:**

1. **Expert-level output:** Skill-guided agent produces work comparable to expert baseline
2. **Context adaptation:** Solutions vary appropriately across different scenarios
3. **Trade-off reasoning:** Decisions include explicit trade-off articulation
4. **No mechanical application:** Agent adapts principles, doesn't apply templates
5. **Tacit knowledge present:** Expert checks and considerations now prompted by skill

**Quality validation complements pressure testing:**
- Pressure testing → Process compliance under stress
- Quality validation → Expert-level output quality
- Both together → Bulletproof skill that works under pressure AND produces quality

## Meta: Testing This Skill

**This skill itself should be quality-validated:**

Create scenarios for skill validation:
- Scenario 1: Technical skill with clear tacit knowledge (e.g., TDD)
- Scenario 2: Judgment-heavy skill (e.g., architecture decisions)
- Scenario 3: Process skill with context-dependence (e.g., debugging)

Run expert-agent comparison on this validation skill:
- Does it identify real quality gaps?
- Are improvements actionable?
- Does iteration close gaps?
- Does output quality actually improve?

**If this skill passes its own validation, it's bulletproof.**
