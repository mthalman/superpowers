---
name: prompt-validator-generator
description: Use when needing to create validators for LLM prompts in a specific domain - provides systematic process for analyzing domain expertise, classifying prompt types, and generating domain-specific validation frameworks that check for expert-level effectiveness, not just coverage
---

# LLM Prompt Validator Generator

## Overview

**Generate domain-specific LLM prompt validators through systematic analysis, not ad-hoc checklisting.**

**Core principle:** Validators must check whether prompts transfer expert behavior, not just cover domain topics.

## When to Use

**Use when:**
- Creating validators for prompts in any specific domain: teaching, medical advice, legal analysis, product recommendations, creative writing, financial planning, debugging, API design, and similar domains
- Evaluating whether prompts are expert-level rather than novice-level
- Building prompt quality frameworks for a domain

**Don't use when:**
- Evaluating one prompt directly
- The domain is too broad and needs sharper focus
- Validating non-prompt artifacts such as documents, products, or designs

## Execution Method: Use Subagents (MANDATORY)

**This skill REQUIRES subagent-based execution to prevent circular validation.**

Three-agent architecture:

1. **Main agent identifies domain.** Read the target prompt only enough to name the domain. Do not analyze the domain yet.
2. **Subagent 1 creates the validator.** Launch a subagent with only the domain name: `Create a validator for [domain name] prompts. Complete Phases 1-5 of the prompt-validator-generator skill.`
3. **Subagent 2 meta-validates.** After Subagent 1 returns the validator, launch another subagent with the validator plus the target and test prompts: `Here's a [domain] validator: [paste validator]. Test it on these prompts: [target prompt + test prompts]. Complete Phase 6 of the prompt-validator-generator skill.`

**CRITICAL: Do NOT pass the target prompt to Subagent 1. Pass ONLY the domain name.** Subagent 1 must base the validator on domain expertise, not the prompt's structure.

Subagent 1 returns a complete validator document after Phases 1-5. Subagent 2 applies it, checks false positives and negatives, calibrates it, and returns validation results plus a refined validator.

Single-agent execution is not recommended because it creates high circular-validation risk. Use it only if subagents are unavailable, and preserve the same separation: identify domain, set the prompt aside, analyze the domain independently, then test afterward.

## Non-Negotiable Circular-Validation Rule

**Do not base validator dimensions on what the prompt being validated contains.** The validator checks whether prompts enable expert behavior, not whether they resemble the example prompt.

Correct sequence:

1. Look at the prompt only to identify the domain.
2. Set the prompt aside.
3. Analyze expert behavior and failure modes in that domain independently.
4. Build the validator from domain expertise.
5. Test the original prompt and other prompts with the finished validator.

Red flags:

- "This prompt has X, so validators should check for X"
- "Let me look at the prompt to see what dimensions to create"
- Validator dimensions matching the prompt's sections
- Expert behavior inferred from one prompt's contents
- Validator works on the example but poorly on structurally different prompts

Open `references/checklists-and-pitfalls.md` when checking for detailed circular-validation mistakes, rationalizations, red flags, and final readiness criteria.

## Six-Phase Workflow

Complete all phases in order. Do not generate the validator until Phase 5. Document each phase.

### Phase 1: Domain Analysis

Analyze the domain independently before validating any prompt. Identify expert-versus-novice patterns, common failure modes, and domain-specific versus universal concerns.

Open `references/domain-analysis-and-expertise.md` when identifying expert behavior, novice failures, domain-specific concerns, tacit knowledge, context factors, or expert validation methods.

### Phase 2: Prompt Type Classification

Classify the prompt's primary type because type determines validation focus. Common types include enforcement, guidance/advisory, diagnostic, analytical, evaluative, generative/creative, synthesis, planning/strategic, transformation, explanation/teaching, procedural, and interactive/conversational.

Open `references/prompt-classification-and-testing.md` when choosing a prompt type, defining a custom type, or selecting type-specific validation criteria.

### Phase 3: Capture Domain Expertise

For each likely evaluation dimension, document the expert behavior it checks, the tacit knowledge it must make explicit, relevant context factors, and how experts validate effectiveness.

Open `references/domain-analysis-and-expertise.md` when turning domain analysis into concrete dimensions, heuristics, context variables, and ground-truth methods.

### Phase 4: Design Testing Methodology

Plan how you will prove the validator works before writing it. Choose with/without, expert/novice, scenario-based, agent-based, or a custom comparison. Define baseline, ground truth, and what result would prove the validator detects quality gaps rather than coverage.

Open `references/prompt-classification-and-testing.md` when designing meta-validation comparisons, baselines, and proof criteria.

### Phase 5: Generate Complete Validator

Now create the validator, incorporating Phases 1-4. Include a domain analysis summary, prompt type classification, validation approach, 3-7 domain-specific dimensions, 2-3 universal quality dimensions, scoring methodology, anti-patterns, and a meta-validation plan.

The validator must check behavior, include tacit knowledge, be domain-specific, match the prompt type, have observable criteria, include anti-patterns, and be testable by the Phase 4 methodology.

Open `references/validator-template.md` when writing the validator structure, dimensions, scoring criteria, anti-patterns, or Phase 5 gate.

### Phase 6: Meta-Validation and Refinement

Test the validator using the Phase 4 methodology. Apply it to strong and weak examples, check whether bad coverage-only prompts can pass, check whether unconventional good prompts can fail, calibrate against ground truth where possible, then refine.

Open `references/meta-validation.md` when executing tests, checking false positives or false negatives, calibrating against expert judgment, or finalizing the validator.

## Output Contract

Return a complete validator package with:

1. Domain analysis summary
2. Prompt type classification and validation approach
3. Evaluation dimensions with weights, expert-behavior rationale, score bands, red flags, and context factors
4. Scoring methodology, thresholds, and any critical dimensions
5. Anti-patterns drawn from domain failure modes
6. Meta-validation plan and results
7. Final calibration notes and known limits

When showing process, include enough Phase 1-6 evidence to prove the validator was not derived from the target prompt.

## Short Checklist

- [ ] Subagent 1 received only the domain, not the target prompt
- [ ] Phase 1 domain analysis happened before validator generation
- [ ] Phase 2 type classification shaped the validation approach
- [ ] Phase 3 made tacit expert knowledge explicit
- [ ] Phase 4 defined a comparison that can prove effectiveness
- [ ] Phase 5 dimensions check expert behavior, not topic coverage
- [ ] Phase 6 tested strong, weak, false-negative, and false-positive cases
- [ ] Final validator is calibrated and usable by someone else

## Examples and References

Open `references/examples.md` when you need worked examples for software debugging, mathematics teaching, or financial advising validators.
