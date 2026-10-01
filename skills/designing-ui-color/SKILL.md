---
name: designing-ui-color
description: Use when selecting colors for interfaces, evaluating color combinations, creating palettes, resolving stakeholder color conflicts, or when colors "feel wrong" but you can't articulate why - provides expert color theory, perceptual principles, and systematic palette creation beyond basic accessibility
---

# Designing UI Color

## Overview

Color design applies perceptual science to create functional, harmonious, and contextually appropriate color systems. Accessibility and meaning come before aesthetics.

## When to Use

Use when selecting or evaluating color combinations, creating palettes or design systems, resolving stakeholder color pressure, designing beyond basic contrast ratios, choosing between valid options, or explaining why colors work or clash.

Do not use for pure WCAG audits, color naming or hex conversion, or print color systems such as CMYK and Pantone.

## Priority Hierarchy

Justify color choices in this order:

1. **Accessibility:** contrast ratios, colorblind safety, readable states.
2. **Semantics:** established UI conventions and traffic-light patterns.
3. **Brand consistency:** existing style guide and recognition.
4. **Perceptual effects:** vibration, simultaneous contrast, temperature, saturation balance.
5. **Aesthetic harmony:** only after functional requirements pass.

Avoid unsupported color psychology. Use measurable mechanisms, established conventions, or cited research with effect sizes. Do not claim that a hue universally creates trust, luxury, action, or emotion.

## Context Decision

First classify the color problem:

- **UI interface:** readability, usability, state clarity, low distraction, and accessible contrast are primary.
- **Brand or marketing:** recognition, differentiation, and consistency matter more, but text still needs accessibility where it is used for reading.
- **Data visualization:** distinguishability, colorblind-safe palettes, perceptual uniformity, and pattern recognition are primary.

Open `references/context-specific-color.md` when you need detailed UI, brand, or data-viz rules or the decision framework.

## Core Workflow

1. **Identify context and constraints.** Name whether this is UI, brand, data visualization, or a mixed case. Collect existing brand colors, accessibility requirements, target backgrounds, modes, and stakeholder constraints.
2. **Check accessibility first.** Verify contrast for the actual text size and weight. Ensure critical meaning is never conveyed by color alone; add labels, icons, shape, position, or patterns.
3. **Test colors in context.** Evaluate colors against actual backgrounds, neighboring colors, real content, light/dark modes, and colorblind simulations. Do not judge swatches in isolation.
4. **Analyze harmony and perception.** Look for saturation imbalance, simultaneous contrast, warm/cool visual depth, and full-saturation complementary vibration. Open `references/color-harmony.md` when diagnosing clash, harmony, vibration, temperature, or contrast effects.
5. **Generate multiple options.** Produce at least three approaches with explicit trade-offs: minimal fix, balanced improvement, and comprehensive solution. Do not default to a full design system when a targeted fix solves the problem.
6. **Build or adjust the palette systematically.** Use tonal scales, semantic colors, and context-specific palettes rather than random hex choices. Open `references/palette-generation.md` when creating tonal scales, semantic assignments, complementary/analogous colors, or evidence-based rationale.
7. **Defend the recommendation.** Explain the business or product impact using objective standards and the chosen priority hierarchy. Open `references/stakeholder-color-workflow.md` when responding to problematic stakeholder requests or preparing comparison options.
8. **Review for implementation risks.** Open `references/color-review.md` when checking color models, common mistakes, tools, real-world impact language, or final review points.

## Non-Negotiables

- Never use color alone to convey critical meaning.
- Never approve a palette before checking contrast in the actual UI context.
- Never apply one palette unchanged across UI, brand, and data visualization without verifying the different goals.
- Never use unsupported color-psychology claims as evidence.
- Always account for colorblind users when colors distinguish categories, states, or data series.
- Always generate multiple viable options before recommending one direction.
- Prefer the simplest color solution that satisfies accessibility, semantics, brand, perception, and maintainability.

## Output Contract

When recommending or reviewing colors, include:

- context classification: UI, brand, data visualization, or mixed;
- accessibility status and any colorblind-safety concerns;
- candidate options with trade-offs;
- final recommendation with objective rationale;
- implementation notes for states, backgrounds, and non-color cues;
- validation steps performed or still needed.
