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

Use three agents:

1. The main agent provides metadata: domain, primary objective, audience, and expected outcome. Do not share the prompt's wording or structure. Ask the user if its objective is unclear.
2. Subagent 1 receives only the domain and performs Phase 1.
3. Subagent 2 receives Phase 1's analysis and the metadata, but not the prompt or its structure. It performs Phases 2-5, classifying by objective and outcome and grounding dimensions in domain expertise.
4. Subagent 3 receives the finished validator and target/test prompts, then performs Phase 6.

**CRITICAL: Keep the target prompt from Subagents 1 and 2.** Subagent 1 analyzes the domain independently; Subagent 2 gets only enough abstract metadata to classify purpose. Subagent 3 sees the prompt only after the validator is complete.

Subagent 2 returns the validator after Phases 2-5. Subagent 3 tests and calibrates it, checks false positives and negatives, and returns results plus a refined validator.

If subagents are unavailable, preserve the same separation in a single agent: analyze without prompt context, classify from metadata, create the validator without seeing prompt structure, then test it against the prompts.

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

- [ ] Subagent 1 received only the domain and completed Phase 1
- [ ] Phases 2-5 received abstract task metadata but not the target prompt or its structure
- [ ] Phase 1 domain analysis happened before validator generation
- [ ] Phase 2 type classification shaped the validation approach
- [ ] Phase 3 made tacit expert knowledge explicit
- [ ] Phase 4 defined a comparison that can prove effectiveness
- [ ] Phase 5 dimensions check expert behavior, not topic coverage
- [ ] Phase 6 tested strong, weak, false-negative, and false-positive cases
- [ ] Final validator is calibrated and usable by someone else

## Examples and References

Open `references/examples.md` when you need worked examples for software debugging, mathematics teaching, or financial advising validators.
