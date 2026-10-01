# Directions and trade-offs

Detailed guidance for creating three strategic logo directions and explaining trade-offs.

## Three Directions Rule

**Create and present 3 strategic directions**, not just visual variations.

For each direction:
1. Design the concept (icon style, wordmark approach, visual metaphor)
2. Use superpowers:svg-generator to CREATE the actual logo file
3. Use superpowers:designing-ui-color to SELECT actual colors
4. Use superpowers:designing-ui-typography to CHOOSE actual fonts (if wordmark)
5. Document the rationale and trade-offs

Each direction should:
- Represent different positioning strategy
- Include working SVG file (not just description)
- Have clear rationale for why this approach works
- Show trade-offs vs other approaches (quantified when possible)

**Example for B2B SaaS "DataFlow":**
- Direction 1: Abstract geometric - CREATE SVG with geometric shapes, SELECT blue palette, present working file
- Direction 2: Wordmark-focused - CHOOSE font with designing-ui-typography, CREATE SVG wordmark, present working file
- Direction 3: Subtle metaphor - CREATE flow icon SVG, SELECT colors, present working file

Don't present: same logo in 3 colors, or descriptions without actual files.

## Quantifying Trade-Offs

**Include numbers to make trade-offs actionable:**

**Instead of:** "Single color is more budget-friendly"
**Say:** "Single color printing: $50 for 1,000 stickers vs Full color: $200 for 1,000 stickers (Savings: $150 or 4x volume for same cost)"

### Common Quantifiable Dimensions

- **Print costs:** Single-color vs multi-color (exact $ difference, e.g., $50/1k stickers vs $200/1k)
- **Typography licensing:** $0 (system fonts) vs $200-$10k (custom typefaces - see superpowers:designing-ui-typography for details)
- **Implementation time:** 15-30 min (upload SVG to website) vs 2-3 hours (full brand rollout across platforms)
- **File size:** <2KB (fast page loads) vs >50KB (slow, impacts SEO)
- **Scalability:** Works at 16px vs illegible below 32px
- **Color accessibility:** WCAG AA vs AAA compliance (check with superpowers:designing-ui-color)

**Why quantification matters:** "More expensive" is vague. "$200 vs $50" lets user make informed decisions.

## Alternative Exploration (Show Your Work)

**Don't just present final options - document what you rejected and why.**

For each significant alternative considered but not recommended:

### Template:
**❌ Alternative: [Name]**
**Visual concept:** [Brief description]
**Why considered:** [What made this initially appealing]
**Why rejected for THIS context:** [Specific reasons tied to user constraints]

**Example:**

**❌ Alternative: Kanban Board Icon**
**Visual concept:** Three columns with task cards
**Why considered:** Direct visual connection to task management
**Why rejected for THIS context:**
- Too literal - looks like feature screenshot, not brand mark
- Complex detail doesn't scale to 16px favicon (cards become illegible)
- Doesn't differentiate from competitors (many task apps use board metaphors)
- Technical founder couldn't modify easily (too many small elements)

**Why show rejections:**
- Demonstrates thoroughness (didn't just pick first idea)
- Prevents user from suggesting rejected options later
- Shows context-specific reasoning (not generic "boards are bad")
