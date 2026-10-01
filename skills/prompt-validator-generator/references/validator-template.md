# Validator Template

This reference covers the complete validator structure, required dimensions, scoring, anti-patterns, and Phase 5 gate.

## Phase 5: Generate Complete Validator (MANDATORY)

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

### 5.1 Validator Structure Template

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

## Domain-Specific Dimensions (3-7 dimensions)

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

## Universal Quality Dimensions (2-3 dimensions)

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

### 5.2 Critical Requirements

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

### 5.3 Validation Check Before Proceeding

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
