# Type Scale and Spacing

Scale ratios, line-height math, line length, and vertical rhythm guidance.

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
