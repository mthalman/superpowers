# Icon workflow

Detailed workflow for simple icon and symbol SVG generation.

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
