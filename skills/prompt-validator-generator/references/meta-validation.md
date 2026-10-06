# Meta-Validation

This reference covers Phase 6 testing, false-positive and false-negative checks, calibration, and ground-truth comparison.

## Phase 6: Meta-Validation and Refinement (MANDATORY)

**Test your validator using the methodology designed in Phase 4.**

### 6.1 Execute Testing Methodology

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

### 6.2 Test with Known Examples

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

### 6.3 Check for False Negatives

**Can a bad prompt pass your validation?**

Test by creating prompt that:
- Covers all topics (content complete)
- But missing expert judgment/behavior
- Should FAIL validation

If it passes → validator checks coverage, not effectiveness

**Example test prompt:**
"[Create a coverage-only prompt for your domain that lists all relevant topics but provides no expert guidance on when/how/why to apply them]"

### 6.4 Check for False Positives

**Can a good prompt fail your validation?**

Test with prompt that:
- Transfers expert behavior
- But structured differently than expected
- Should PASS validation

If it fails → validator too rigid or structural

**Example test prompt:**
"[Take an unconventional but effective prompt that achieves expert-level results through different structure or approach]"

### 6.5 Calibration Against Ground Truth

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
