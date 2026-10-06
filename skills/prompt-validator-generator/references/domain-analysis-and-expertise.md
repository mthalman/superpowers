# Domain Analysis and Expertise

This reference covers independent domain analysis and explicit capture of expert behavior, tacit knowledge, context factors, and expert validation methods.

## Phase 1: Domain Analysis (MANDATORY)

**CRITICAL: Do NOT look at the prompt you're validating yet. Analyze the DOMAIN independently first.**

**Common failure:** Looking at a prompt and basing validator on "what does this prompt contain?" This creates circular validation where the prompt defines its own success criteria.

**Correct approach:** Analyze expert behavior in the domain FIRST, independently of any specific prompt. The validator checks if prompts enable expert behavior, not if prompts match an example.

**Note:** If you're executing this skill via subagent (as recommended above), you won't have access to the target prompt during this phase - which is exactly the point.

**Before creating validator, analyze the domain:**

### 1.1 Identify Domain Expertise Patterns

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

### 1.2 Map Common Failure Modes

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

### 1.3 Determine Domain-Specific vs Universal Concerns

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

## Phase 3: Capture Domain Expertise

**Before generating the validator, capture the expertise that will fill it.**

**DO NOT generate the validator yet. Phase 5 will do that. This phase PREPARES the expertise.**

**For each evaluation dimension from Phase 1, document:**

### 3.1 What Expert Behavior Does This Check?

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

### 3.2 What Tacit Knowledge Must Be Explicit?

**Examples across domains:**
- Software debugging: "3+ failed fixes = question architecture, not persistence"
- Mathematics teaching: "Student errors reveal misconceptions, not stupidity"
- Financial advising: "Behavior gaps cost more than fee differences"
- Medical diagnosis: "Common things are common, but rare things happen"
- Creative writing: "Conflict drives story; description provides rest"
- Legal analysis: "Facts matter more than eloquence in trial"

### 3.3 What Context Factors Matter?

**Examples across domains:**
- Software: Emergency vs routine, critical vs experimental, internal vs public
- Teaching: Grade level, prior knowledge, learning disabilities, class size
- Financial: Age, risk tolerance, life stage, liquidity needs, tax situation
- Medical: Acute vs chronic, emergency vs routine, patient age/comorbidities
- Legal: Jurisdiction, case type (civil/criminal), client resources, stakes
- Creative writing: Genre, audience age, publication venue, series vs standalone

### 3.4 What Validation Methodology Do Experts Use?

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
