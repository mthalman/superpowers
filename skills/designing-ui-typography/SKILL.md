---
name: designing-ui-typography
description: Use when designing typography for web/app interfaces, selecting fonts, setting up type scales, addressing performance/accessibility concerns, or handling stakeholder conflicts over typography - provides expert-level guidance on font rendering, OpenType features, and performance trade-offs
---

# Designing UI Typography

## Overview

Expert UI typography balances aesthetics, readability, performance, accessibility, rendering quality, language support, and organizational constraints. Treat typography as a functional interface system, not decoration.

## When to Use

Use when selecting fonts for web or app interfaces, setting up type scales and design systems, debugging readability or rendering issues, optimizing font loading, meeting accessibility requirements, or supporting multilingual interfaces.

Do not use for print typography, minimal-text marketing sites, or editorial/blog typography where the constraints differ.

## Core Workflow

1. **Identify the context and constraints.** Determine product domain, text density, devices, languages, accessibility obligations, brand constraints, stakeholder pressure, and performance budget. Open `references/font-selection.md` when choosing or defending a font based on rendering quality, OpenType support, language coverage, domain semiotics, or stakeholder framing.
2. **Set readable defaults first.** Use `rem` font sizes, keep body text at **16px minimum on mobile**, avoid body weights below 400, and use at least 1.5 line-height for body copy.
3. **Design hierarchy with a small scale.** Use 6-8 sizes maximum. Prefer a 1.25 or 1.333 ratio for most UIs; avoid 1.2 when hierarchy must be obvious. Open `references/type-scale-and-spacing.md` when calculating scale ratios, line-height by characters per line, or vertical rhythm.
4. **Validate accessibility.** Confirm text scales to 200%, normal text reaches 4.5:1 contrast, line length stays around 45-75 characters, and characters such as `I/l/1`, `0/O`, `5/S`, and `rn/m` remain distinguishable. Open `references/typography-accessibility.md` when you need detailed WCAG, contrast-by-weight, character differentiation, or mobile guidance.
5. **Apply OpenType features intentionally.** Enable `font-variant-numeric: tabular-nums` or `'tnum'` for tables, dashboards, prices, IDs, and data-heavy UI. Use ligatures, case-sensitive forms, fractions, and optical sizing only when they improve the interface. Open `references/opentype-and-mistakes.md` when implementing OpenType features or checking common mistakes.
6. **Plan font loading.** Use `font-display: swap` by default, preload only critical fonts, load only weights actually used, and consider subsetting or variable fonts when the trade-off is favorable. Open `references/font-performance.md` when optimizing loading, choosing variable fonts, or evaluating subsetting.
7. **Test in context.** Check real content on target devices, including non-Retina Windows rendering, mobile inputs, dense tables, multilingual strings, and user-generated names.
8. **Summarize trade-offs and checks.** Open `references/typography-checklists.md` when you need quick checklists or impact language for performance, accessibility, and user-experience trade-offs.

## Actionable Defaults

- Use `rem` for font sizes so user preferences and zoom work.
- Keep mobile body text and inputs at **16px minimum** to avoid iOS auto-zoom and preserve readability.
- Use body line-height of **1.5 minimum**; increase it as line length grows.
- Keep line length around **45-75 characters**, with 80 as a practical maximum for long-form UI text.
- Test contrast for each font weight; light weights need more contrast than regular text.
- Prefer clear character differentiation for financial, technical, healthcare, and identity flows.
- Enable `tnum` for data-heavy UI so numbers align and scanning errors drop.
- Include language-specific fallback fonts and check diacritics, CJK, RTL, and clipping where relevant.
- Avoid thin body text; weights below 400 often fail on lower-quality displays.

## Output Contract

When making recommendations, include:

- the recommended typeface or stack;
- size scale and line-height defaults;
- accessibility checks and any risks;
- performance/loading guidance;
- language or rendering constraints;
- trade-offs and stakeholder-friendly rationale when there is brand or client pressure.

## Non-Negotiables

- Do not recommend `px` font-size systems for UI text; use scalable units.
- Do not reduce mobile body/input text below 16px.
- Do not treat contrast as font-independent; weight and rendering affect legibility.
- Do not use color, weight, or typography alone to carry critical state if semantics or labels are needed.
- Do not choose fonts only by visual preference; check rendering, language support, accessibility, performance, and domain fit.
- Do not load unused weights or block body text with `font-display: block`.
