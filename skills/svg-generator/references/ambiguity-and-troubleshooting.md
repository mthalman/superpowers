# Ambiguity and troubleshooting

Detailed guidance for ambiguous requirements, contradictions, and common SVG generation failures.

## Complexity calibration details

Use these details when the compact SKILL.md table is not enough to calibrate
workflow depth:

| Complexity | Criteria | Workflow approach |
|---|---|---|
| **Simple** | Fewer than 5 elements; established metaphor such as a search icon, checkmark, or arrow; well-defined parameters | Streamlined: 1-2 paragraphs per decision. Focus on correct proportions and clean code. Skip exhaustive checklists and lengthy verification. |
| **Moderate** | 5-15 elements; standard requirements with some customization; typical use cases | Standard workflow depth. Balance detail with efficiency. Focus on key decisions. |
| **Complex** | More than 15 elements; custom illustrations or novel compositions; conflicting requirements; special constraints such as accessibility or text overlay | Full workflow with deep exploration. Provide detailed alternative analysis and comprehensive verification. Expect multiple iterations. |

In interactive contexts, if the complexity is genuinely ambiguous and the answer
would change the deliverable, ask: "Should I provide streamlined analysis for a
simple task, or comprehensive exploration for a complex requirement?" In
non-interactive contexts, classify the task yourself, state the classification,
and continue.

## Context-to-constraint examples

Extract functional requirements before making technical decisions:

- **Platform constraints** → technical requirements:
  - "mobile app" → touch targets at least 44×44px on iOS and 48×48px for Material.
  - "print materials" → CMYK-safe colors and 300 DPI considerations.
- **Visual environment** → design requirements:
  - "toolbar icon" → must work in monochrome and needs consistent optical weight.
  - "hero image" → must support text overlay and requires specific luminance values.
- **User interaction** → functional requirements:
  - "search icon" → must be recognizable within 100ms glance time.
  - "data dashboard" → must enable quick value comparison.

State constraints as "Because [context], we must [constraint]." For example,
"Because mobile toolbar, we must work in monochrome with `currentColor`." Avoid
stopping at "This is for a mobile toolbar" because that does not extract the
constraint. Reference these constraints throughout technical decisions.

## Trade-off principle examples

Before technical planning, articulate 2-4 design principles as `X over Y`
trade-offs. These principles guide later decisions and resolve ambiguity:

- **Mobile icon:** "Clarity over cleverness" favors obvious solutions over creative ones.
- **Brand asset:** "Distinctiveness over convention" prioritizes unique elements.
- **Data visualization:** "Accuracy over aesthetics" means never distort data for visual appeal.
- **Technical diagram:** "Comprehension over completeness" hides complexity when needed.
- **Accessible design:** "Inclusivity over optimization" ensures access even if less efficient.

When making decisions, reference the principles explicitly, for example: "I'm
choosing simple primitives over complex paths because 'clarity over cleverness'
favors obvious, maintainable solutions."

## Handling Ambiguous or Conflicting Requirements

When requirements are vague or contradictory, you must make them explicit before proceeding.

### Systematic Contradiction Analysis

**Step 1: Identify all contradictions**

List conflicting requirements explicitly:
- "Fun but realistic" → Spectrum from photorealistic to cartoon
- "Colorful but professional" → Risk of garish vs. muted
- "For kids but not childish" → Age range unclear

**Step 2: Extract the underlying intent**

For each contradiction, determine what the user likely means:
- "Fun but realistic" → Probably means "recognizable architecture with friendly styling"
- "Colorful but professional" → Probably means "vibrant but harmonious palette"
- "For kids but not childish" → Probably means ages 7-12, not preschool

**Step 3: Document assumptions with justification**

Use this format:

**ASSUMPTION:** [What you're assuming]
**RATIONALE:** [Why you're making this assumption based on context]
**RISK:** [What happens if assumption is wrong]
**MITIGATION:** [How to easily adjust if user corrects you]

**Example:**

**ASSUMPTION:** Target age is 7-11 (elementary school)
**RATIONALE:** "Not too childish" rules out early childhood; educational context suggests K-12
**RISK:** If target is ages 13-18, style may be too playful
**MITIGATION:** Color saturation and detail level are easily adjustable

### Clarifying Questions Framework

**If you could ask questions, what would you ask?**

Document these (even if you can't ask them) to show your thinking:

**Critical questions** (would change fundamental approach):
- What age range exactly?
- What's the specific use case? (worksheet, poster, presentation)
- Print or digital?

**High-priority questions** (major design implications):
- Any required elements? (garage, garden, specific architectural style)
- Cultural context? (house styles vary globally)
- Part of a series requiring consistency?

**Nice-to-know questions** (optimization/refinement):
- Preferred color palette?
- Will there be text nearby?

**Decision protocol when you can't ask:**
1. State the questions you would ask
2. Make reasonable assumptions with clear justification
3. Design for easy adjustment (modular structure, adjustable parameters)

## Troubleshooting

### Elements appear cut off or outside viewBox

**Issue:** Coordinates exceed viewBox bounds

**Solution:**
1. Check viewBox dimensions vs. element coordinates
2. Recalculate positions to fit within viewBox
3. Consider increasing viewBox size or adjusting element positions

### Colors don't match description

**Issue:** Color selection doesn't align with described appearance

**Solution:**
1. Use superpowers:designing-ui-color skill to select appropriate colors based on mood, context, and description
2. Choose colors that better match the description
3. Consider using gradients for more accurate representation

### Proportions look wrong

**Issue:** Elements are disproportionate to each other

**Solution:**
1. Review planning calculations
2. Compare described proportions to generated sizes
3. Recalculate dimensions maintaining proper ratios
4. Regenerate with corrected sizes

### Composition is unbalanced

**Issue:** Visual weight is unevenly distributed

**Solution:**
1. Review references/svg-reference.md (Visual Accuracy Techniques)
2. Adjust element positions for better balance
3. Consider using the rule of thirds or golden ratio
4. Ensure negative space is appropriately distributed

### Technical diagram is confusing

**Issue:** Flow or relationships are unclear

**Solution:**
1. Simplify connector paths for clarity
2. Ensure consistent spacing between nodes
3. Use clear arrow directions
4. Add or clarify labels
5. Consider reorganizing layout for better readability
