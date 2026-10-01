# Illustration workflow

Detailed workflow for SVG scenes, landscapes, artistic compositions, and multi-element illustrations.

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
