---
name: prompt-validator-generator
description: Use when needing to create validators for LLM prompts in a specific domain - provides systematic process for analyzing domain expertise, classifying prompt types, and generating domain-specific validation frameworks that check for expert-level effectiveness, not just coverage
---

# LLM Prompt Validator Generator

## Overview

**Generate domain-specific LLM prompt validators through systematic analysis, not ad-hoc checklisting.**

**Core principle:** Validators must check whether prompts transfer expert behavior, not just cover domain topics.

## Quick Reference

**Execution:** Use subagent architecture (see "Execution Method" section below)
- Main agent: Identifies domain only
- Subagent 1: Creates validator (Phases 1-5) - never sees target prompt
- Subagent 2: Tests validator (Phase 6) - receives target prompt

**6-Phase Process (Complete ALL phases IN ORDER):**
1. **Domain Analysis:** Expert vs novice patterns, failure modes, domain-specific concerns
2. **Prompt Type:** Classify (Enforcement/Guidance/Diagnostic/etc.) → determines approach
3. **Domain Expertise:** Capture tacit knowledge, heuristics, context factors, validation methodology
4. **Testing Design:** Plan how you'll meta-validate (with/without, agent-based, etc.)
5. **Generate Validator:** Create complete validator incorporating Phases 1-4
6. **Meta-Validation:** Test validator, refine based on results, finalize

**Don't skip phases. Don't generate validator until Phase 5. Document each phase.**

## When to Use

**Use when:**
- Creating validators for prompts in ANY specific domain (teaching, medical advice, legal analysis, product recommendations, creative writing, financial planning, debugging, API design, etc.)
- Need to evaluate whether prompts are expert-level vs novice-level
- Building prompt quality frameworks for a domain

**Don't use when:**
- Evaluating a single prompt (just evaluate it directly)
- Domain is too broad (need sharper focus)
- Validating non-prompt artifacts (documents, products, designs)

## Execution Method: Use Subagents (MANDATORY)

**This skill REQUIRES subagent-based execution to prevent circular validation.**

**Three-Agent Architecture:**

**Step 1: Main Agent identifies domain**
- Read the target prompt
- Identify domain only (e.g., "test-driven development", "financial advising")
- Do NOT analyze domain yet

**Step 2: Launch Subagent 1 for Validator Creation (Phases 1-5)**

Use the Task tool to launch a subagent:
```
Task tool parameters:
- subagent_type: "general-purpose"
- prompt: "Create a validator for [domain name] prompts. Complete Phases 1-5 of the prompt-validator-generator skill."
- description: "Create validator for [domain]"
```

**CRITICAL: Do NOT pass the target prompt to Subagent 1. Pass ONLY the domain name.**

Subagent 1 will:
- Complete Phase 1: Domain Analysis (based on expertise, not prompt structure)
- Complete Phase 2: Prompt Type Classification
- Complete Phase 3: Capture Domain Expertise
- Complete Phase 4: Design Testing Methodology
- Complete Phase 5: Generate Complete Validator
- Return: Complete validator document

**Step 3: Launch Subagent 2 for Meta-Validation (Phase 6)**

After receiving validator from Subagent 1, launch another subagent:
```
Task tool parameters:
- subagent_type: "general-purpose"
- prompt: "Here's a [domain] validator: [paste validator]. Test it on these prompts: [target prompt + test prompts]. Complete Phase 6 of the prompt-validator-generator skill."
- description: "Meta-validate [domain] validator"
```

**NOW you can pass the target prompt to Subagent 2 for testing.**

Subagent 2 will:
- Apply validator to test prompts
- Check for false positives/negatives
- Calibrate and refine
- Return: Validation results and refined validator

**Why this architecture is mandatory:**
- Subagent 1 CANNOT see target prompt = structurally prevents circular validation
- Validator based purely on domain expertise
- Subagent 2 can safely use target prompt for testing (after validator is created)

**Single-agent execution NOT RECOMMENDED:**
- High risk of circular validation
- Requires perfect agent discipline
- Only use if subagents unavailable

## Systematic Process

### Phase 1: Domain Analysis (MANDATORY)

**CRITICAL: Do NOT look at the prompt you're validating yet. Analyze the DOMAIN independently first.**

**Common failure:** Looking at a prompt and basing validator on "what does this prompt contain?" This creates circular validation where the prompt defines its own success criteria.

**Correct approach:** Analyze expert behavior in the domain FIRST, independently of any specific prompt. The validator checks if prompts enable expert behavior, not if prompts match an example.

**Note:** If you're executing this skill via subagent (as recommended above), you won't have access to the target prompt during this phase - which is exactly the point.

**Before creating validator, analyze the domain:**

#### 1.1 Identify Domain Expertise Patterns

**Question:** What do experts do naturally in this domain that novices don't?

**IMPORTANT: Answer based on domain knowledge, NOT by looking at prompts you're validating.**

**Wrong approach:**
- ❌ "This prompt mentions X, Y, Z, so experts must do X, Y, Z"
- ❌ "The prompt has these sections, so I'll validate for those sections"
- ❌ "This prompt works, so I'll check if other prompts are similar"

**Right approach:**
- ✓ "In debugging, experts form hypotheses before trying fixes" (domain knowledge)
- ✓ "Math teachers use multiple representations adaptively" (pedagogical expertise)
- ✓ "Financial advisors assess emotional AND financial risk capacity" (professional standard)

**Analyze:**
- **Behavioral patterns**: What actions do experts take?
- **Mental models**: How do experts think about problems?
- **Heuristics**: What instincts and rules-of-thumb matter?
- **Context sensitivity**: When do experts adapt their approach?

**Sources for this analysis:**
- Your domain expertise
- Domain literature and research
- Expert interviews or observation
- Professional standards and best practices
- **NOT: The specific prompt you're validating**

**Examples across domains:**

*Software debugging:*
```
Experts: Investigate root cause, form hypotheses, add instrumentation
Novices: Jump to solutions, try random fixes, no stopping criteria
```

*Teaching mathematics:*
```
Experts: Connect concepts to prior knowledge, use multiple representations, diagnose misconceptions
Novices: Show procedures without conceptual links, single approach, assume understanding
```

*Financial advising:*
```
Experts: Assess risk tolerance, consider tax implications, integrate estate planning, adapt to life changes
Novices: Focus on returns only, ignore taxes/estate, one-size-fits-all approach
```

*Medical diagnosis:*
```
Experts: Differential diagnosis, probabilistic reasoning, consider comorbidities, update based on tests
Novices: Pattern match to common conditions, binary thinking, ignore context
```

#### 1.2 Map Common Failure Modes

**Question:** What goes wrong when non-experts work in this domain?

**Categories:**
- **Process failures**: Skipping critical steps
- **Judgment failures**: Poor prioritization or decisions
- **Knowledge gaps**: Missing domain-specific concerns
- **Rationalization patterns**: Excuses for shortcuts

**Examples across domains:**

*Software (TDD):*
```
- Writing code before tests ("too simple to test")
- Testing after implementation ("achieves same goals")
```

*Teaching (mathematics):*
```
- Teaching procedures without concepts ("they just need the formula")
- Skipping prerequisite checks ("they should know this")
```

*Financial advising:*
```
- Recommending products without risk assessment ("high returns are good")
- Ignoring client's emotional relationship with money
```

*Medical diagnosis:*
```
- Anchoring on first impression ("it's probably just X")
- Ordering tests before clinical reasoning ("let's see what shows up")
```

#### 1.3 Determine Domain-Specific vs Universal Concerns

**Domain-specific** (unique to this domain):
- Software debugging: Root-cause investigation, hypothesis testing
- Mathematics teaching: Multiple representations, misconception diagnosis
- Financial advising: Risk-return trade-offs, tax efficiency
- Medical diagnosis: Differential diagnosis, probabilistic reasoning
- Creative writing: Show-don't-tell, character development, pacing
- Legal analysis: Precedent research, statutory interpretation, fact patterns

**Universal** (apply to all domains):
- Clear, actionable guidance
- Concrete examples
- Context-appropriate advice
- Anti-patterns and red flags
- Progressive skill development

**The validator must check BOTH.**

### Phase 2: Prompt Type Classification (MANDATORY)

**Determine what type of prompt you're validating:**

#### 2.1 Prompt Type Taxonomy

**Note:** Prompts often combine multiple types. Identify the PRIMARY type to guide validation focus.

| Type | Purpose | Validation Focus | Examples |
|------|---------|------------------|----------|
| **Enforcement** | Make violations costly, prevent shortcuts | Will they follow discipline under pressure? | TDD, safety protocols, compliance |
| **Guidance/Advisory** | Help with judgment and complex decisions | Will they make expert-level choices? | Investment allocation, teaching strategy, legal strategy |
| **Diagnostic** | Identify problems and root causes | Will they diagnose accurately? | Medical diagnosis, debugging, troubleshooting |
| **Analytical** | Break down and examine information | Will they analyze deeply/systematically? | Argument analysis, data interpretation |
| **Evaluative** | Judge quality against standards | Will they assess accurately? | Code review, essay grading, evaluation |
| **Generative/Creative** | Create original content | Will they produce quality output? | Story writing, design, composition |
| **Synthesis** | Combine multiple sources coherently | Will they integrate effectively? | Research synthesis, lit reviews |
| **Planning/Strategic** | Develop actionable plans | Will they create realistic plans? | Project planning, strategic planning |
| **Transformation** | Convert between formats/forms | Will they transform accurately? | Translation, summarization, conversion |
| **Explanation/Teaching** | Build understanding and mental models | Will they grasp and explain concepts? | Math concepts, theory, principles |
| **Procedural** | Provide step-by-step instructions | Will they follow steps correctly? | Recipes, tutorials, protocols |
| **Interactive/Conversational** | Guide ongoing dialogue | Will they conduct effective conversations? | Tutoring, coaching, customer service |

**If your prompt doesn't fit:** Define custom type by answering:
1. What is the primary purpose of this prompt?
2. What is the core success criterion?
3. What expert behavior must it enable?

#### 2.2 Type-Specific Validation Approaches

**Core validation approaches by type:**

**Enforcement:** Check for explicit requirements (MUST/MANDATORY), rationalization prevention, consequences for violations, red flags

**Guidance/Advisory:** Check for trade-off frameworks, context-adaptation guidance, decision-making support, tacit knowledge capture

**Diagnostic:** Check for systematic investigation process, differential consideration, evidence requirements, stopping criteria

**Analytical:** Check for framework/methodology, depth vs surface distinction, logical rigor, assumption identification

**Evaluative:** Check for clear criteria, severity/priority guidance, bias prevention, actionable feedback structure

**Generative/Creative:** Check for quality standards, creativity constraints, style/voice guidance, iteration/refinement process

**Synthesis:** Check for integration methodology, source evaluation, coherence standards, citation/attribution guidance

**Planning/Strategic:** Check for goal-to-task decomposition, risk consideration, resource allocation, timeline realism, contingency planning

**Transformation:** Check for accuracy verification, semantic preservation, format requirements, edge case handling

**Explanation/Teaching:** Check for mental models, concrete examples, conceptual accuracy, progressive complexity, misconception prevention

**Procedural:** Check for step completeness, prerequisite clarity, error recovery, verification checkpoints

**Interactive/Conversational:** Check for context tracking, turn-taking guidance, empathy/tone calibration, goal orientation

### Phase 3: Capture Domain Expertise

**Before generating the validator, capture the expertise that will fill it.**

**DO NOT generate the validator yet. Phase 5 will do that. This phase PREPARES the expertise.**

**For each evaluation dimension from Phase 1, document:**

#### 3.1 What Expert Behavior Does This Check?

**Software examples:**
- Bad: "Does the prompt cover error handling?"
- Good: "Does the prompt guide defensive error handling at system boundaries, trusting internal code?"

**Teaching examples:**
- Bad: "Does the prompt mention multiple methods?"
- Good: "Does the prompt guide selecting representations based on student's current understanding?"

**Financial examples:**
- Bad: "Does the prompt mention risk?"
- Good: "Does the prompt guide risk assessment through client's emotional and financial capacity?"

**Medical examples:**
- Bad: "Does the prompt cover diagnosis?"
- Good: "Does the prompt guide probabilistic reasoning across differential diagnoses?"

#### 3.2 What Tacit Knowledge Must Be Explicit?

**Examples across domains:**
- Software debugging: "3+ failed fixes = question architecture, not persistence"
- Mathematics teaching: "Student errors reveal misconceptions, not stupidity"
- Financial advising: "Behavior gaps cost more than fee differences"
- Medical diagnosis: "Common things are common, but rare things happen"
- Creative writing: "Conflict drives story; description provides rest"
- Legal analysis: "Facts matter more than eloquence in trial"

#### 3.3 What Context Factors Matter?

**Examples across domains:**
- Software: Emergency vs routine, critical vs experimental, internal vs public
- Teaching: Grade level, prior knowledge, learning disabilities, class size
- Financial: Age, risk tolerance, life stage, liquidity needs, tax situation
- Medical: Acute vs chronic, emergency vs routine, patient age/comorbidities
- Legal: Jurisdiction, case type (civil/criminal), client resources, stakes
- Creative writing: Genre, audience age, publication venue, series vs standalone

#### 3.4 What Validation Methodology Do Experts Use?

**Question:** How do domain experts validate effectiveness? How do they establish ground truth?

**Critical for meta-validation design:** This determines HOW you'll test your validator.

**Ask yourself:**
- How do experts in this domain measure quality?
- What comparison mechanisms exist? (baseline, control group, benchmark)
- How do they establish "correct" or "expert-level"?
- What methodology reveals quality gaps vs just compliance?

**Examples across domains:**

*Software debugging:*
```
Experts compare: Systematic investigation vs random fixes
Methodology: Track hypothesis count, fix attempts, root cause identification
Ground truth: Did they find actual root cause vs symptom fix?
```

*Mathematics teaching:*
```
Experts compare: Conceptual understanding vs procedural fluency
Methodology: Student explanation quality, transfer to new problems
Ground truth: Can students explain WHY, not just HOW?
```

*Financial advising:*
```
Experts compare: Personalized advice vs generic recommendations
Methodology: Risk-return alignment, tax efficiency, behavioral coaching quality
Ground truth: Would expert advisor give same recommendation?
```

*Skill quality (meta):*
```
Experts compare: Skill-guided output vs expert output (no skill)
Methodology: Agent A (expert), Agent B (skill-guided), Agent C (analyzer)
Ground truth: Does skill-guided output match expert-level output?
```

**Why this matters:**
- Your validator needs to TEST for effectiveness, not just coverage
- The methodology you identify here becomes Phase 6 meta-validation approach
- Comparison mechanisms (with/without, expert/novice, baseline/treatment) are key

**Document:**
- What comparison would prove prompts are effective in this domain?
- What baseline or ground truth exists?
- How would experts test if a prompt works?

### Phase 4: Design Testing Methodology

**Before generating the validator, plan how you'll test it.**

**Critical questions to answer:**
- How will I know if this validator actually works?
- What's my baseline for "correct" validation?
- What comparison methodology will prove the validator is effective?

**Based on Phase 3.4 (domain validation methodology), determine:**

**What comparison will prove your validator works?**

**Common approaches:**

**A. With/Without Comparison** (most common):
- Test prompts WITH the feature you're validating
- Test prompts WITHOUT the feature
- Validator should distinguish between them

**B. Expert/Novice Comparison:**
- Test expert-level prompts (should PASS)
- Test novice-level prompts (should FAIL)
- Validator should discriminate correctly

**C. Scenario-Based Testing:**
- Create scenarios that require domain expertise
- Test prompts across scenarios
- Validator should detect context-inappropriate prompts

**D. Agent-Based Comparison** (for prompts guiding agent behavior):
- Agent A: Expert baseline (no prompt, pure expertise)
- Agent B: Prompt-guided (with prompt being validated)
- Agent C: Analyzer (compares outputs, identifies gaps)
- Validator should detect when prompt doesn't transfer expertise

**Choose methodology based on:**
- What experts use in this domain (from 3.4)
- What would prove prompts are effective
- What reveals quality gaps vs just compliance

**Example for skill quality domain:**
```
Methodology: Agent-based comparison
- Agent A: Expert skill writer (no framework)
- Agent B: Using prompt-validator-generator skill
- Agent C: Compare outputs for quality, systematic process
Proves: Skill transfers systematic process for validator creation
```

**Document your chosen methodology:**
- Which approach (A/B/C/D or custom)?
- What comparison proves validator effectiveness?
- What's your baseline/ground truth?
- How will you know validator works?

### Phase 5: Generate Complete Validator (MANDATORY)

**NOW generate your validator, incorporating ALL previous phases.**

**CRITICAL: This is where validator creation happens. Not before.**

**Your validator must incorporate:**
- **From Phase 1:** Domain analysis (expert patterns, failure modes, domain-specific concerns)
- **From Phase 2:** Prompt type classification and appropriate validation approach
- **From Phase 3:** Domain expertise (expert behavior, tacit knowledge, context factors, validation methodology)
- **From Phase 4:** Testing methodology (how you'll meta-validate)

**IMPORTANT: Phase 4 methodology should SHAPE your validator design:**

- **If Phase 4 chose With/Without Comparison:**
  - Ensure dimensions detect presence/absence of features
  - Criteria distinguish prompts WITH feature from those WITHOUT
  - Example: "Rationalization Prevention" dimension detects when prompts prevent vs allow shortcuts

- **If Phase 4 chose Expert/Novice Comparison:**
  - Ensure scoring clearly separates expertise levels
  - Strong (4.5-5.0) criteria = expert behavior, Poor (1.0-2.4) = novice behavior
  - Example: "Risk Assessment" dimension scores expert holistic assessment high, novice returns-only approach low

- **If Phase 4 chose Scenario-Based Testing:**
  - Ensure dimensions include context factors from Phase 3.3
  - Criteria adapt to different scenarios
  - Example: "Context Adaptation" dimension checks if prompts guide different approaches for different contexts

- **If Phase 4 chose Agent-Based Comparison:**
  - Ensure criteria evaluate behavioral outputs, not just prompt contents
  - Dimensions check if prompts enable expert-level behavior when executed
  - Example: "Systematic Process" dimension evaluates whether prompted agent follows systematic investigation

**Your validator isn't just documented with the methodology - it's DESIGNED to be tested by it.**

#### 5.1 Validator Structure Template

**Create validator with this structure:**

```markdown
# [Domain] Prompt Validator

## Domain Analysis Summary
[Phase 1 output: Expert patterns, failure modes, domain-specific vs universal concerns]

## Prompt Type Classification
[Phase 2 output: Type from taxonomy, validation focus]

## Validation Approach
[Why this approach based on prompt type]

## Evaluation Dimensions

### Domain-Specific Dimensions (3-7 dimensions)

**Dimension 1: [Name] ([Weight]%)**

**What expert behavior:** [From Phase 3.1]

**Evaluation criteria:**
- **Strong (4.5-5.0):** [Detailed criteria incorporating tacit knowledge from Phase 3.2]
- **Adequate (3.5-4.4):** [Criteria]
- **Weak (2.5-3.4):** [Criteria]
- **Poor (1.0-2.4):** [Criteria]

**Red flags:** [Anti-patterns from Phase 1.2]

**Context factors:** [From Phase 3.3]

[Repeat for each domain dimension]

### Universal Quality Dimensions (2-3 dimensions)

**Dimension X: Actionability**
[Standard universal dimension]

**Dimension Y: Context Adaptation**
[Standard universal dimension]

## Scoring Methodology

**Weights:**
- Domain dimensions: [weights from Phase 3]
- Universal dimensions: [weights]

**Thresholds:**
- Expert-level: ≥ [threshold from Phase 2 approach]
- Critical dimensions: [any must-exceed thresholds]

## Anti-Patterns
[From Phase 1.2 - common failure modes as checklist]

## Meta-Validation Plan
[From Phase 4 - how you'll test this validator]
```

#### 5.2 Critical Requirements

**Your validator MUST:**

1. **Check behavior, not coverage**: Every dimension validates expert behavior or judgment, not topic mentions

2. **Include tacit knowledge**: Make implicit expert knowledge explicit in evaluation criteria

3. **Be domain-specific**: 3-7 dimensions unique to this domain based on Phase 1 analysis

4. **Be type-appropriate**: Validation approach matches prompt type from Phase 2

5. **Have clear criteria**: Each score level (5.0, 4.0, 3.0, 2.0, 1.0) has specific, observable criteria

6. **Include anti-patterns**: Common failure modes from Phase 1.2 as red flags

7. **Be testable**: Can be applied consistently using methodology from Phase 4, with dimensions and criteria specifically designed to support that testing approach

**Don't create validator that:**
- Checks for topic coverage instead of expert behavior
- Uses generic criteria that could apply to any domain
- Missing tacit knowledge from Phase 3.2
- Ignores context factors from Phase 3.3
- Can't be tested with Phase 4 methodology (dimensions don't support the comparison approach)
- Dimensions designed generically that work with any testing approach (indicates misalignment with Phase 4 methodology)

#### 5.3 Validation Check Before Proceeding

**GATE: Cannot proceed to Phase 5 until Phase 4 is complete with documented testing methodology.**

**Before moving to Phase 6, verify:**

- [ ] Validator incorporates Phase 1 domain analysis
- [ ] Validator uses Phase 2 type-appropriate approach
- [ ] Each dimension based on expert behavior from Phase 3.1
- [ ] Tacit knowledge from Phase 3.2 is explicit in criteria
- [ ] Context factors from Phase 3.3 are included
- [ ] Testing methodology from Phase 4 is documented
- [ ] **Dimensions and criteria DESIGNED to support Phase 4 testing approach** (not just documented)
- [ ] Anti-patterns from Phase 1.2 are red flags
- [ ] Validator checks behavior, not coverage
- [ ] Criteria are specific and observable
- [ ] Can be tested with methodology from Phase 4 (dimensions enable the comparison approach)

**If any checkbox is unchecked, fix before Phase 6.**

### Phase 6: Meta-Validation and Refinement (MANDATORY)

**Test your validator using the methodology designed in Phase 4.**

#### 6.1 Execute Testing Methodology

**Apply the methodology you designed in Phase 4:**

If you chose:
- **With/Without:** Test prompts with and without the feature
- **Expert/Novice:** Test expert and novice-level prompts
- **Scenario-Based:** Test across multiple scenarios
- **Agent-Based:** Run Agent A, Agent B, Agent C comparison

**Document results:**
- What tests did you run?
- Did validator distinguish correctly?
- Any unexpected passes/fails?

#### 6.2 Test with Known Examples

**Strong prompt test:**
- Take an expert-level prompt in the domain
- Run your validator
- Should PASS with high scores (≥4.0)
- If it fails, your validator is too strict or checks wrong things

**Weak prompt test:**
- Take a novice-level prompt in the domain
- Run your validator
- Should FAIL or score low (≤2.5)
- If it passes, your validator misses critical gaps

**Document both tests:**
- Which prompts did you use?
- What scores did they get?
- Did results match expectations?

#### 6.3 Check for False Negatives

**Can a bad prompt pass your validation?**

Test by creating prompt that:
- Covers all topics (content complete)
- But missing expert judgment/behavior
- Should FAIL validation

If it passes → validator checks coverage, not effectiveness

**Example test prompt:**
"[Create a coverage-only prompt for your domain that lists all relevant topics but provides no expert guidance on when/how/why to apply them]"

#### 6.4 Check for False Positives

**Can a good prompt fail your validation?**

Test with prompt that:
- Transfers expert behavior
- But structured differently than expected
- Should PASS validation

If it fails → validator too rigid or structural

**Example test prompt:**
"[Take an unconventional but effective prompt that achieves expert-level results through different structure or approach]"

#### 6.5 Calibration Against Ground Truth

**If possible, compare validator results against domain expert judgment:**

**Process:**
1. Select 5-10 prompts of varying quality
2. Have domain expert rate them (without validator)
3. Run prompts through your validator
4. Compare: Do validator scores correlate with expert ratings?

**Correlation check:**
- High correlation (>0.8): Validator captures expert judgment ✓
- Moderate correlation (0.5-0.8): Validator partially aligned, refine dimensions
- Low correlation (<0.5): Validator checks wrong things, restart Phase 1

**If expert judgment unavailable:**
- Use your own expertise (document assumptions)
- Use established examples from domain literature
- Use comparison methodology from 5.1 (with/without, expert/novice)

**Document:**
- What ground truth did you use?
- How well does validator align?
- What refinements are needed?

## Workflow Checklist

**Use TodoWrite to track these steps:**

- [ ] **Phase 1**: Complete domain analysis
  - [ ] Identify expert vs novice patterns
  - [ ] Map common failure modes
  - [ ] Determine domain-specific vs universal concerns

- [ ] **Phase 2**: Classify prompt type
  - [ ] Determine enforcement/guidance/explanation/etc from taxonomy
  - [ ] Select appropriate validation approach

- [ ] **Phase 3**: Capture domain expertise
  - [ ] For each dimension, identify expert behavior
  - [ ] Make tacit knowledge explicit
  - [ ] Identify context factors
  - [ ] Determine validation methodology experts use (3.4)

- [ ] **Phase 4**: Design testing methodology
  - [ ] Choose approach: with/without, expert/novice, scenario-based, or agent-based
  - [ ] Document what comparison proves validator effectiveness
  - [ ] Define baseline/ground truth
  - [ ] Plan how you'll know validator works

- [ ] **Phase 5**: Generate complete validator
  - [ ] Create validator structure incorporating Phases 1-4
  - [ ] Include domain-specific dimensions (3-7)
  - [ ] Add universal quality dimensions (2-3)
  - [ ] Define scoring methodology
  - [ ] Write anti-patterns section
  - [ ] Document meta-validation plan
  - [ ] Verify all Phase 5.3 checkboxes before proceeding

- [ ] **Phase 6**: Meta-validate and refine
  - [ ] Execute testing methodology from Phase 4
  - [ ] Test with strong example prompt (should pass)
  - [ ] Test with weak example prompt (should fail)
  - [ ] Check for false negatives (bad passing)
  - [ ] Check for false positives (good failing)
  - [ ] Calibrate against ground truth if available (6.5)
  - [ ] Refine based on calibration results
  - [ ] Finalize validator

## Success Criteria

**Your validator is ready when:**
- Passes strong example prompts (≥4.0)
- Fails weak example prompts (≤2.5)
- Checks expert behavior, not just coverage
- Includes domain-specific and universal dimensions
- Has clear, specific evaluation criteria
- Calibrated against known examples
- Can be applied consistently by others

## Common Mistakes

### Mistake 0: Circular Validation (MOST CRITICAL)

**Problem:** Basing validator on what the prompt you're validating contains

**How it happens:**
1. Look at prompt to be validated
2. Extract its contents/structure
3. Create validator checking for those contents
4. Prompt passes validation (circular!)

**Why it's wrong:**
- Validator becomes "does this match the example?" not "does this enable expert behavior?"
- Any prompt similar to the example passes, even if ineffective
- Structurally different but effective prompts fail
- You're validating form, not function

**Example of circular validation:**
```
❌ Wrong sequence:
1. Look at TDD prompt
2. See it has "Write test first" section
3. Create validator dimension "Has 'write test first' section"
4. TDD prompt passes (because we based validator on it)
5. Other prompts fail even if they enforce test-first differently

This validates structure, not behavior.
```

**Correct sequence:**
```
✓ Right sequence:
1. Analyze TDD domain: Experts write tests before code
2. Identify failure mode: Developers rationalize skipping tests
3. Create dimension: "Does prompt ENFORCE test-first with consequences?"
4. Test TDD prompt: Does it prevent writing code before tests?
5. Test any prompt structure: Can detect enforcement regardless of format

This validates behavior, not structure.
```

**Red flags you're doing circular validation:**
- "This prompt has X, so validators should check for X"
- "Let me look at the prompt to see what dimensions to create"
- "The validator dimensions match the prompt's sections"
- Basing expert behavior on what one prompt contains
- Validator works great on the example but poorly on others

**Fix:** Complete Phase 1 domain analysis WITHOUT looking at any prompts. Base dimensions on domain expertise, not prompt contents.

### Mistake 1: Coverage Instead of Effectiveness

**Problem:** Checklist of topics to cover, not behaviors to enforce

**Examples:**

*Software:*
```
Bad: "Does prompt cover security, performance, scalability?"
Good: "Does prompt guide threat modeling at trust boundaries?"
```

*Teaching:*
```
Bad: "Does prompt cover multiplication methods?"
Good: "Does prompt guide method selection based on student understanding?"
```

*Financial:*
```
Bad: "Does prompt mention diversification?"
Good: "Does prompt guide diversification based on risk capacity and timeline?"
```

**Fix:** Every dimension must check for expert behavior or judgment

### Mistake 2: Skipping Domain Analysis

**Problem:** Creating validator without understanding domain expertise

**Symptom:** Generic quality criteria that could apply to any prompt

**Fix:** Complete Phase 1 (Domain Analysis) before writing validator

### Mistake 3: One-Size-Fits-All Scoring

**Problem:** Same scoring approach for all prompt types

**Example:** Using behavioral enforcement criteria for explanation prompts

**Fix:** Adapt scoring to prompt type (Phase 2 classification)

### Mistake 4: Missing Tacit Knowledge Validation

**Problem:** Validating explicit knowledge only

**Example:** Checks for "mentions X" instead of "guides when to apply X vs Y"

**Fix:** Capture expert heuristics and instincts in evaluation criteria

### Mistake 5: No Calibration

**Problem:** Deploying validator without testing it

**Symptom:** Validators that pass everything or fail everything

**Fix:** Phase 6 (Meta-Validation) with known strong/weak examples

## Domain-Specific vs Universal Template

**ALWAYS include:**
1. Domain analysis summary (Phase 1 output)
2. Prompt type classification (Phase 2 output)
3. Validation approach explanation
4. 3-7 domain-specific dimensions
5. 2-3 universal quality dimensions
6. Domain-appropriate scoring methodology
7. Anti-patterns section
8. Meta-validation checks

**ADAPT based on:**
- Prompt type (enforcement/guidance/explanation)
- Domain complexity (more dimensions for complex domains)
- Expertise capture (tacit knowledge specific to domain)
- Context factors (what variables affect approach)

## Red Flags - You're Doing It Wrong

- Creating validator without domain analysis → Coverage checklist, not expertise validation
- Same structure for all domains → Missing domain-specific patterns
- No prompt type classification → Wrong validation approach
- Checking for topic coverage → Not checking for behavior/judgment
- No calibration testing → Validator effectiveness unknown
- Generic criteria only → Missing domain expertise
- Skipping meta-validation → Can't verify validator works

**All of these mean: Go back to Phase 1 and follow the systematic process.**

## Common Rationalizations (Don't Skip the Process!)

| Rationalization | Reality |
|-----------------|---------|
| "I'll base validator dimensions on what this prompt contains" | **CIRCULAR VALIDATION.** Dimensions come from domain expertise, not prompt structure. Identify domain, then analyze independently. |
| "This prompt is good, I'll validate if others match it" | **CIRCULAR VALIDATION.** Validator checks behavior, not structural similarity. One prompt doesn't define success criteria. |
| "I'll extract what this prompt does and check for that" | **CIRCULAR VALIDATION.** Analyze domain independently first. Prompt contents don't define expert behavior. |
| "I already know this domain well" | Your implicit knowledge won't transfer to the validator. Phase 1 makes it explicit. |
| "This prompt type is obvious" | Classification determines validation approach. Phase 2 ensures you choose correctly. |
| "I can do domain analysis mentally" | Undocumented analysis = other validators can't learn from it. Document Phase 1. |
| "Meta-validation takes too long" | 15 minutes of testing prevents deploying broken validators. Phase 6 is mandatory. |
| "The user needs this quickly" | Quick broken validator wastes more time than systematic correct validator. |
| "I'll follow the spirit not letter" | Skipping phases = missing critical elements. Follow the process. |
| "This domain doesn't fit the taxonomy" | Define custom type (instructions in Phase 2.1). Still follow the 6 phases. |
| "I'll use an example as template" | Examples are illustrations, not templates. Each domain needs analysis. |
| "Domain analysis is obvious from prompt type" | Type suggests focus, analysis reveals specifics. Both required. |
| "I can combine phases to save time" | Phases build on each other. Skipping = incomplete validators. |

**All of these mean: Complete all 6 phases in order. The process exists because shortcuts fail.**

**Top 3 are CIRCULAR VALIDATION - the most critical failure mode. Correct sequence:**
1. ✓ Look at prompt → Identify domain ("Oh, this is about debugging")
2. ✓ Set prompt aside → Analyze debugging domain independently (expert patterns, failure modes)
3. ✓ Create validator → Based on domain analysis, not prompt contents
4. ✓ Test prompt → Apply validator to original prompt AND others

## Example 1: Software Debugging Prompt Validator

**Phase 1: Domain Analysis**
```
Expert patterns: Root-cause investigation, hypothesis testing, instrumentation
Failure modes: Random fixes, premature solutions, infinite retries
Domain-specific: Systematic process, rationalization prevention
Universal: Actionability, examples, context adaptation
```

**Phase 2: Prompt Type**
```
Type: Enforcement (prevents shortcuts under pressure)
Focus: Will they investigate before fixing?
```

**Phase 3: Domain Expertise**
```
Expert behavior: Investigate systematically, form hypotheses, gather evidence
Tacit knowledge: "3+ failed fixes = question architecture"
Context factors: Emergency vs routine, critical vs experimental
Validation methodology: Track hypothesis count, root cause identification
```

**Phase 4: Testing Design**
```
Methodology: With/Without comparison
Test prompts WITH systematic investigation enforcement
Test prompts WITHOUT enforcement (random fix approach)
Validator should distinguish between them
```

**Phase 5: Validator Generated**
```
Domain dimensions:
1. Systematic Process Enforcement (25%)
2. Rationalization Prevention (30%)
3. Evidence Gathering (20%)
4. Hypothesis Testing (15%)
5. Handling Uncertainty (10%)

Universal: Actionability, Context Adaptation
Scoring: Weighted, threshold ≥3.5, enforcement ≥4.0
```

## Example 2: Mathematics Teaching Prompt Validator

**Phase 1: Domain Analysis**
```
Expert patterns: Multiple representations, misconception diagnosis, conceptual connections
Failure modes: Procedural only, assumed understanding, single method
Domain-specific: Representation selection, error analysis, conceptual depth
Universal: Clarity, examples, progressive complexity
```

**Phase 2: Prompt Type**
```
Type: Guidance (helps with pedagogical decisions)
Focus: Will they select appropriate teaching strategies?
```

**Phase 3: Domain Expertise**
```
Expert behavior: Select representations based on student understanding
Tacit knowledge: "Student errors reveal misconceptions, not stupidity"
Context factors: Grade level, prior knowledge, learning disabilities
Validation methodology: Student explanation quality, transfer to new problems
```

**Phase 4: Testing Design**
```
Methodology: Expert/Novice comparison
Test expert-level teaching prompts (conceptual + procedural)
Test novice-level prompts (procedural only)
Validator should discriminate correctly
```

**Phase 5: Validator Generated**
```
Domain dimensions:
1. Representation Guidance (25%)
2. Misconception Diagnosis (25%)
3. Conceptual Connection (20%)
4. Differentiation Strategy (15%)
5. Assessment Integration (15%)

Universal: Actionability, Context Adaptation
Scoring: Balanced, threshold ≥4.0
```

## Example 3: Financial Advising Prompt Validator

**Phase 1: Domain Analysis**
```
Expert patterns: Holistic planning, risk-return alignment, behavior coaching, tax integration
Failure modes: Product-focused, returns-only, ignores emotions, forgets taxes
Domain-specific: Risk assessment, tax efficiency, behavior management
Universal: Clarity, examples, context sensitivity
```

**Phase 2: Prompt Type**
```
Type: Guidance (complex judgment decisions)
Focus: Will they make client-appropriate recommendations?
```

**Phase 3: Domain Expertise**
```
Expert behavior: Assess risk through emotional AND financial capacity
Tacit knowledge: "Behavior gaps cost more than fee differences"
Context factors: Age, risk tolerance, life stage, tax situation
Validation methodology: Would expert advisor give same recommendation?
```

**Phase 4: Testing Design**
```
Methodology: Scenario-based testing
Create scenarios: young investor, near-retirement, high net worth
Test prompts across scenarios
Validator should detect context-inappropriate advice
```

**Phase 5: Validator Generated**
```
Domain dimensions:
1. Risk Assessment Depth (25%)
2. Tax Integration (20%)
3. Behavior Coaching (20%)
4. Life Stage Adaptation (20%)
5. Goal Prioritization (15%)

Universal: Actionability, Context Adaptation
Scoring: Balanced, threshold ≥4.0, risk assessment ≥4.5
```

## Integration with Other Skills

**After creating validator, consider:**
- **testing-skills-with-subagents**: Pressure test prompts with validator
- **validating-skill-output-quality**: Quality-validate prompts after pressure testing
- **writing-skills**: Use validator during skill RED-GREEN-REFACTOR cycle

## Bottom Line

**Creating prompt validators IS domain expertise analysis made systematic.**

Don't jump to checklist creation. Follow the process:
1. Analyze domain expertise patterns (Phase 1)
2. Classify prompt type (Phase 2)
3. Capture tacit knowledge (Phase 3)
4. Design testing methodology (Phase 4)
5. Generate complete validator incorporating 1-4 (Phase 5)
6. Meta-validate and calibrate (Phase 6)

The result: Validators that check whether prompts transfer expert behavior, not just cover topics.
