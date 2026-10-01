# Palette Generation

Systematic palette creation from brand colors, tonal scales, semantics, and evidence-based claims.

## Systematic Palette Creation

**Don't pick colors randomly. Use systematic generation from brand colors.**

### The 60-30-10 Rule

- **60%:** Dominant color (usually neutral or desaturated)
- **30%:** Secondary color (supports dominant)
- **10%:** Accent color (high contrast, draws attention)

**Example:**
```
60% → Light gray background #F5F5F5
30% → Medium blue surfaces #2196F3
10% → Orange CTAs #FF9800
```

### From Brand Color to Full Palette

**Given brand color:** `#32CD32` (lime green)

**Step 1: Create tonal scale (50-900)**
Use HSL model to maintain hue consistency:

```
50:  hsl(120, 61%, 90%) → #D4F4D4
100: hsl(120, 61%, 80%) → #A9E9A9
200: hsl(120, 61%, 70%) → #7FDE7F
300: hsl(120, 61%, 60%) → #54D354
400: hsl(120, 61%, 50%) → #32CD32  ← Brand color
500: hsl(120, 61%, 40%) → #28A328
600: hsl(120, 61%, 30%) → #1E7A1E
700: hsl(120, 61%, 20%) → #145014
800: hsl(120, 61%, 10%) → #0A270A
900: hsl(120, 61%, 5%)  → #051305
```

**Step 2: Derive complementary/analogous colors**
- Complementary: Rotate hue 180° → Red-purple
- Analogous: ±30° → Yellow-green, Blue-green

**Step 3: Test against contexts**
- Light mode: Does 600 have enough contrast on white?
- Dark mode: Does 200 have enough contrast on black?
- Colorblind: Simulate deuteranopia, protanopia

### Semantic Color Assignment

| Semantic Meaning | Hue Choice | Why |
|-----------------|-----------|-----|
| **Success/Confirm** | Green | Universal "go" signal |
| **Warning/Caution** | Yellow/Amber | Traffic light convention |
| **Error/Danger** | Red | Danger/stop association |
| **Info/Neutral** | Blue | Calm, trustworthy, informational |
| **Pending/Process** | Purple/Gray | No strong semantic association |

**Cultural exceptions:** Red = prosperity in China, white = mourning in some Asian cultures.

### Evidence-Based Color Claims

**When explaining color choices, ground claims in measurable mechanisms, not psychology:**

✅ **GOOD - Mechanistic/Convention-Based:**
- "Red signals danger in Western UIs (established pattern: error messages, stop signs, warnings)"
- "Complementary colors at full saturation create chromatic aberration (visual vibration at edges)"
- "Warm colors advance visually due to chromatic aberration; cool colors recede"
- "Blue is common for CTAs in major platforms (Facebook, Twitter, LinkedIn = learned convention)"

❌ **BAD - Unsupported Psychology:**
- "Red-orange is perceived as 'action' rather than 'danger'" (no evidence - both are red family)
- "Orange signals 'proceed'" (orange means caution in traffic lights, warning in many contexts)
- "Purple conveys luxury" (cultural association, not universal perception)
- "Blue makes users trust your brand" (unfalsifiable claim)

**Priority hierarchy for justifying color choices:**
1. **Accessibility** (contrast ratios, colorblind-safe)
2. **Semantics** (established UI conventions, traffic light patterns)
3. **Brand consistency** (existing style guide, recognition)
4. **Perceptual effects** (vibration, simultaneous contrast, temperature)
5. **Aesthetic harmony** (lowest priority - only after functional requirements met)

**Avoid color psychology entirely unless you can cite specific research with effect sizes.**
