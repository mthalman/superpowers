# Checklists and Pitfalls

This reference covers the detailed workflow checklist, success criteria, common mistakes, red flags, rationalizations, and integration notes.

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
