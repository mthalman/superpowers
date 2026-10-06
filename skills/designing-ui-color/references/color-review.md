# Color Review

Color models, common mistakes, tools, real-world impact notes, and summary guidance for reviews.

## Color Models: When to Use What

| Model | When to Use | Why |
|-------|------------|-----|
| **RGB** | Final output, CSS hex codes | How screens display color |
| **HSL** | Palette generation, tints/shades | Intuitive lightness control |
| **LAB** | Perceptual uniformity testing | Matches human perception |
| **HSB/HSV** | Design tools (Figma, Sketch) | Intuitive saturation control |

**Practical workflow:**
1. Generate palette in **HSL** (easier to create tonal scales)
2. Convert to **RGB/HEX** for implementation
3. Validate in **LAB** for perceptual consistency (advanced)

## Common Mistakes

| Mistake | Fix | Why |
|---------|-----|-----|
| "Pure black #000000 text" | Use #212121 or #1A1A1A | Pure black is too harsh on screens |
| "Rainbow gradients for data" | Use perceptually uniform gradients | Rainbow doesn't map to linear value changes |
| "All colors at full saturation" | Desaturate secondary/tertiary colors | Reduces visual fatigue |
| "Testing colors in design tool only" | Test in actual product with real content | Context changes perception |
| "Using same palette for UI and data viz" | Create separate palettes for each context | Different goals require different strategies |
| "Ignoring colorblind users (8% male)" | Use ColorOracle to simulate, add patterns/shapes | Color alone shouldn't convey critical info |

## Tools

- **Contrast checking:** WebAIM Contrast Checker, Stark plugin
- **Colorblind simulation:** ColorOracle, Chrome DevTools
- **Palette generation:** Coolors.co, Adobe Color, HSL color picker
- **Perceptual testing:** LAB color space converters

## Real-World Impact

- **E-commerce:** Reducing CTA button saturation from 100% to 70% → 12% conversion increase (A/B test)
- **Dashboard:** Using colorblind-safe palette → 23% reduction in support tickets about "can't distinguish states"
- **Brand redesign:** Systematic palette vs. ad-hoc colors → 3x faster designer onboarding

## Summary

**What you already know:** WCAG, basic psychology, accessibility compliance

**What this skill adds:**
- Color harmony types and when to use them
- Perceptual effects (vibration, temperature, simultaneous contrast)
- Systematic palette creation from brand colors
- Context-specific rules (UI ≠ brand ≠ data viz)
- Color models and workflows
- How to explain and defend color choices to stakeholders

**Core principle:** Color design is systematic application of perceptual science, not subjective preference.
