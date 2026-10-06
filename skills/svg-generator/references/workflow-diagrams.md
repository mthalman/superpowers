# Technical diagram workflow

Detailed workflow for SVG flowcharts, architecture diagrams, and process diagrams.

## Technical Diagram

For flowcharts, architecture diagrams, process flows.

### Step 1: Map the Structure

Identify diagram components:
- **Nodes** - Processes, decisions, entities
- **Connections** - Arrows, lines showing relationships
- **Labels** - Text describing each element
- **Layout** - Flow direction (top-to-bottom, left-to-right)

### Step 2: Plan Layout

```
Read references/svg-reference.md (Technical Diagrams)
```

Calculate positions:
1. Determine node dimensions (e.g., 100×50 for rectangles)
2. Calculate spacing between nodes (e.g., 50px gaps)
3. Plan connector paths between nodes
4. Reserve space for labels

**Example:** 3-step vertical flowchart
- Node 1: rect at (50, 20)
- Node 2: rect at (50, 120)
- Node 3: rect at (50, 220)
- Connectors: vertical lines with arrowheads

### Step 3: Generate Diagram Elements

Create SVG structure:

1. **Define reusable elements** - Arrow markers, node templates
```svg
<defs>
  <marker id="arrowhead" ...>
</defs>
```

2. **Create nodes** - Rectangles, diamonds, circles based on type
3. **Add connectors** - Lines with arrow markers
4. **Add labels** - Text centered in or near nodes (use superpowers:designing-ui-typography for font selection if text is prominent)
5. **Group related elements** - Use `<g>` for logical grouping

### Step 4: Verify Diagram

Check that:
- **Flow is clear:** Direction and connections are obvious
- **Layout is balanced:** Nodes are evenly spaced
- **Labels are readable:** Text doesn't overlap, appropriate font size (check superpowers:designing-ui-typography for readability standards)
- **Logic matches description:** Diagram accurately represents the described process
