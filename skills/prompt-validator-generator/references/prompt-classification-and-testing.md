# Prompt Classification and Testing Design

This reference covers prompt type classification and choosing the comparison methodology that will later prove the validator works.

## Phase 2: Prompt Type Classification (MANDATORY)

**Determine what type of prompt you're validating:**

Classify from the prompt's primary objective and expected outcome, not its wording, sections, or internal criteria. If this metadata is unavailable or ambiguous, ask for clarification rather than guessing.

### 2.1 Prompt Type Taxonomy

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

### 2.2 Type-Specific Validation Approaches

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

## Phase 4: Design Testing Methodology

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
