# Data visualization workflow

Detailed workflow for SVG charts, graphs, and data-driven graphics.

## Data Visualization

For charts, graphs, and data-driven graphics.

### Step 1: Understand the Data and Identify Edge Cases

Parse the data or data description:
- Values or ranges
- Number of data points
- Categories or labels
- Comparison relationships
- **Edge cases:** Outliers, zeros, negative values, missing data

**CRITICAL: Identify outliers immediately**

An outlier is a value significantly different from others (typically >2x or <0.5x the median).

**If outliers exist, you MUST address them explicitly:**

| Outlier Strategy | When to Use | Trade-off |
|-----------------|-------------|-----------|
| Broken axis with visual indicator | One outlier, need to show all data | Shows full range but requires explanation |
| Logarithmic scale | Multiple outliers, wide range | Harder for non-technical audiences to read |
| Separate annotation | Extreme outlier | Maintains readable scale, outlier shown separately |
| Truncation with marker | Outlier less important than comparison | Hides actual value, emphasizes relative differences |

**Decision format:** "Data contains outlier at [value] which is [X]x the median. Using [strategy] because [reason], accepting [downside]."

### Step 2: Choose Chart Type and ViewBox

```
Read references/svg-reference.md (Data Visualizations)
```

Select appropriate visualization:
- **Bar chart** - Comparing discrete values
- **Line chart** - Showing trends over time
- **Pie chart** - Showing proportions of a whole
- **Scatter plot** - Showing correlations

Choose viewBox dimensions (e.g., 400×300 for charts with axes).

### Step 3: Calculate Positions

**For bar charts:**
1. Determine bar width: `chartWidth / numberOfBars`
2. Calculate bar heights: `(value / maxValue) * chartHeight`
3. Position bars with consistent spacing

**For pie charts:**
1. Convert values to percentages
2. Convert percentages to angles: `(percentage / 100) * 360`
3. Calculate arc paths using cumulative angles

**For line/scatter plots:**
1. Normalize data to coordinate space
2. Calculate point positions: `x = (index / maxIndex) * chartWidth`, `y = chartHeight - (value / maxValue) * chartHeight`

### Step 4: Generate SVG Structure

Create SVG in layers:
1. **Background** - Chart area, grid lines (if needed)
2. **Axes** - X and Y axes with labels
3. **Data elements** - Bars, lines, points, pie segments
4. **Labels** - Data labels, titles, legends
5. **Decorative** - Colors, gradients, styling

### Step 5: Verify Accuracy

Check that:
- **Data representation:** Values are accurately visualized
- **Proportions:** Relative sizes match relative values
- **Labels:** All data is properly labeled
- **Readability:** Text is readable, colors have sufficient contrast (validate with superpowers:designing-ui-color)
