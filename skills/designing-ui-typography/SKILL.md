---
name: designing-ui-typography
description: Use when designing typography for web/app interfaces, selecting fonts, setting up type scales, addressing performance/accessibility concerns, or handling stakeholder conflicts over typography - provides expert-level guidance on font rendering, OpenType features, and performance trade-offs
---

# Designing UI Typography

## Overview

Expert UI typography balances aesthetics, readability, performance, accessibility, and technical constraints. This skill captures tacit knowledge that separates competent typography from expert-level implementation.

## When to Use

Use this skill when:
- Selecting fonts for web/app interfaces
- Setting up type scales and design systems
- Debugging readability or rendering issues
- Optimizing font loading performance
- Addressing accessibility requirements
- Supporting international/multilingual interfaces

**Don't use for:**
- Print typography (different constraints)
- Marketing sites with minimal text
- Editorial/blog typography (different priorities)

## Complete Expert Analysis Framework

**Expert typography guidance requires analyzing technical AND human/organizational factors:**

### Technical Assessment
- Rendering quality, OpenType features, performance
- Accessibility compliance (WCAG, ADA)
- Cross-platform/device compatibility

### Domain Context Assessment
- **Domain type determines typography psychology:**
  - Fintech/finance → trust, professionalism, clarity
  - Healthcare → accessibility, readability, compliance
  - E-commerce → brand personality + checkout clarity
  - Enterprise SaaS → data density + professional polish

- **Organizational dynamics shape recommendations:**
  - If user mentions stakeholder/client pressure, acknowledge it in your response
  - If brand team conflicts with accessibility, frame accessibility as legal/business risk
  - If time pressure exists, prioritize quick wins vs ideal solutions

### Recommendation Framing
**Include ALL dimensions in your reasoning:**
1. Technical justification (rendering, features, performance)
2. Domain appropriateness (semiotics, trust signals)
3. Legal/compliance implications (WCAG, ADA)
4. Organizational reality (stakeholder language, pushback ammunition)

**Example expert framing:**
"I understand [pressure/constraint mentioned]. Here's why [recommendation]: [technical reason] + [domain reason] + [compliance reason]. To advocate for this: [stakeholder language]."

## Font Selection Criteria

Beyond "does it look good," evaluate fonts on these technical dimensions:

### Rendering Quality
- **Hinting quality**: Does it render clearly at small sizes (12-14px)?
- **X-height**: Taller x-height = better readability at small sizes (compare Inter vs Helvetica)
- **Aperture**: Open counters (a, e, c, s) improve legibility (Verdana, Open Sans)
- **Character differentiation**: Can users distinguish I/l/1, 0/O, rn/m?

### OpenType Features Support
Check what features the font includes:
- `tnum` - Tabular figures (monospaced numbers for tables/dashboards)
- `liga` - Ligatures (fi, fl, ff)
- `calt` - Contextual alternates
- `case` - Case-sensitive forms (better punctuation with ALL CAPS)
- `frac` - Fractions
- `sups`/`subs` - Proper superscript/subscript (not faked)

**For UI fonts, `tnum` is critical** for displaying numbers/data consistently.

### Language Support
- **Latin extended**: Covers Western European languages?
- **CJK fallbacks**: Does your font stack handle Chinese/Japanese/Korean?
- **Diacritics**: Proper accent marks (not clipped by line-height)?
- **RTL support**: If supporting Arabic/Hebrew

**Font stacks should specify language-specific fallbacks:**
```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI',
             'Noto Sans CJK', 'Hiragino Sans', sans-serif;
```

### Typography Semiotics & Trust Signals

**Typography communicates beyond words—font choice signals domain appropriateness and trustworthiness.**

| Font Category | Signals | Appropriate Domains | Inappropriate Domains |
|---------------|---------|---------------------|----------------------|
| **Geometric Sans** (Inter, Roboto, Work Sans) | Modern, technical, trustworthy, professional | Fintech, SaaS, dashboards, data apps | Luxury brands, editorial |
| **High-Contrast Serif** (Playfair, Bodoni, Didot) | Elegant, editorial, luxury, traditional | Fashion, lifestyle, marketing | Fintech, healthcare, dashboards |
| **Humanist Sans** (Open Sans, Lato, Noto Sans) | Friendly, accessible, neutral | Healthcare, education, government | High-end fashion, tech startups |
| **Slab Serif** (Roboto Slab, Zilla Slab) | Sturdy, authoritative, retro-tech | News, documentation, retro branding | Modern fintech, minimalist UIs |

**Domain-Specific Typography Psychology:**

**Fintech/Finance:**
- Users must trust you with their money
- Geometric sans-serifs (Inter, Roboto) signal: professional, modern, trustworthy, technical competence
- Display serifs (Playfair) signal: editorial, luxury → undermines financial credibility
- **Critical:** Serif fonts for marketing/branding ≠ serif fonts for dashboards/data

**Healthcare:**
- Prioritize accessibility, readability for all ages
- Avoid thin weights, decorative fonts that reduce legibility
- Humanist sans-serifs signal care, accessibility, professionalism

**E-commerce:**
- Product names can use display fonts (personality)
- Prices, checkout, cart MUST be ultra-clear (geometric sans)
- Balance brand personality with transactional clarity

**When Recommending Against a Font:**
Don't only cite technical issues—explain the semantic mismatch:

**Template:**
"[Font X] signals [association/emotion], which contradicts [domain requirement]. Users in [domain] need [trust signal], not [font's signal]."

**Example:**
"Playfair Display signals editorial elegance and luxury, which contradicts fintech's need for technical trustworthiness. Financial dashboard users need modern professionalism, not magazine sophistication."

## Type Scale Mathematics

### Scale Ratios and Their Uses

| Ratio | Name | Use Case |
|-------|------|----------|
| 1.125 | Major Second | Subtle hierarchy, info-dense UIs |
| 1.200 | Minor Third | Conservative corporate sites |
| 1.250 | Major Third | **Recommended for most UIs** |
| 1.333 | Perfect Fourth | Marketing sites, generous spacing |
| 1.414 | Augmented Fourth | High visual impact, limited text |
| 1.500 | Perfect Fifth | Editorial, large headings |
| 1.618 | Golden Ratio | High drama, minimal use |

**Key insight:** 1.2 ratio is **too subtle** - differences become imperceptible. 1.25-1.333 provides clear visual hierarchy with fewer steps.

### Line Height ↔ Line Length Formula

**Line-height should increase with line length:**

```
Optimal line-height = 1.5 + ((CPL - 45) / 100)

Where CPL = Characters Per Line
```

Examples:
- 45 CPL: 1.5 line-height
- 60 CPL: 1.65 line-height
- 75 CPL: 1.8 line-height
- 90 CPL: 1.95 line-height

**Shorter lines tolerate tighter spacing. Longer lines need more breathing room.**

### Vertical Rhythm (Optional but Professional)

Maintain consistent spacing using a baseline grid:

```css
:root {
  --baseline: 8px; /* or 4px for tighter grids */
  --font-size-base: 16px;
  --line-height-base: 1.5; /* = 24px, divisible by baseline */
}

/* All spacing in multiples of baseline */
h1 { margin-bottom: calc(var(--baseline) * 4); } /* 32px */
p { margin-bottom: calc(var(--baseline) * 3); }  /* 24px */
```

## Font Loading & Performance

### The Flash Problem

| Strategy | Behavior | When to Use |
|----------|----------|-------------|
| `font-display: block` | FOIT (Flash of Invisible Text) | Never for body text |
| `font-display: swap` | FOUT (Flash of Unstyled Text) | **Default choice** |
| `font-display: fallback` | 100ms FOIT, then FOUT, gives up after 3s | Performance-critical |
| `font-display: optional` | Uses cache or skips font | Extreme performance mode |

**Recommendation:** Use `swap` for most cases. Add `rel="preload"` for critical fonts:

```html
<link rel="preload" href="/fonts/inter-var.woff2" as="font"
      type="font/woff2" crossorigin>
```

### Variable Fonts Trade-offs

**When to use variable fonts:**
- ✅ Need 4+ weights/styles (saves bandwidth)
- ✅ Implementing weight animations
- ✅ Responsive typography (weight changes at breakpoints)

**When NOT to use variable fonts:**
- ❌ Only using 1-2 weights (larger file than static fonts)
- ❌ Supporting older browsers (requires fallbacks anyway)
- ❌ Font doesn't have quality variable implementation

**File size comparison:**
- Static fonts: ~40-50kb per weight → 3 weights = ~150kb
- Variable font: ~70-100kb for entire range
- Break-even point: ~4 weights

### Subsetting

Remove unused characters to reduce file size by 30-70%:

```bash
# Keep only Latin characters
pyftsubset font.ttf --output-file=font-subset.woff2 \
  --flavor=woff2 \
  --unicodes=U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD
```

**Trade-off:** Smaller files vs. supporting unexpected characters (user names, etc.)

## Accessibility by the Numbers

### WCAG Requirements (Level AA)

| Criterion | Requirement | Notes |
|-----------|-------------|-------|
| 1.4.3 Contrast | 4.5:1 normal text, 3:1 large text (18px+) | **Measure for each font weight** |
| 1.4.4 Resize | Text must scale to 200% without loss | Don't use px for font-size |
| 1.4.8 Visual Presentation | Line-height min 1.5, paragraph spacing 1.5x, line length max 80 chars | **1.2 fails this** |
| 1.4.12 Text Spacing | User must be able to adjust spacing | Don't set max-height on text containers |

### Contrast Calculations for Different Weights

**Light/thin weights need higher contrast:**

```
Regular (400 weight) at 16px: 4.5:1 required
Light (300 weight) at 16px: 5.5:1 recommended
Bold (700 weight) at 16px: 3.5:1 acceptable (treat as "large")

For #666 on white:
- Contrast ratio: 3.82:1 → FAILS for 400 weight
- Need #595959 or darker for AA compliance

For #767676 on white:
- Contrast ratio: 4.54:1 → PASSES for 400 weight
- Still insufficient for 300 weight
```

**Tool:** Use WebAIM contrast checker and verify each weight separately.

### Character Differentiation for Accessibility

**Ambiguous characters create accessibility barriers, especially in financial/technical applications:**

| Character Pair | Problem | Solution |
|----------------|---------|----------|
| 1 / I / l | One, capital I, lowercase L look identical | Choose fonts with slashed/dotted zero, serifs on I, distinct l |
| 0 / O | Zero, capital O indistinguishable | Slashed zero (`font-feature-settings: 'zero' 1`) |
| 5 / S | Similar shapes | Test in context: account numbers, product codes |
| rn / m | Lowercase rn can look like m | Good aperture and letter spacing |

**For financial applications:**
- Enable slashed zero: `font-feature-settings: 'zero' 1;`
- Test account numbers, transaction IDs, confirmation codes
- Users misreading numbers = support tickets, failed transactions, lost trust

**Character differentiation is accessibility:**
Users with dyslexia, low vision, or cognitive impairments rely on clear character forms. This isn't aesthetic—it's functional accessibility.

### Mobile Considerations

**Minimum sizes for touch targets:**
- Body text: 16px **minimum** (prevents zoom on iOS)
- Touch targets: 44px × 44px minimum
- Line-height: 1.5-1.6 (more generous than desktop)

**Why 16px matters on mobile:** iOS Safari auto-zooms on inputs with font-size <16px. This breaks your layout and frustrates users.

## OpenType Features in Practice

### Enabling Features

```css
/* Dashboard/data-heavy UI */
.numbers {
  font-variant-numeric: tabular-nums lining-nums;
  font-feature-settings: 'tnum' 1, 'lnum' 1;
}

/* Body copy */
.body {
  font-variant-ligatures: common-ligatures;
  font-feature-settings: 'liga' 1, 'calt' 1;
}

/* ALL CAPS headings */
.uppercase-heading {
  text-transform: uppercase;
  font-feature-settings: 'case' 1; /* Better punctuation positioning */
  letter-spacing: 0.05em; /* Caps need more spacing */
}

/* Fractions */
.fraction {
  font-variant-numeric: diagonal-fractions;
  font-feature-settings: 'frac' 1;
}
```

### Optical Sizing

Some variable fonts include optical sizing (adjusting letterforms for different sizes):

```css
@supports (font-variation-settings: normal) {
  body {
    font-variation-settings: 'opsz' auto; /* Let browser choose */
  }

  /* Or manually control */
  .large-heading {
    font-variation-settings: 'opsz' 48; /* Optimize for 48px */
  }
}
```

**Fonts with optical sizing:** Recursive, Amstelvar, Source Serif Variable

## Common Mistakes

### ❌ Using `px` for Font Sizes
```css
/* BAD */
body { font-size: 16px; }
```
**Problem:** Breaks browser zoom, fails WCAG 1.4.4

```css
/* GOOD */
body { font-size: 1rem; } /* 16px default, scales with user preferences */
```

### ❌ Assuming "Mobile = Smaller Text"
```css
/* BAD */
@media (max-width: 768px) {
  body { font-size: 14px; }
}
```
**Problem:** Mobile users need **larger or equal** text due to viewing distance and screen size

### ❌ Ignoring Font Rendering Differences
- **Windows ClearType** vs. **macOS font smoothing** render differently
- Thin weights look great on Retina displays, unreadable on 1080p Windows
- **Solution:** Test on non-Retina Windows. Avoid weights <400 for body text.

### ❌ Not Specifying Numeric Variants
```css
/* BAD - proportional figures in tables */
table { font-family: 'Inter', sans-serif; }
```

**Result:** Numbers don't align in columns, looks unprofessional in data-heavy UIs

```css
/* GOOD */
table {
  font-variant-numeric: tabular-nums;
  font-feature-settings: 'tnum' 1;
}
```

### ❌ Loading Unused Font Weights
**Every weight = ~40-60kb**

Audit actual usage:
```javascript
const weights = new Set();
document.querySelectorAll('*').forEach(el => {
  weights.add(getComputedStyle(el).fontWeight);
});
console.log(weights); // Often only using 400, 600, 700
```

Most designs only need 2-3 weights. Loading 9 weights = wasted bandwidth.

## Real-World Impact

**Performance:**
- Reducing 8 font weights → 3: ~250kb savings (0.5s on 3G)
- Variable fonts for 4+ weights: ~100kb savings
- Proper subsetting: 30-70% file size reduction

**Accessibility:**
- 16px + 1.5 line-height: Reduces reading time by 11-15% for users with mild vision impairment
- Proper contrast: 30-40% reduction in eye strain
- WCAG AA compliance: Eliminates legal risk

**User experience:**
- Clear hierarchy (1.25+ ratio): Users find information 20-25% faster
- Tabular figures in data UIs: Reduces scanning errors, increases trust
- Mobile-optimized sizing: Prevents layout-breaking zoom behavior

## Quick Reference

### Type Scale Checklist
- [ ] Using 1.25 or 1.333 ratio (not 1.2)
- [ ] 6-8 font sizes maximum
- [ ] Line-height scales with line length (1.5+ for body)
- [ ] Using rem units (not px)

### Font Loading Checklist
- [ ] `font-display: swap` on all @font-face
- [ ] Preloading critical fonts only
- [ ] Loading only 2-3 weights actually used
- [ ] Subset for Western languages if appropriate

### Accessibility Checklist
- [ ] 16px minimum body text (especially mobile)
- [ ] 1.5 minimum line-height
- [ ] 4.5:1 contrast for normal text (test each weight)
- [ ] 45-75 characters per line
- [ ] Text scales to 200% without breaking

### OpenType Features Checklist
- [ ] `tnum` enabled for tables/numbers
- [ ] `liga` enabled for body copy
- [ ] `case` enabled for uppercase headings
- [ ] Font includes features you need (check before selecting)
