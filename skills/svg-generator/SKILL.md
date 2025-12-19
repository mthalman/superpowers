---
name: svg-generator
description: Use when generating SVG graphics from written descriptions including icons, data visualizations, illustrations, technical diagrams, or any visual content. Emphasizes visual accuracy through planning-first workflows, proper coordinate systems, and expert-level engineering reasoning including alternative exploration, context constraint extraction, and trade-off articulation.
---

# SVG Generator

## Overview

This skill provides systematic workflows for generating accurate SVG graphics from textual descriptions. The primary focus is ensuring **visual accuracy** through **expert-level engineering reasoning** - that generated SVGs actually look like what was described, with decisions grounded in explicit trade-off analysis, context constraints, and alternative exploration rather than mechanical template application.

**Supporting skills (load when needed):**
- **superpowers:designing-ui-color**: For color palette selection, harmony, and accessibility validation
- **superpowers:designing-ui-typography**: For text/font selection in SVGs with labels or typography

## When to Use This Skill

Use this skill when:

- **Generating icons** - Creating simple graphics like checkmarks, arrows, menu icons
- **Creating data visualizations** - Producing charts, graphs, or diagrams from data
- **Building illustrations** - Crafting complex scenes like landscapes, objects, or compositions
- **Drawing technical diagrams** - Designing flowcharts, architecture diagrams, or system diagrams
- **Any SVG generation request** - Whenever visual accuracy matters

## Core Principle: Plan Before Generating

**CRITICAL:** Never generate SVG code directly from a description. Always plan first.

The planning phase ensures:
1. Appropriate coordinate system is chosen
2. Element positions and proportions are calculated
3. Visual composition is mentally sketched
4. Technical approach is determined

This prevents misaligned, disproportionate, or inaccurate graphics.

## Step 0: Pre-Planning Assessment (Required Before Workflow)

Before executing any workflow, complete these three critical steps:

### 0A. Task Complexity Calibration

**Classify the task complexity to determine appropriate workflow depth:**

| Complexity | Criteria | Workflow Approach |
|------------|----------|-------------------|
| **SIMPLE** | • <5 elements<br>• Established metaphor (search icon, checkmark, arrow)<br>• Well-defined parameters | • Streamlined: 1-2 paragraphs per decision<br>• Focus: correct proportions, clean code<br>• Skip: exhaustive checklists, lengthy verification |
| **MODERATE** | • 5-15 elements<br>• Standard requirements with some customization<br>• Typical use cases | • Standard workflow depth<br>• Balance detail with efficiency<br>• Focus on key decisions |
| **COMPLEX** | • >15 elements<br>• Custom illustrations or novel compositions<br>• Conflicting requirements<br>• Special constraints (accessibility, text overlay) | • Full workflow with deep exploration<br>• Detailed alternative analysis<br>• Comprehensive verification<br>• Multiple iterations expected |

**Current task classification:** [Determine from request and state explicitly]

**If unsure, ask the user:** "Should I provide streamlined analysis for a simple task, or comprehensive exploration for a complex requirement?"

### 0B. Context Analysis: Extract Constraints

**From the stated use case, extract functional requirements BEFORE making technical decisions.**

Use this template:

**Platform constraints** → Technical requirements
- Example: "mobile app" → Touch targets ≥44×44px (iOS), ≥48×48px (Material)
- Example: "print materials" → CMYK-safe colors, 300 DPI considerations

**Visual environment** → Design requirements
- Example: "toolbar icon" → Must work in monochrome, needs consistent optical weight
- Example: "hero image" → Must support text overlay, requires specific luminance values

**User interaction** → Functional requirements
- Example: "search icon" → Must be recognizable within 100ms glance time
- Example: "data dashboard" → Must enable quick value comparison

**FORMAT REQUIREMENT:** "Because [context], we must [constraint]"

✓ Good: "Because mobile toolbar, must work in monochrome with currentColor"
✗ Bad: "This is for a mobile toolbar" (no extracted constraint)

**Reference these constraints throughout your technical decisions.**

### 0C. Design Philosophy: Establish Guiding Principles

**Before technical planning, articulate 2-4 design principles as "X over Y" trade-offs:**

These principles guide ALL subsequent decisions and help resolve ambiguous choices.

**Examples by context:**

- **Mobile icon:** "Clarity over cleverness" → favor obvious solutions over creative ones
- **Brand asset:** "Distinctiveness over convention" → prioritize unique elements
- **Data visualization:** "Accuracy over aesthetics" → never distort data for visual appeal
- **Technical diagram:** "Comprehension over completeness" → hide complexity when needed
- **Accessible design:** "Inclusivity over optimization" → ensure access even if less efficient

**Your principles for this task:** [State 2-4 principles based on context]

**How to use:** When making decisions, reference your principles. Example: "I'm choosing simple primitives over complex paths because 'clarity over cleverness' dictates favoring obvious, maintainable solutions."

## Workflow Decision Tree

```
User requests SVG generation?
│
├─ Simple icon or symbol (< 10 elements)
│  └─ Use "Quick Icon Generation" workflow
│
├─ Data visualization (chart, graph)
│  └─ Use "Data Visualization" workflow
│
├─ Technical diagram (flowchart, architecture)
│  └─ Use "Technical Diagram" workflow
│
├─ Complex illustration or scene
│  └─ Use "Complex Illustration" workflow
│
└─ Unknown or complex requirements
   └─ Start with "Complex Illustration" workflow
```

## Quick Icon Generation

For simple icons and symbols (< 10 basic shapes).

### Step 1: Choose ViewBox with Alternative Analysis

```
Read references/svg-reference.md (Common ViewBox Patterns)
```

**REQUIRED: Explore 2-3 viewBox alternatives with specific trade-offs**

For each option, state the **specific technical downside**, not just "less optimal."

**Example analysis:**

| ViewBox | Technical Trade-off | Use When |
|---------|---------------------|----------|
| 16×16 | Forces fractional coordinates, harder stroke math | Very small UI elements, space-constrained |
| 24×24 | Industry standard, clean integer math | Standard mobile/web icons (RECOMMENDED) |
| 32×32 | More precision but larger file size | Icons that need fine detail |
| 48×48 | Excessive precision for simple icons | Complex icons with many elements |

**Decision format:** "Choosing [X] over [Y] because [specific reason]. Accepting [downside] because [context makes it acceptable]."

✓ Good: "Choosing 24×24 over 16×16 because 16×16 forces fractional coordinates (harder to pixel-align). Accepting slightly less precision than 48×48 because simple icons don't need that detail."

✗ Bad: "Using 24×24 because it's standard." (No alternatives explored, no downsides stated)

### Step 2: Plan Elements

List the visual elements needed:
- Shapes (circles, rectangles, paths)
- Colors (fill, stroke)
- Positioning (coordinates)

**Example:** "Blue checkmark icon"
- Element: Path forming checkmark shape
- Color: Blue stroke, no fill
- Position: Centered in 24×24 viewBox
- Path: M 4,12 L 9,17 L 20,6

### Step 2b: Coordinate Selection with Pixel-Grid Awareness

**For icons at small sizes (<48px viewBox), coordinate precision affects rendering quality.**

#### Pixel-Grid Alignment Principles

**Default to integer coordinates** for crisp rendering. Use fractional coordinates ONLY when you can justify the benefit.

**Stroke-aware positioning:**
- Even-width strokes (2px, 4px) + integer coordinates = crisp edges
- Odd-width strokes (1px, 3px) may need 0.5 offsets for pixel alignment
- Calculate stroke spatial extent: `strokeWidth / 2` when planning margins

**Decision template for coordinates:**

"Using [integer/fractional] coordinates because [specific reason]."

✓ Good examples:
- "Circle at (10, 10) with integer coordinates for crisp rendering at target size"
- "Line at x=10.5 with 1px stroke to align with pixel grid (odd-width strokes need 0.5 offset)"
- "Handle from (15, 15) to (21, 21) - all integers for crisp diagonal at 24px"

✗ Bad examples:
- "Handle at (15.5, 15.5)" without explanation (Why fractional? What's the benefit?)
- "Using 14.7825 for precise calculation" (False precision - rounds to pixels anyway)

#### Avoiding Cargo Cult Math

**When explaining technical parameters, avoid meaningless calculations:**

**DON'T:**
- Calculate percentages without meaning: "Stroke is 8.3% of viewBox" (no threshold exists for this)
- Invoke non-existent rules: "Golden ratio suggests 1.618px stroke" (not applicable)
- Use false precision: "Radius of 7.382 units" (rounds to 7 anyway at this scale)

**DO:**
- Cite established conventions: "Material Design icons use 2px strokes"
- Reference perceptual thresholds: "Below 1.5px becomes invisible on standard displays"
- Compare alternatives: "2px vs 1.5px trades delicacy for reliability"
- Use round numbers: "2px, not 1.847px"

**Test:** If stating a ratio or percentage, ask "Is this threshold documented anywhere, or am I just doing math?"

### Step 3: Generate SVG

Create SVG with planned elements:
- Start with `<svg>` tag including viewBox and dimensions
- Add each element with calculated coordinates
- Apply styling (fill, stroke, stroke-width)
- Include title and desc for accessibility

### Step 4: Purposeful Verification (Not Theater)

**For SIMPLE icons:** Skip formal checklists. Instead:
1. Render/mentally visualize the SVG at target size
2. Ask: "Does this look right?"
3. Check only real failure modes for this specific icon

**Red flag:** Verification checklist with more items than SVG elements = verification theater

**Real failure modes to check:**
- Rendering issues: Elements cut off, anti-aliasing problems at target size
- Accessibility: Missing or incorrect aria labels
- Context fit: Works in stated environment (monochrome, themes, etc.)

✓ Good: "Verified: Icon looks correct at 24×24px, works in both light/dark themes with currentColor"
✗ Bad: 15-point checklist for a 2-element SVG

If inaccurate, identify the specific issue and regenerate with corrections.

## Data Visualization

For charts, graphs, and data-driven graphics.

### Step 1: Understand the Data and Identify Edge Cases

Parse the data or data description:
- Values or ranges
- Number of data points
- Categories or labels
- Comparison relationships
- **Edge cases:** Outliers, zeros, negative values, missing data

**CRITICAL: Identify outliers immediately**

An outlier is a value significantly different from others (typically >2x or <0.5x the median).

**If outliers exist, you MUST address them explicitly:**

| Outlier Strategy | When to Use | Trade-off |
|-----------------|-------------|-----------|
| Broken axis with visual indicator | One outlier, need to show all data | Shows full range but requires explanation |
| Logarithmic scale | Multiple outliers, wide range | Harder for non-technical audiences to read |
| Separate annotation | Extreme outlier | Maintains readable scale, outlier shown separately |
| Truncation with marker | Outlier less important than comparison | Hides actual value, emphasizes relative differences |

**Decision format:** "Data contains outlier at [value] which is [X]x the median. Using [strategy] because [reason], accepting [downside]."

### Step 2: Choose Chart Type and ViewBox

```
Read references/svg-reference.md (Data Visualizations)
```

Select appropriate visualization:
- **Bar chart** - Comparing discrete values
- **Line chart** - Showing trends over time
- **Pie chart** - Showing proportions of a whole
- **Scatter plot** - Showing correlations

Choose viewBox dimensions (e.g., 400×300 for charts with axes).

### Step 3: Calculate Positions

**For bar charts:**
1. Determine bar width: `chartWidth / numberOfBars`
2. Calculate bar heights: `(value / maxValue) * chartHeight`
3. Position bars with consistent spacing

**For pie charts:**
1. Convert values to percentages
2. Convert percentages to angles: `(percentage / 100) * 360`
3. Calculate arc paths using cumulative angles

**For line/scatter plots:**
1. Normalize data to coordinate space
2. Calculate point positions: `x = (index / maxIndex) * chartWidth`, `y = chartHeight - (value / maxValue) * chartHeight`

### Step 4: Generate SVG Structure

Create SVG in layers:
1. **Background** - Chart area, grid lines (if needed)
2. **Axes** - X and Y axes with labels
3. **Data elements** - Bars, lines, points, pie segments
4. **Labels** - Data labels, titles, legends
5. **Decorative** - Colors, gradients, styling

### Step 5: Verify Accuracy

Check that:
- **Data representation:** Values are accurately visualized
- **Proportions:** Relative sizes match relative values
- **Labels:** All data is properly labeled
- **Readability:** Text is readable, colors have sufficient contrast (validate with superpowers:designing-ui-color)

## Technical Diagram

For flowcharts, architecture diagrams, process flows.

### Step 1: Map the Structure

Identify diagram components:
- **Nodes** - Processes, decisions, entities
- **Connections** - Arrows, lines showing relationships
- **Labels** - Text describing each element
- **Layout** - Flow direction (top-to-bottom, left-to-right)

### Step 2: Plan Layout

```
Read references/svg-reference.md (Technical Diagrams)
```

Calculate positions:
1. Determine node dimensions (e.g., 100×50 for rectangles)
2. Calculate spacing between nodes (e.g., 50px gaps)
3. Plan connector paths between nodes
4. Reserve space for labels

**Example:** 3-step vertical flowchart
- Node 1: rect at (50, 20)
- Node 2: rect at (50, 120)
- Node 3: rect at (50, 220)
- Connectors: vertical lines with arrowheads

### Step 3: Generate Diagram Elements

Create SVG structure:

1. **Define reusable elements** - Arrow markers, node templates
```svg
<defs>
  <marker id="arrowhead" ...>
</defs>
```

2. **Create nodes** - Rectangles, diamonds, circles based on type
3. **Add connectors** - Lines with arrow markers
4. **Add labels** - Text centered in or near nodes (use superpowers:designing-ui-typography for font selection if text is prominent)
5. **Group related elements** - Use `<g>` for logical grouping

### Step 4: Verify Diagram

Check that:
- **Flow is clear:** Direction and connections are obvious
- **Layout is balanced:** Nodes are evenly spaced
- **Labels are readable:** Text doesn't overlap, appropriate font size (check superpowers:designing-ui-typography for readability standards)
- **Logic matches description:** Diagram accurately represents the described process

## Complex Illustration

For scenes, landscapes, artistic compositions, or multi-element graphics.

### Step 1: Decompose the Description

Break down the description into:
- **Background elements** - Sky, ground, backdrop
- **Midground elements** - Main subjects, focal points
- **Foreground elements** - Details, overlaying objects
- **Atmospheric effects** - Gradients, shadows, depth cues

**Example:** "Mountain landscape with sun and trees"
- Background: Sky (gradient), sun
- Midground: Mountains
- Foreground: Trees, ground

### Step 2: Choose Coordinate System

```
Read references/svg-reference.md (Coordinate System and ViewBox)
```

Select viewBox based on aspect ratio:
- **Landscape (16:9)** - viewBox="0 0 1600 900"
- **Square** - viewBox="0 0 100 100"
- **Portrait** - viewBox="0 0 600 800"
- **Custom** - Match description's aspect ratio

Consider using centered origin for symmetrical compositions.

### Step 3: Plan Composition

**Establish spatial layout:**
1. Divide viewBox into sections (e.g., sky: top 60%, ground: bottom 40%)
2. Determine element positions and sizes
3. Plan layering order (background to foreground)

**Plan colors:**

**For color palette selection, use superpowers:designing-ui-color skill.**

The superpowers:designing-ui-color skill provides:
- Color harmony strategies (complementary, analogous, monochromatic)
- Mood and psychology-based color selection
- Accessibility and contrast validation
- Industry and context-appropriate palettes

**SVG-specific color considerations:**
- Select gradients for depth (sky, water, 3D effects)
- Plan fill vs stroke colors for visual hierarchy
- Consider dark mode / theme variations if needed

**If image will have text overlay (hero images, backgrounds):**

You MUST consider luminance values and contrast ratios, not just "subtle colors."

**Text overlay requirements:**

| Text Color | Background Luminance | WCAG Contrast Ratio | Color Strategy |
|-----------|---------------------|-------------------|----------------|
| White text | L* < 60 (dark backgrounds) | 4.5:1 for body, 3:1 for large text | Use muted, low-luminance colors |
| Dark text | L* > 70 (light backgrounds) | 4.5:1 for body, 3:1 for large text | Use pastel, high-luminance colors |

**Example analysis:**

✓ Good: "For white text overlay, using sage green (#8B9A7F, L* ≈ 52), taupe (#B8A898, L* ≈ 58), soft blue (#6B8CAA, L* ≈ 48). All L* < 60 ensures WCAG AA compliance (≥4.5:1 contrast) for body text."

✗ Bad: "Using subtle green and blue colors" (No luminance analysis, no contrast verification)

**How to verify:** Use an online contrast checker or calculate: If RGB values average <128, likely dark enough for white text.

**Calculate key coordinates:**
- Element centers
- Path points for complex shapes
- Gradient directions
- Text positions

### Step 4: Generate SVG in Layers

**Create SVG structure from back to front:**

```svg
<svg viewBox="..." width="..." height="...">
  <!-- 1. Background layer -->
  <g id="background">
    <!-- Sky, backdrop, gradients -->
  </g>

  <!-- 2. Midground layer -->
  <g id="midground">
    <!-- Main subjects, focal elements -->
  </g>

  <!-- 3. Foreground layer -->
  <g id="foreground">
    <!-- Details, overlaying objects -->
  </g>
</svg>
```

**For each layer:**
1. Generate elements from reference patterns
```
Read references/svg-reference.md (Content-Specific Patterns)
```

2. Apply calculated coordinates and dimensions
3. Add appropriate styling (fill, stroke, gradients)
4. Include details that enhance visual accuracy

**Use grouping and reuse:**
- Group related elements with `<g>`
- Define reusable elements in `<defs>` and use `<use>`
- Apply transforms for positioning and rotation

### Step 5: Add Depth and Detail

Enhance visual richness:

1. **Gradients** - Add dimension to flat shapes
2. **Overlapping** - Layer elements for depth perception
3. **Shadows** - Use filters or darker shapes for shadows
4. **Highlights** - Add lighter accents for texture
5. **Opacity variations** - Create atmospheric effects

```
Read references/svg-reference.md (Depth and Dimension)
```

### Step 6: Comprehensive Verification

Verify the illustration matches the description:

**Compositional accuracy:**
- [ ] All described elements are present
- [ ] Elements are in correct relative positions
- [ ] Overall composition matches described layout

**Visual accuracy:**
- [ ] Colors match or are appropriate for description
- [ ] Proportions are realistic and match description
- [ ] Perspective and depth appear correct
- [ ] Style (realistic, minimalist, etc.) matches intent

**Technical quality:**
- [ ] No obvious coordinate errors (elements cut off, misaligned)
- [ ] Gradients flow in correct directions
- [ ] Layering is correct (no background elements on top)
- [ ] Code is organized with clear grouping

If any verification fails, identify the specific issue and regenerate the affected elements or sections.

## Using the SVG Reference

The SVG reference document contains comprehensive technical information:

```
Read references/svg-reference.md
```

**When to consult specific sections:**

- **Coordinate System** - Before choosing viewBox, for centering strategies
- **Basic Shapes** - When using simple geometric primitives
- **Paths** - For curves, complex shapes, or custom forms
- **Gradients** - When adding depth, dimension, or color transitions
- **Transforms** - For rotation, scaling, or mirroring elements
- **Visual Accuracy Techniques** - For planning compositions, choosing colors
- **Content-Specific Patterns** - For pre-defined solutions (icons, charts, landscape elements)

**Search the reference for:**
- Specific SVG elements (e.g., "ellipse", "polygon")
- Visual effects (e.g., "shadow", "gradient")
- Content types (e.g., "mountain", "flowchart")
- Technical questions (e.g., "viewBox", "path commands")

## Common Scenarios

### Scenario: User asks "Create a blue circular loading spinner"

```
1. Recognize as icon generation task
2. Plan: Circle with arc path, blue stroke, centered in 24×24 viewBox
3. Consult references/svg-reference.md (Paths - Arc Examples)
4. Generate SVG with animated arc or segmented circle
5. Verify: circular shape, blue color, appropriate for loading indication
```

### Scenario: User provides data and asks for bar chart

```
1. Recognize as data visualization task
2. Parse data values and labels
3. Consult references/svg-reference.md (Bar Chart Pattern)
4. Calculate bar widths and heights based on data
5. Generate SVG with axes, bars, and labels
6. Verify: bars accurately represent data values, labels are correct
```

### Scenario: User describes "Flowchart with 5 steps and 2 decision points"

```
1. Recognize as technical diagram task
2. Map structure: identify 5 process boxes, 2 diamond decisions
3. Consult references/svg-reference.md (Flowchart Box, Diamond)
4. Calculate layout: vertical flow with appropriate spacing
5. Generate SVG with arrow markers, nodes, connectors
6. Verify: 7 total nodes, clear flow direction, decisions properly marked
```

### Scenario: User requests "Beach scene with palm tree, ocean, and sunset"

```
1. Recognize as complex illustration task
2. Decompose: Background (sky gradient, sun), Midground (palm tree), Foreground (beach, ocean)
3. Choose viewBox="0 0 1600 900" for landscape aspect ratio
4. Consult references/svg-reference.md (Sun, Water, Sky Gradient, Tree pattern)
5. Plan composition: sky top 50%, ocean middle 30%, beach bottom 20%
6. Generate in layers: sky → sun → ocean → beach → palm tree
7. Verify: all elements present, sunset colors appropriate, composition balanced
```

### Scenario: Visual accuracy issue - elements are misaligned

```
1. Identify the problem: which elements are misaligned
2. Check coordinate calculations in planning
3. Consult references/svg-reference.md (Coordinate System)
4. Recalculate positions ensuring proper spacing and alignment
5. Regenerate affected elements with corrected coordinates
6. Verify alignment is now correct
```

## Best Practices

### Start with Step 0: Pre-Planning Assessment

- **Classify complexity first** - Determines appropriate workflow depth
- **Extract context constraints** - Before technical decisions, identify what context requires
- **Establish design philosophy** - Create "X over Y" principles to guide all decisions
- **Skip this = guaranteed mechanical application**

### Explore Alternatives, Don't Jump to Answers

- **For every non-trivial decision:** Identify 2-3 alternatives with specific technical downsides
- **State trade-offs explicitly:** "Choosing X over Y because [reason], accepting [downside]"
- **Avoid "it's standard"** without explaining what's wrong with non-standard options
- **This builds engineering judgment** that transfers across tasks

### Use Evidence, Not Spurious Math

- **Cite established conventions:** "Material Design uses 2px" beats "8.3% of viewBox"
- **Reference perceptual thresholds:** "Below 1.5px invisible on standard displays"
- **Compare alternatives with specifics:** "2px vs 1.5px trades delicacy for reliability"
- **Test ratios/percentages:** Is this threshold documented, or just math?

### Calibrate Verification to Task Complexity

- **Simple tasks:** Skip formal checklists, just check it looks right
- **Complex tasks:** Verify against user success criteria (not your process steps)
- **Red flag:** Verification checklist longer than element count
- **Focus on real failure modes:** rendering issues, accessibility, context fit

### Make Ambiguity Explicit

- **When requirements conflict:** Document assumptions with ASSUMPTION/RATIONALE/RISK format
- **State clarifying questions** you would ask (even if you can't ask them)
- **Design for easy adjustment:** Make modular choices that adapt to corrections

### Organize Code Clearly

- **Use groups** - Separate background, midground, foreground
- **Add comments** - Note what each section represents
- **Define reusables** - Use `<defs>` and `<use>` for repeated elements
- **Format consistently** - Maintain readable indentation

## Accessibility

Include accessibility features:

```svg
<svg role="img" aria-labelledby="title desc">
  <title id="title">Descriptive Title</title>
  <desc id="desc">Detailed description of the visual content</desc>
  <!-- SVG content -->
</svg>
```

## Handling Ambiguous or Conflicting Requirements

When requirements are vague or contradictory, you must make them explicit before proceeding.

### Systematic Contradiction Analysis

**Step 1: Identify all contradictions**

List conflicting requirements explicitly:
- "Fun but realistic" → Spectrum from photorealistic to cartoon
- "Colorful but professional" → Risk of garish vs. muted
- "For kids but not childish" → Age range unclear

**Step 2: Extract the underlying intent**

For each contradiction, determine what the user likely means:
- "Fun but realistic" → Probably means "recognizable architecture with friendly styling"
- "Colorful but professional" → Probably means "vibrant but harmonious palette"
- "For kids but not childish" → Probably means ages 7-12, not preschool

**Step 3: Document assumptions with justification**

Use this format:

**ASSUMPTION:** [What you're assuming]
**RATIONALE:** [Why you're making this assumption based on context]
**RISK:** [What happens if assumption is wrong]
**MITIGATION:** [How to easily adjust if user corrects you]

**Example:**

**ASSUMPTION:** Target age is 7-11 (elementary school)
**RATIONALE:** "Not too childish" rules out early childhood; educational context suggests K-12
**RISK:** If target is ages 13-18, style may be too playful
**MITIGATION:** Color saturation and detail level are easily adjustable

### Clarifying Questions Framework

**If you could ask questions, what would you ask?**

Document these (even if you can't ask them) to show your thinking:

**Critical questions** (would change fundamental approach):
- What age range exactly?
- What's the specific use case? (worksheet, poster, presentation)
- Print or digital?

**High-priority questions** (major design implications):
- Any required elements? (garage, garden, specific architectural style)
- Cultural context? (house styles vary globally)
- Part of a series requiring consistency?

**Nice-to-know questions** (optimization/refinement):
- Preferred color palette?
- Will there be text nearby?

**Decision protocol when you can't ask:**
1. State the questions you would ask
2. Make reasonable assumptions with clear justification
3. Design for easy adjustment (modular structure, adjustable parameters)

## Troubleshooting

### Elements appear cut off or outside viewBox

**Issue:** Coordinates exceed viewBox bounds

**Solution:**
1. Check viewBox dimensions vs. element coordinates
2. Recalculate positions to fit within viewBox
3. Consider increasing viewBox size or adjusting element positions

### Colors don't match description

**Issue:** Color selection doesn't align with described appearance

**Solution:**
1. Use superpowers:designing-ui-color skill to select appropriate colors based on mood, context, and description
2. Choose colors that better match the description
3. Consider using gradients for more accurate representation

### Proportions look wrong

**Issue:** Elements are disproportionate to each other

**Solution:**
1. Review planning calculations
2. Compare described proportions to generated sizes
3. Recalculate dimensions maintaining proper ratios
4. Regenerate with corrected sizes

### Composition is unbalanced

**Issue:** Visual weight is unevenly distributed

**Solution:**
1. Review references/svg-reference.md (Visual Accuracy Techniques)
2. Adjust element positions for better balance
3. Consider using the rule of thirds or golden ratio
4. Ensure negative space is appropriately distributed

### Technical diagram is confusing

**Issue:** Flow or relationships are unclear

**Solution:**
1. Simplify connector paths for clarity
2. Ensure consistent spacing between nodes
3. Use clear arrow directions
4. Add or clarify labels
5. Consider reorganizing layout for better readability

## Critical Anti-Patterns to Avoid

These are common failure modes identified through quality validation. Avoid them:

### ❌ Jumping to Solutions Without Exploring Alternatives

**Bad:** "Using 24×24 viewBox because it's standard."
**Good:** "Choosing 24×24 over 16×16 (forces fractional coordinates) and 48×48 (excessive precision). Accepting slightly less precision than 48×48 because simple icons don't need that detail."

**Why it matters:** Without alternative exploration, you can't adapt when requirements change.

### ❌ Treating Context as Documentation Instead of Constraints

**Bad:** "This is for a mobile toolbar." (stated but not analyzed)
**Good:** "Because mobile toolbar → must work in monochrome (currentColor), touch target ≥44×44px (iOS), consistent optical weight with other icons."

**Why it matters:** Missing context constraints = accessibility failures and integration problems.

### ❌ Mechanical Workflow Application Regardless of Complexity

**Bad:** 15-point verification checklist for a 2-element SVG
**Good:** "Simple icon → streamlined verification: looks right at 24px, works in light/dark themes."

**Why it matters:** Wastes time on trivial confirmations instead of focusing on real issues.

### ❌ Spurious Math Without Grounding

**Bad:** "Stroke is 8.3% of viewBox width"
**Good:** "Using 2px stroke (Material Design standard), proven readable at this scale"

**Why it matters:** Meaningless calculations substitute for genuine engineering reasoning.

### ❌ Using Fractional Coordinates Without Justification

**Bad:** "Handle at (15.5, 15.5)" with no explanation
**Good:** "Handle at (15, 15) with integer coordinates for crisp rendering, OR (15.5, 15.5) for 1px stroke pixel-grid alignment"

**Why it matters:** Fractional coordinates cause anti-aliasing blur unless specifically needed.

### ❌ Ignoring Outliers in Data Visualization

**Bad:** Using linear scale when one value is 3x others, making most bars unreadable
**Good:** "Outlier at $155k (3x median). Using broken axis with visual indicator to maintain readability while showing full range. Trade-off: requires explanation, but preserves data integrity."

**Why it matters:** Outliers on linear scales make data unreadable or require dishonest omission.

### ❌ Saying "Subtle Colors" Without Luminance Analysis for Text Overlay

**Bad:** "Using subtle colors for text overlay"
**Good:** "For white text overlay: sage green (L* ≈ 52), taupe (L* ≈ 58). All L* < 60 ensures WCAG AA (≥4.5:1 contrast)."

**Why it matters:** Without luminance analysis, text may be unreadable or fail accessibility standards.

### ❌ Leaving Ambiguity Implicit

**Bad:** Proceeding with vague requirements without documenting assumptions
**Good:** "ASSUMPTION: Ages 7-11. RATIONALE: 'Not childish' rules out preschool. RISK: If 13-18, may be too playful. MITIGATION: Color saturation easily adjustable."

**Why it matters:** Implicit assumptions lead to rework when user expectations don't match.

## Success Criteria for Quality Output

Your SVG generation demonstrates expert-level quality when:

✓ **Trade-offs articulated:** Every non-trivial decision includes 2+ alternatives with specific downsides
✓ **Context incorporated:** Constraints extracted from use case and referenced in decisions
✓ **Alternatives explored:** No foregone conclusions; solution space examined
✓ **Reasoning grounded:** Evidence-based (industry standards, perceptual thresholds) not spurious math
✓ **Depth calibrated:** Simple tasks streamlined, complex tasks thorough
✓ **Ambiguity explicit:** Assumptions documented with rationale and risk assessment
✓ **Verification purposeful:** Focus on real failure modes, not process theater

**If you find yourself:**
- Stating decisions without exploring alternatives → STOP, explore 2-3 options
- Calculating meaningless percentages → STOP, cite conventions or thresholds
- Creating long checklists for simple tasks → STOP, calibrate depth to complexity
- Using "subtle" or "standard" without specifics → STOP, quantify or explain

**This is engineering reasoning, not template filling.**
