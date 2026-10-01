# OpenType Features and Common Mistakes

OpenType implementation details, optical sizing, and common typography implementation mistakes.

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
