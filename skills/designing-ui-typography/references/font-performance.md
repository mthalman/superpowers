# Font Performance

Font loading strategies, variable-font trade-offs, subsetting, and performance impact.

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
