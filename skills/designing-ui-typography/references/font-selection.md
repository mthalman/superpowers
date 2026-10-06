# Font Selection

Technical, linguistic, and domain-semiotic criteria for choosing UI fonts.

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
