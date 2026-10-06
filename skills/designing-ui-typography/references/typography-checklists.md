# Typography Checklists

Real-world impact notes and quick checklists for type scale, loading, accessibility, and OpenType features.

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
