---
name: svg-generator
description: Use when generating SVG graphics from written descriptions including icons, data visualizations, illustrations, technical diagrams, or any visual content. Emphasizes visual accuracy through planning-first workflows, proper coordinate systems, and expert-level engineering reasoning including alternative exploration, context constraint extraction, and trade-off articulation.
---

# SVG Generator

## Overview

Generate SVG graphics from written descriptions with visual accuracy and
engineering judgment. You may create icons, data visualizations, technical
diagrams, illustrations, or other SVG assets.

**Core rule:** never generate SVG code directly from a description. Plan first,
then generate. The plan must choose a coordinate system, calculate positions and
proportions, mentally sketch the composition, and select the technical approach.

Load supporting skills when the work needs them:

- **superpowers:designing-ui-color** for palette, harmony, luminance, and contrast decisions.
- **superpowers:designing-ui-typography** for text, labels, font choice, and readability.

## When to use this skill

Use this skill for:

- generating simple icons, symbols, and UI glyphs;
- creating charts, graphs, or data-driven SVG graphics;
- drawing flowcharts, architecture diagrams, and technical diagrams;
- building complex scenes, landscapes, objects, or compositions;
- any SVG request where visual accuracy, accessibility, or clean SVG structure matters.

## Step 0: pre-planning assessment

Complete this before choosing a workflow.

### 0A. Classify complexity

State the complexity explicitly.

| Complexity | Criteria | Workflow depth |
|---|---|---|
| **Simple** | Fewer than 5 elements, established metaphor, well-defined parameters | Streamlined decisions, correct proportions, clean code |
| **Moderate** | 5-15 elements, standard requirements with some customization | Standard workflow depth and key trade-offs |
| **Complex** | More than 15 elements, custom composition, conflicts, or special constraints | Full exploration, detailed alternatives, comprehensive verification |

Do not ask the user to choose workflow depth in non-interactive contexts. Make a
reasonable classification and continue.

### 0B. Extract constraints

Convert context into technical requirements before designing. Use this form:

> Because [context], we must [constraint].

Examples:

- Because mobile toolbar, we must work in monochrome with `currentColor`.
- Because hero image with text overlay, we must control luminance and contrast.
- Because dashboard chart, we must preserve data comparison accuracy.

Reference these constraints in later decisions.

### 0C. Establish trade-off principles

State 2-4 design principles as `X over Y` trade-offs, then use them to resolve
ambiguous choices. Examples: clarity over cleverness, accuracy over aesthetics,
comprehension over completeness, inclusivity over optimization.

## Workflow decision tree

```text
User requests SVG generation?
│
├─ Simple icon or symbol (< 10 elements)
│  └─ Use the icon workflow
│
├─ Data visualization (chart, graph)
│  └─ Use the data visualization workflow
│
├─ Technical diagram (flowchart, architecture)
│  └─ Use the technical diagram workflow
│
├─ Complex illustration or scene
│  └─ Use the illustration workflow
│
└─ Unknown or complex requirements
   └─ Start with the illustration workflow
```

## Core workflow

### 1. Select the workflow and reference

Open `references/workflow-icons.md` when creating simple icons or symbols.
Open `references/workflow-data-visualization.md` when creating charts, graphs,
or data-driven graphics. Open `references/workflow-diagrams.md` when creating
flowcharts, architecture diagrams, or process diagrams. Open
`references/workflow-illustrations.md` when creating scenes, landscapes,
objects, or multi-element compositions.

Open `references/svg-reference.md` when you need SVG syntax, viewBox patterns,
basic shapes, paths, gradients, transforms, depth techniques, chart patterns,
diagram patterns, or content-specific shape patterns.

### 2. Plan the SVG

Before writing SVG code, document:

- target use case and constraints;
- chosen viewBox and alternatives considered;
- elements, layers, and grouping;
- coordinates, spacing, proportions, and stroke widths;
- color and typography decisions, using supporting skills when needed;
- assumptions, rationale, risks, and mitigation for ambiguous requirements.

Every non-trivial decision must compare 2-3 alternatives with specific
downsides. Avoid “standard” or “subtle” unless you explain what alternatives
fail and why the chosen option fits the context.

### 3. Generate accessible SVG

Create valid SVG with a clear `viewBox`, organized groups, reusable definitions
when useful, and readable formatting. Include accessibility metadata:

```svg
<svg role="img" aria-labelledby="title desc">
  <title id="title">Descriptive Title</title>
  <desc id="desc">Detailed description of the visual content</desc>
  <!-- SVG content -->
</svg>
```

### 4. Verify against real failure modes

Calibrate verification to complexity. Simple SVGs need a focused visual check;
complex SVGs need comprehensive verification against the request.

Always check:

- elements are not cut off or misaligned;
- proportions and visual hierarchy match the description;
- colors and text meet the context and accessibility requirements;
- data encodings preserve the data truth;
- diagrams preserve the described logic and flow;
- the SVG works in the stated environment, including monochrome or themed contexts when required.

Open `references/quality-checks.md` when you need scenario examples, detailed
best practices, anti-patterns, or the full quality checklist. Open
`references/ambiguity-and-troubleshooting.md` when requirements conflict, the
request is vague, or the generated SVG has visual or technical problems.

## Non-negotiables

- Plan before generating SVG code.
- Extract context into constraints with “Because [context], we must [constraint].”
- State 2-4 trade-off principles for the task.
- Explore alternatives for non-trivial decisions and name accepted downsides.
- Use evidence, conventions, or perceptual thresholds instead of spurious math.
- Justify fractional coordinates; default to integer coordinates for small icons unless stroke alignment requires otherwise.
- Identify and handle data outliers before drawing charts.
- For text overlays, analyze luminance and WCAG contrast, not just color mood.
- Make ambiguity explicit with assumptions, rationale, risk, and mitigation.
- Verify the output against real failure modes, not process theater.

## Success contract

A successful SVG response includes:

- a concise plan with complexity, constraints, trade-off principles, alternatives, and key coordinates;
- actual SVG code or files, not only a description;
- accessible `<title>` and `<desc>` metadata;
- validation notes tied to the task’s real risks;
- clear mention of any assumptions that may need later adjustment.
