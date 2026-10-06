# Typography Accessibility

WCAG sizing, spacing, contrast, character differentiation, and mobile accessibility details.

## Accessibility by the Numbers

### WCAG Requirements (Level AA)

| Criterion | Requirement | Notes |
|-----------|-------------|-------|
| 1.4.3 Contrast | 4.5:1 normal text, 3:1 large text (18px+) | **Measure for each font weight** |
| 1.4.4 Resize | Text must scale to 200% without loss | Don't use px for font-size |
| 1.4.8 Visual Presentation | Line-height min 1.5, paragraph spacing 1.5x, line length max 80 chars | **1.2 fails this** |
| 1.4.12 Text Spacing | User must be able to adjust spacing | Don't set max-height on text containers |

### Contrast Calculations

WCAG AA requires a contrast ratio of 4.5:1 for normal text and 3:1 for large text (at least 18 pt, or 14 pt bold). Font weight alone does not lower the threshold: 16px bold text is not large and still requires 4.5:1.

```
For #666 on white:
- Contrast ratio: 5.74:1 → PASSES for normal text

For #767676 on white:
- Contrast ratio: 4.54:1 → PASSES for normal text
```

**Tool:** Use a contrast checker to verify the exact foreground/background pair against the applicable threshold.

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
