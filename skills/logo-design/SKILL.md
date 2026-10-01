---
name: logo-design
description: Use when designing logos, creating brand marks, or helping with visual identity work - provides expert logo design process including discovery, strategic positioning, validation testing, and delivery of production-ready designs using SVG
---

# Logo Design

## Overview

You can and should design logos. Create actual production-ready logo files, not
just recommendations or descriptions.

Use this workflow to design logos, brand marks, wordmarks, combination marks,
rebrands, visual identity symbols, and improved versions of existing marks.

**Supporting skills (load exact names when needed):**

- **superpowers:designing-ui-color** for all color selection, palettes, color psychology, and contrast validation.
- **superpowers:designing-ui-typography** for wordmarks, font choice, readability, and licensing trade-offs.
- **superpowers:svg-generator** for creating production-ready SVG logo files.

**Critical:** every logo direction must include actual working SVG files created
with `superpowers:svg-generator`, actual colors selected with
`superpowers:designing-ui-color`, and actual fonts chosen with
`superpowers:designing-ui-typography` when typography is involved.

## When to use

Use this skill when the user requests logo design, rebranding, a brand mark,
visual identity work, logo evaluation, logo improvement, or a brand icon.

## Non-negotiable discovery gate

Never jump straight to designing. Ask discovery questions first, even when the
user says not to ask questions, the deadline is tight, or they say you are the
expert. Minimum viable discovery beats no discovery.

Ask at least three questions covering:

1. **Business context:** what the company does, target audience, competitors, and what is unique.
2. **Brand positioning:** personality, desired emotional response, industry norms, and whether to conform or break them.
3. **Practical constraints:** where the logo appears, size range, color limits, accessibility needs, and implementation constraints.

If the user cannot answer, help them think it through. Do not replace discovery
with undocumented or “strategic” assumptions.

Open `references/discovery-and-positioning.md` when you need the full discovery
question set, competitive visual analysis process, or constraint filters for
budget, licensing, implementation, and positioning.

## Six-step workflow

### 1. Conduct strategic discovery

Gather enough context to prevent designing blind. Identify target audience,
competitors, unique value, brand personality, desired emotion, practical uses,
size range, and color or implementation constraints.

### 2. Perform competitive visual analysis

Identify 3-5 direct competitors and map their colors, style, and logo types.
Find an unclaimed positioning gap and explain how the logo will signal
difference without becoming inappropriate for the industry.

### 3. Create three strategic directions

Create exactly three strategic directions, not three cosmetic variations. Each
direction must represent a different positioning strategy and include an actual
working SVG file.

For each direction:

- design the icon, wordmark, or combination concept;
- use **superpowers:svg-generator** to create the SVG file;
- use **superpowers:designing-ui-color** to select actual colors;
- use **superpowers:designing-ui-typography** to choose fonts when text is involved;
- document rationale, rejected alternatives, and trade-offs.

Open `references/directions-and-tradeoffs.md` when defining the three
directions, quantifying trade-offs, or documenting alternatives you rejected.

### 4. Validate each mark

Before delivery, verify each direction:

- remains recognizable at 16x16px;
- works in monochrome as solid black;
- has sufficient contrast, using **superpowers:designing-ui-color**;
- exports cleanly as SVG, using **superpowers:svg-generator**;
- has readable typography at all sizes, using **superpowers:designing-ui-typography** for wordmarks;
- avoids obvious visual similarity or trademark-risk patterns;
- communicates a clear strategic rationale.

Open `references/logo-principles-and-validation.md` when you need the full logo
principles, validation checklist, or guidance for handling user pressure.

### 5. Deliver production files and usage guidance

Deliver actual files, not descriptions. Required deliverables:

1. full-color SVG;
2. monochrome solid-black SVG;
3. simplified favicon or small-size SVG;
4. usage guidance covering minimum size, clear space, and implementation notes.

Open `references/supporting-skills-and-delivery.md` when selecting colors,
choosing type, creating SVG deliverables, or preparing the full delivery set.

### 6. Explain implementation and success checks

When useful for DIY users or small teams, include a timeboxed implementation
plan. Explain observable success checks across short, medium, and long horizons.

Open `references/implementation-and-success.md` when the user needs rollout
steps, time estimates, or success metrics. Open `references/pressure-patterns.md`
when the conversation includes rushed decisions, “include everything,” “make it
like this famous logo,” “just give options,” or other rationalizations that risk
weak logo work.

## Minimum output contract

A complete logo-design response includes:

- the discovery answers or the questions still needed;
- competitive positioning insight and the visual gap;
- three strategic logo directions with actual SVG files;
- selected colors and fonts, including supporting skill rationale;
- validation results for monochrome and 16x16px use;
- trade-offs and rejected alternatives;
- final usage guidance and next steps.

## Red flags: stop and correct course

- Designing without asking discovery questions.
- Presenting only one direction.
- Presenting descriptions instead of actual SVG files.
- Skipping **superpowers:svg-generator** for logo files.
- Skipping **superpowers:designing-ui-color** for color selection.
- Skipping **superpowers:designing-ui-typography** when a wordmark or text is involved.
- Using literal, clichéd interpretation without strategic exploration.
- Not testing at 16x16px and monochrome.
- Creating a complex gradient-heavy mark that cannot survive small sizes.
- Refusing the task by claiming you are not a designer.
