# Quality checks

Detailed best practices, reference usage, scenario examples, anti-patterns, and success criteria for high-quality SVG output.

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
