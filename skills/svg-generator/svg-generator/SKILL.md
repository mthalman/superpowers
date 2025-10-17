---
name: svg-generator
description: Use when generating SVG graphics from written descriptions including icons, data visualizations, illustrations, technical diagrams, or any visual content. Emphasizes visual accuracy through planning-first workflows, proper coordinate systems, and verification steps to ensure generated SVGs match the described appearance.
---

# SVG Generator

## Overview

This skill provides systematic workflows for generating accurate SVG graphics from textual descriptions. The primary focus is ensuring **visual accuracy** - that generated SVGs actually look like what was described. This is achieved through planning-first workflows, proper use of coordinate systems, and verification steps.

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

### Step 1: Choose ViewBox

```
Read references/svg-reference.md (Common ViewBox Patterns)
```

Select appropriate viewBox:
- **24×24** - Standard icons (Material Design)
- **16×16** - Small icons
- **32×32** - Medium icons
- **Centered origin** - For symmetrical icons

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

### Step 3: Generate SVG

Create SVG with planned elements:
- Start with `<svg>` tag including viewBox and dimensions
- Add each element with calculated coordinates
- Apply styling (fill, stroke, stroke-width)
- Include title and desc for accessibility

### Step 4: Verify Visual Accuracy

Check the generated SVG:
- **Proportions:** Elements are sized appropriately relative to each other
- **Positioning:** Elements are where described (centered, aligned, etc.)
- **Styling:** Colors and strokes match description
- **Completeness:** All described features are present

If inaccurate, identify the issue and regenerate with corrections.

## Data Visualization

For charts, graphs, and data-driven graphics.

### Step 1: Understand the Data

Parse the data or data description:
- Values or ranges
- Number of data points
- Categories or labels
- Comparison relationships

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
- **Readability:** Text is readable, colors have sufficient contrast

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
4. **Add labels** - Text centered in or near nodes
5. **Group related elements** - Use `<g>` for logical grouping

### Step 4: Verify Diagram

Check that:
- **Flow is clear:** Direction and connections are obvious
- **Layout is balanced:** Nodes are evenly spaced
- **Labels are readable:** Text doesn't overlap, appropriate font size
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
```
Read references/svg-reference.md (Color Harmony, Visual Accuracy Techniques)
```

- Choose color palette (complementary, analogous, or monochromatic)
- Select gradients for depth (sky, water, 3D effects)
- Ensure colors support the mood/description

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

### Always Plan First

- **Never skip planning** - Generates better results, reduces regeneration
- **Calculate key coordinates** - Don't guess positions
- **Sketch mentally** - Visualize the layout before coding

### Use the Reference Effectively

- **Search before creating** - Check if pattern exists
- **Consult during generation** - Reference syntax and examples
- **Learn from examples** - Adapt existing patterns to new contexts

### Verify Systematically

- **Check against description** - Ensure all requirements met
- **Verify proportions** - Relative sizes should be accurate
- **Test visual balance** - Composition should be aesthetically sound
- **Validate coordinates** - No elements should be cut off or misplaced

### Organize Code Clearly

- **Use groups** - Separate background, midground, foreground
- **Add comments** - Note what each section represents
- **Define reusables** - Use `<defs>` and `<use>` for repeated elements
- **Format consistently** - Maintain readable indentation

### Iterate When Needed

- **Don't settle for "close enough"** - Visual accuracy is the priority
- **Regenerate problematic sections** - Fix issues rather than accepting them
- **Learn from errors** - Understand why inaccuracy occurred

## Accessibility

Include accessibility features:

```svg
<svg role="img" aria-labelledby="title desc">
  <title id="title">Descriptive Title</title>
  <desc id="desc">Detailed description of the visual content</desc>
  <!-- SVG content -->
</svg>
```

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
1. Consult references/svg-reference.md (Common Color Palettes)
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
