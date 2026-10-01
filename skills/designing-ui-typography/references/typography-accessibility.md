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
