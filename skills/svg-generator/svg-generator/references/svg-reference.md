# SVG Reference Guide

Comprehensive reference for generating accurate and well-structured SVG graphics.

## Table of Contents

- [SVG Fundamentals](#svg-fundamentals)
- [Coordinate System and ViewBox](#coordinate-system-and-viewbox)
- [Basic Shapes](#basic-shapes)
- [Paths](#paths)
- [Styling](#styling)
- [Gradients and Patterns](#gradients-and-patterns)
- [Transforms](#transforms)
- [Text](#text)
- [Groups and Structure](#groups-and-structure)
- [Animations](#animations)
- [Visual Accuracy Techniques](#visual-accuracy-techniques)
- [Content-Specific Patterns](#content-specific-patterns)

## SVG Fundamentals

### Basic Structure

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 width height" width="actualWidth" height="actualHeight">
  <!-- SVG content -->
</svg>
```

### Key Attributes

- **xmlns**: Required namespace for SVG (`http://www.w3.org/2000/svg`)
- **viewBox**: Defines the coordinate system (`min-x min-y width height`)
- **width/height**: Physical dimensions (can use units: px, em, %, etc.)
- **preserveAspectRatio**: Controls scaling behavior

### Basic Template

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="200" height="200">
  <rect x="10" y="10" width="80" height="80" fill="blue"/>
</svg>
```

## Coordinate System and ViewBox

### Understanding Coordinates

- Origin (0,0) is at **top-left**
- X increases to the right
- Y increases **downward** (opposite of math convention)

### ViewBox Explained

`viewBox="min-x min-y width height"`

- **min-x, min-y**: Top-left corner of the viewable area
- **width, height**: Size of the coordinate system

### Example: Centering Content

```svg
<!-- Center a 100x100 coordinate system -->
<svg viewBox="-50 -50 100 100" width="200" height="200">
  <!-- Now (0,0) is at the center -->
  <circle cx="0" cy="0" r="40" fill="red"/>
</svg>
```

### Common ViewBox Patterns

```svg
<!-- Icons (square) -->
<svg viewBox="0 0 24 24">

<!-- Widescreen (16:9) -->
<svg viewBox="0 0 1600 900">

<!-- Portrait -->
<svg viewBox="0 0 600 800">

<!-- Centered origin -->
<svg viewBox="-100 -100 200 200">
```

## Basic Shapes

### Rectangle

```svg
<rect x="10" y="10" width="80" height="50" fill="blue" stroke="black" stroke-width="2"/>

<!-- Rounded corners -->
<rect x="10" y="10" width="80" height="50" rx="5" ry="5" fill="blue"/>
```

### Circle

```svg
<circle cx="50" cy="50" r="40" fill="red"/>
```

### Ellipse

```svg
<ellipse cx="50" cy="50" rx="40" ry="20" fill="green"/>
```

### Line

```svg
<line x1="10" y1="10" x2="90" y2="90" stroke="black" stroke-width="2"/>
```

### Polyline

```svg
<!-- Multiple connected points (not closed) -->
<polyline points="10,10 50,50 10,90" fill="none" stroke="blue" stroke-width="2"/>
```

### Polygon

```svg
<!-- Closed shape from points -->
<polygon points="50,10 90,90 10,90" fill="yellow" stroke="black" stroke-width="2"/>

<!-- Triangle -->
<polygon points="50,10 90,90 10,90"/>

<!-- Pentagon -->
<polygon points="50,5 95,35 80,85 20,85 5,35"/>
```

## Paths

Paths are the most powerful SVG element for creating complex shapes.

### Path Commands

#### Move To (M/m)
```svg
M x y    <!-- Absolute: move to (x,y) -->
m dx dy  <!-- Relative: move by (dx,dy) -->
```

#### Line To (L/l, H/h, V/v)
```svg
L x y    <!-- Absolute: line to (x,y) -->
l dx dy  <!-- Relative: line by (dx,dy) -->
H x      <!-- Horizontal line to x -->
V y      <!-- Vertical line to y -->
```

#### Curves

**Quadratic Bézier (Q/q)**
```svg
Q cx cy x y    <!-- Absolute: control point (cx,cy), end point (x,y) -->
q dcx dcy dx dy <!-- Relative -->
T x y          <!-- Smooth continuation -->
```

**Cubic Bézier (C/c)**
```svg
C cx1 cy1 cx2 cy2 x y    <!-- Two control points -->
c dcx1 dcy1 dcx2 dcy2 dx dy <!-- Relative -->
S cx2 cy2 x y             <!-- Smooth continuation -->
```

**Arc (A/a)**
```svg
A rx ry rotation large-arc-flag sweep-flag x y
<!-- rx,ry: radii; rotation: angle; flags: 0 or 1; x,y: end point -->
```

#### Close Path (Z/z)
```svg
Z  <!-- Close the path (draw line to start) -->
```

### Path Examples

**Triangle**
```svg
<path d="M 50,10 L 90,90 L 10,90 Z" fill="yellow"/>
```

**Smooth Curve**
```svg
<path d="M 10,50 Q 50,10 90,50" fill="none" stroke="blue" stroke-width="2"/>
```

**Wave**
```svg
<path d="M 0,50 Q 25,20 50,50 T 100,50" fill="none" stroke="blue" stroke-width="2"/>
```

**Heart Shape**
```svg
<path d="M 50,70 C 50,55 40,50 30,50 C 20,50 10,60 10,70 C 10,85 25,95 50,110 C 75,95 90,85 90,70 C 90,60 80,50 70,50 C 60,50 50,55 50,70 Z" fill="red"/>
```

**Arc Examples**
```svg
<!-- Quarter circle -->
<path d="M 50,50 L 50,10 A 40,40 0 0,1 90,50 Z" fill="blue"/>

<!-- Pac-Man -->
<path d="M 50,50 L 80,30 A 30,30 0 1,1 80,70 Z" fill="yellow"/>
```

### Path Best Practices

1. **Use relative commands (lowercase) for repeated patterns**
2. **Use smooth curve commands (S, T) for flowing shapes**
3. **Close paths with Z for filled shapes**
4. **Keep commands readable with spaces**
5. **Use decimals sparingly - round to 1-2 decimal places**

## Styling

### Fill

```svg
<rect fill="blue"/>
<rect fill="#3498db"/>
<rect fill="rgb(52, 152, 219)"/>
<rect fill="rgba(52, 152, 219, 0.5)"/>
<rect fill="none"/>  <!-- No fill -->
```

### Stroke

```svg
<line stroke="black" stroke-width="2"/>
<line stroke-width="5" stroke-linecap="round"/>  <!-- round, square, butt -->
<line stroke-linejoin="round"/>  <!-- round, bevel, miter -->
<line stroke-dasharray="5,5"/>  <!-- Dashed line -->
<line stroke-dasharray="10,5,2,5"/>  <!-- Complex dash pattern -->
```

### Opacity

```svg
<rect fill-opacity="0.5"/>
<rect stroke-opacity="0.8"/>
<rect opacity="0.5"/>  <!-- Applies to entire element -->
```

### Common Color Palettes

**Material Design**
```svg
<!-- Primary colors -->
fill="#2196F3"  <!-- Blue -->
fill="#4CAF50"  <!-- Green -->
fill="#F44336"  <!-- Red -->
fill="#FF9800"  <!-- Orange -->
```

**Grayscale**
```svg
fill="#FFFFFF"  <!-- White -->
fill="#F5F5F5"  <!-- Very light gray -->
fill="#CCCCCC"  <!-- Light gray -->
fill="#666666"  <!-- Dark gray -->
fill="#333333"  <!-- Very dark gray -->
fill="#000000"  <!-- Black -->
```

## Gradients and Patterns

### Linear Gradient

```svg
<defs>
  <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" />
    <stop offset="100%" style="stop-color:rgb(255,0,0);stop-opacity:1" />
  </linearGradient>
</defs>
<rect fill="url(#grad1)" x="0" y="0" width="100" height="100"/>
```

**Common Gradient Directions**
```svg
<!-- Horizontal: left to right -->
<linearGradient x1="0%" y1="0%" x2="100%" y2="0%">

<!-- Vertical: top to bottom -->
<linearGradient x1="0%" y1="0%" x2="0%" y2="100%">

<!-- Diagonal: top-left to bottom-right -->
<linearGradient x1="0%" y1="0%" x2="100%" y2="100%">
```

### Radial Gradient

```svg
<defs>
  <radialGradient id="grad2" cx="50%" cy="50%" r="50%">
    <stop offset="0%" style="stop-color:white;stop-opacity:1" />
    <stop offset="100%" style="stop-color:blue;stop-opacity:1" />
  </radialGradient>
</defs>
<circle fill="url(#grad2)" cx="50" cy="50" r="40"/>
```

### Patterns

```svg
<defs>
  <pattern id="stripe" patternUnits="userSpaceOnUse" width="10" height="10">
    <line x1="0" y1="0" x2="0" y2="10" stroke="black" stroke-width="5"/>
  </pattern>
</defs>
<rect fill="url(#stripe)" x="0" y="0" width="100" height="100"/>
```

## Transforms

### Transform Attribute

```svg
<!-- Translate (move) -->
<rect transform="translate(50, 50)"/>

<!-- Rotate (angle, center-x, center-y) -->
<rect transform="rotate(45, 50, 50)"/>

<!-- Scale (x-scale, y-scale) -->
<rect transform="scale(2, 1)"/>

<!-- Skew -->
<rect transform="skewX(20)"/>

<!-- Multiple transforms (applied right to left) -->
<rect transform="translate(50, 50) rotate(45) scale(1.5)"/>
```

### Common Transform Patterns

**Rotate around center**
```svg
<!-- For an element at (50,50) with size 20x20 -->
<rect x="40" y="40" width="20" height="20" transform="rotate(45, 50, 50)"/>
```

**Mirror horizontally**
```svg
<g transform="scale(-1, 1) translate(-100, 0)">
  <!-- Content to mirror -->
</g>
```

## Text

### Basic Text

```svg
<text x="50" y="50" font-family="Arial" font-size="20" fill="black">
  Hello World
</text>
```

### Text Alignment

```svg
<!-- Horizontal alignment -->
<text text-anchor="start">Left aligned</text>
<text text-anchor="middle">Center aligned</text>
<text text-anchor="end">Right aligned</text>

<!-- Vertical alignment (use dominant-baseline or dy) -->
<text dominant-baseline="hanging">Top aligned</text>
<text dominant-baseline="middle">Middle aligned</text>
<text dominant-baseline="baseline">Baseline aligned</text>
```

### Text Styling

```svg
<text font-family="Arial, sans-serif"
      font-size="24"
      font-weight="bold"
      font-style="italic"
      letter-spacing="2"
      fill="blue"
      stroke="black"
      stroke-width="0.5">
  Styled Text
</text>
```

### Text on Path

```svg
<defs>
  <path id="curve" d="M 10,50 Q 50,10 90,50" fill="none"/>
</defs>
<text>
  <textPath href="#curve">
    Text along a curve
  </textPath>
</text>
```

### Multi-line Text

```svg
<text x="50" y="50" text-anchor="middle">
  <tspan x="50" dy="0">Line 1</tspan>
  <tspan x="50" dy="20">Line 2</tspan>
  <tspan x="50" dy="20">Line 3</tspan>
</text>
```

## Groups and Structure

### Group Element

```svg
<g id="group1" fill="blue" stroke="black" stroke-width="2">
  <!-- All children inherit these styles -->
  <circle cx="25" cy="25" r="20"/>
  <circle cx="75" cy="25" r="20"/>
</g>
```

### Reusable Elements with Defs and Use

```svg
<defs>
  <!-- Define reusable elements (not rendered) -->
  <circle id="dot" r="5" fill="red"/>
</defs>

<!-- Use (reference) the element multiple times -->
<use href="#dot" x="10" y="10"/>
<use href="#dot" x="30" y="10"/>
<use href="#dot" x="50" y="10"/>
```

### Symbol and Use

```svg
<defs>
  <symbol id="icon" viewBox="0 0 24 24">
    <!-- Icon content with its own viewBox -->
    <circle cx="12" cy="12" r="10"/>
  </symbol>
</defs>

<use href="#icon" x="0" y="0" width="50" height="50"/>
<use href="#icon" x="60" y="0" width="100" height="100"/>
```

### Layering with Z-Index

SVG uses **painter's algorithm** - elements drawn later appear on top.

```svg
<rect fill="red" x="0" y="0" width="50" height="50"/>
<rect fill="blue" x="25" y="25" width="50" height="50"/>
<!-- Blue rectangle appears on top -->
```

## Animations

SVG supports both native SMIL animations and CSS animations for creating dynamic graphics.

### CSS Animations (Recommended)

CSS animations are widely supported and easier to control. Use `<style>` tag or inline styles.

**Basic Syntax:**
```svg
<svg viewBox="0 0 100 100">
  <style>
    .rotating {
      animation: rotate 2s linear infinite;
      transform-origin: center;
    }
    @keyframes rotate {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }
  </style>
  <circle class="rotating" cx="50" cy="50" r="40" fill="blue"/>
</svg>
```

### Common Animation Properties

```css
animation: name duration timing-function delay iteration-count direction fill-mode;

/* Examples */
animation: spin 1s linear infinite;              /* Spin forever */
animation: fade 2s ease-in-out 0s 1 normal;     /* Fade once */
animation: pulse 1.5s ease-in-out 0s infinite alternate; /* Pulse back and forth */
```

**Timing Functions:**
- `linear` - Constant speed
- `ease` - Slow start, fast middle, slow end
- `ease-in` - Slow start
- `ease-out` - Slow end
- `ease-in-out` - Slow start and end
- `cubic-bezier(x1, y1, x2, y2)` - Custom curve

### Animation Patterns

#### Rotating Spinner

```svg
<svg viewBox="0 0 50 50">
  <style>
    .spinner {
      animation: rotate 1s linear infinite;
      transform-origin: center;
    }
    @keyframes rotate {
      to { transform: rotate(360deg); }
    }
  </style>
  <circle class="spinner" cx="25" cy="25" r="20"
          fill="none" stroke="blue" stroke-width="4"
          stroke-dasharray="90, 150" stroke-linecap="round"/>
</svg>
```

#### Pulsing Effect

```svg
<svg viewBox="0 0 100 100">
  <style>
    .pulse {
      animation: pulse 2s ease-in-out infinite;
    }
    @keyframes pulse {
      0%, 100% { transform: scale(1); opacity: 1; }
      50% { transform: scale(1.1); opacity: 0.7; }
    }
  </style>
  <circle class="pulse" cx="50" cy="50" r="30" fill="red"/>
</svg>
```

#### Fade In/Out

```svg
<svg viewBox="0 0 100 100">
  <style>
    .fade {
      animation: fade 3s ease-in-out infinite alternate;
    }
    @keyframes fade {
      from { opacity: 0; }
      to { opacity: 1; }
    }
  </style>
  <rect class="fade" x="25" y="25" width="50" height="50" fill="green"/>
</svg>
```

#### Bouncing

```svg
<svg viewBox="0 0 100 100">
  <style>
    .bounce {
      animation: bounce 1s ease-in-out infinite;
    }
    @keyframes bounce {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-20px); }
    }
  </style>
  <circle class="bounce" cx="50" cy="70" r="15" fill="orange"/>
</svg>
```

#### Progress Bar Fill

```svg
<svg viewBox="0 0 200 20">
  <style>
    .progress {
      animation: fill 3s ease-out forwards;
    }
    @keyframes fill {
      from { width: 0; }
      to { width: 200; }
    }
  </style>
  <rect x="0" y="0" width="200" height="20" fill="#e0e0e0"/>
  <rect class="progress" x="0" y="0" width="0" height="20" fill="#4CAF50"/>
</svg>
```

#### Dash Animation (Drawing Effect)

```svg
<svg viewBox="0 0 100 100">
  <style>
    .draw {
      stroke-dasharray: 314;
      stroke-dashoffset: 314;
      animation: draw 2s ease-out forwards;
    }
    @keyframes draw {
      to { stroke-dashoffset: 0; }
    }
  </style>
  <circle class="draw" cx="50" cy="50" r="45"
          fill="none" stroke="blue" stroke-width="4"/>
</svg>
```

### SMIL Animations (Native SVG)

SMIL is built into SVG but has limited browser support and is less flexible than CSS animations.

#### Animate Element

```svg
<circle cx="50" cy="50" r="20" fill="blue">
  <animate attributeName="r"
           from="20" to="40"
           dur="2s"
           repeatCount="indefinite"/>
</circle>
```

#### Animate Transform

```svg
<rect x="40" y="40" width="20" height="20" fill="red">
  <animateTransform attributeName="transform"
                    type="rotate"
                    from="0 50 50"
                    to="360 50 50"
                    dur="3s"
                    repeatCount="indefinite"/>
</rect>
```

#### Animate Motion

```svg
<path id="motionPath" d="M 10,50 Q 50,10 90,50" fill="none"/>
<circle r="5" fill="red">
  <animateMotion dur="2s" repeatCount="indefinite">
    <mpath href="#motionPath"/>
  </animateMotion>
</circle>
```

#### Animate Multiple Properties

```svg
<circle cx="50" cy="50" r="20" fill="blue">
  <animate attributeName="r" values="20;40;20" dur="2s" repeatCount="indefinite"/>
  <animate attributeName="fill" values="blue;red;blue" dur="2s" repeatCount="indefinite"/>
</circle>
```

### Transform Origin for Rotations

Critical for spinning/rotating animations:

```css
/* Set transform origin to element center */
.rotating {
  transform-origin: center;
}

/* Or specify coordinates */
.rotating {
  transform-origin: 50px 50px;
}
```

### Animation Timing and Control

**Delay:**
```css
animation-delay: 1s;  /* Start after 1 second */
```

**Iteration:**
```css
animation-iteration-count: 3;        /* Run 3 times */
animation-iteration-count: infinite; /* Run forever */
```

**Direction:**
```css
animation-direction: normal;          /* Forward only */
animation-direction: reverse;         /* Backward only */
animation-direction: alternate;       /* Forward then backward */
animation-direction: alternate-reverse; /* Backward then forward */
```

**Fill Mode:**
```css
animation-fill-mode: none;      /* Reset after animation */
animation-fill-mode: forwards;  /* Stay at final state */
animation-fill-mode: backwards; /* Apply first frame before animation */
animation-fill-mode: both;      /* Both forwards and backwards */
```

### Multiple Animations

Apply multiple animations to one element:

```svg
<svg viewBox="0 0 100 100">
  <style>
    .multi {
      animation: spin 2s linear infinite,
                 pulse 1s ease-in-out infinite alternate;
      transform-origin: center;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    @keyframes pulse {
      to { opacity: 0.5; }
    }
  </style>
  <circle class="multi" cx="50" cy="50" r="30" fill="blue"/>
</svg>
```

### Loading Spinner Examples

**Circular Spinner:**
```svg
<svg viewBox="0 0 50 50">
  <style>
    .spinner {
      animation: rotate 2s linear infinite;
      transform-origin: center;
    }
    .path {
      stroke-dasharray: 1, 150;
      stroke-dashoffset: 0;
      animation: dash 1.5s ease-in-out infinite;
    }
    @keyframes rotate {
      100% { transform: rotate(360deg); }
    }
    @keyframes dash {
      0% {
        stroke-dasharray: 1, 150;
        stroke-dashoffset: 0;
      }
      50% {
        stroke-dasharray: 90, 150;
        stroke-dashoffset: -35;
      }
      100% {
        stroke-dasharray: 90, 150;
        stroke-dashoffset: -124;
      }
    }
  </style>
  <g class="spinner">
    <circle class="path" cx="25" cy="25" r="20"
            fill="none" stroke="#2196F3" stroke-width="4"/>
  </g>
</svg>
```

**Dots Spinner:**
```svg
<svg viewBox="0 0 100 20">
  <style>
    .dot {
      animation: bounce 1.4s ease-in-out infinite;
    }
    .dot:nth-child(1) { animation-delay: -0.32s; }
    .dot:nth-child(2) { animation-delay: -0.16s; }
    @keyframes bounce {
      0%, 80%, 100% { transform: scale(0); }
      40% { transform: scale(1); }
    }
  </style>
  <circle class="dot" cx="20" cy="10" r="5" fill="#2196F3"/>
  <circle class="dot" cx="50" cy="10" r="5" fill="#2196F3"/>
  <circle class="dot" cx="80" cy="10" r="5" fill="#2196F3"/>
</svg>
```

### Best Practices for Animations

1. **Use CSS over SMIL** - Better support, more flexible
2. **Set transform-origin** - Critical for rotations and scaling
3. **Use hardware acceleration** - Animate transform and opacity for best performance
4. **Avoid animating expensive properties** - Don't animate width/height if possible
5. **Test performance** - Complex animations can impact performance
6. **Provide reduced motion** - Respect user preferences

```css
@media (prefers-reduced-motion: reduce) {
  .animated {
    animation: none;
  }
}
```

### Pausing and Controlling Animations

```css
/* Pause animation on hover */
.spinner:hover {
  animation-play-state: paused;
}
```

### Animation with JavaScript (if needed)

While generating SVG, include IDs for JavaScript control:

```svg
<circle id="myCircle" cx="50" cy="50" r="20" fill="blue"/>

<script>
  // Can be controlled via JavaScript
  const circle = document.getElementById('myCircle');
  circle.style.animation = 'spin 2s linear infinite';
</script>
```

## Visual Accuracy Techniques

### Planning Compositions

**For complex illustrations:**

1. **Establish coordinate system**
   - Choose appropriate viewBox dimensions
   - Consider using centered origin for symmetrical designs

2. **Sketch mental grid**
   - Divide space into sections
   - Use consistent spacing and proportions

3. **Work in layers (groups)**
   - Background elements first
   - Midground elements
   - Foreground elements
   - Details last

### Proportions and Measurements

**Golden Ratio: ~1.618**
```svg
<!-- Rectangle with golden ratio -->
<rect width="161.8" height="100"/>
```

**Common Icon Sizes**
```svg
viewBox="0 0 24 24"   <!-- Material Design -->
viewBox="0 0 16 16"   <!-- Small icons -->
viewBox="0 0 32 32"   <!-- Medium icons -->
viewBox="0 0 512 512" <!-- Large icons/logos -->
```

### Color Harmony

**Complementary Colors**
- Blue (#2196F3) ↔ Orange (#FF9800)
- Red (#F44336) ↔ Green (#4CAF50)

**Analogous Colors**
- Blue shades: #0D47A1, #1976D2, #2196F3, #42A5F5

**Monochromatic (shades of one color)**
```svg
fill="#1565C0"  <!-- Dark -->
fill="#1976D2"  <!-- Medium-dark -->
fill="#2196F3"  <!-- Base -->
fill="#42A5F5"  <!-- Light -->
fill="#90CAF9"  <!-- Very light -->
```

### Depth and Dimension

**Drop Shadow Effect**
```svg
<defs>
  <filter id="shadow">
    <feDropShadow dx="2" dy="2" stdDeviation="2" flood-opacity="0.3"/>
  </filter>
</defs>
<circle cx="50" cy="50" r="40" fill="blue" filter="url(#shadow)"/>
```

**3D Effect with Gradients**
```svg
<defs>
  <radialGradient id="sphere">
    <stop offset="0%" stop-color="white"/>
    <stop offset="50%" stop-color="blue"/>
    <stop offset="100%" stop-color="darkblue"/>
  </radialGradient>
</defs>
<circle cx="50" cy="50" r="40" fill="url(#sphere)"/>
```

**Overlapping for Depth**
```svg
<!-- Background (lighter, smaller) -->
<circle cx="40" cy="40" r="30" fill="#90CAF9" opacity="0.6"/>
<!-- Foreground (darker, larger) -->
<circle cx="60" cy="60" r="35" fill="#2196F3"/>
```

## Content-Specific Patterns

### Icons

**Checkmark**
```svg
<svg viewBox="0 0 24 24">
  <path d="M 4,12 L 9,17 L 20,6" fill="none" stroke="green" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

**X (Close)**
```svg
<svg viewBox="0 0 24 24">
  <path d="M 6,6 L 18,18 M 18,6 L 6,18" fill="none" stroke="black" stroke-width="2" stroke-linecap="round"/>
</svg>
```

**Menu (Hamburger)**
```svg
<svg viewBox="0 0 24 24">
  <line x1="3" y1="6" x2="21" y2="6" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <line x1="3" y1="12" x2="21" y2="12" stroke="black" stroke-width="2" stroke-linecap="round"/>
  <line x1="3" y1="18" x2="21" y2="18" stroke="black" stroke-width="2" stroke-linecap="round"/>
</svg>
```

**Arrow**
```svg
<svg viewBox="0 0 24 24">
  <path d="M 5,12 L 19,12 M 12,5 L 19,12 L 12,19" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

### Data Visualizations

**Bar Chart Pattern**
```svg
<svg viewBox="0 0 200 100">
  <!-- Bars -->
  <rect x="10" y="40" width="30" height="60" fill="blue"/>
  <rect x="50" y="20" width="30" height="80" fill="blue"/>
  <rect x="90" y="50" width="30" height="50" fill="blue"/>
  <rect x="130" y="30" width="30" height="70" fill="blue"/>

  <!-- Baseline -->
  <line x1="0" y1="100" x2="200" y2="100" stroke="black" stroke-width="2"/>
</svg>
```

**Pie Chart Segment**
```svg
<!-- 90-degree segment (quarter circle) -->
<path d="M 50,50 L 50,10 A 40,40 0 0,1 90,50 Z" fill="blue"/>
```

### Technical Diagrams

**Flowchart Box**
```svg
<rect x="10" y="10" width="80" height="40" rx="5" fill="white" stroke="black" stroke-width="2"/>
<text x="50" y="35" text-anchor="middle" font-size="14">Process</text>
```

**Diamond (Decision)**
```svg
<polygon points="50,10 90,50 50,90 10,50" fill="white" stroke="black" stroke-width="2"/>
<text x="50" y="55" text-anchor="middle" font-size="12">Decision?</text>
```

**Arrow Connector**
```svg
<defs>
  <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
    <polygon points="0,0 10,3 0,6" fill="black"/>
  </marker>
</defs>
<line x1="10" y1="50" x2="90" y2="50" stroke="black" stroke-width="2" marker-end="url(#arrowhead)"/>
```

### Landscapes and Scenes

**Mountain**
```svg
<polygon points="50,10 80,60 20,60" fill="#8B7355"/>
<!-- Snow cap -->
<polygon points="50,10 60,30 40,30" fill="white"/>
```

**Tree**
```svg
<!-- Trunk -->
<rect x="45" y="60" width="10" height="30" fill="#8B4513"/>
<!-- Foliage -->
<circle cx="50" cy="50" r="20" fill="#228B22"/>
<circle cx="40" cy="55" r="15" fill="#228B22"/>
<circle cx="60" cy="55" r="15" fill="#228B22"/>
```

**Sun**
```svg
<defs>
  <radialGradient id="sun">
    <stop offset="0%" stop-color="#FFF59D"/>
    <stop offset="50%" stop-color="#FFD54F"/>
    <stop offset="100%" stop-color="#FFA726"/>
  </radialGradient>
</defs>
<circle cx="80" cy="20" r="15" fill="url(#sun)"/>
```

**Water**
```svg
<!-- Use waves with gradient for water -->
<defs>
  <linearGradient id="water" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#81D4FA"/>
    <stop offset="100%" stop-color="#0277BD"/>
  </linearGradient>
</defs>
<rect x="0" y="70" width="100" height="30" fill="url(#water)"/>
<path d="M 0,70 Q 10,65 20,70 T 40,70 T 60,70 T 80,70 T 100,70" fill="none" stroke="white" stroke-width="1" opacity="0.5"/>
```

**Cloud**
```svg
<g fill="white" opacity="0.8">
  <circle cx="30" cy="30" r="10"/>
  <circle cx="45" cy="28" r="12"/>
  <circle cx="60" cy="30" r="10"/>
  <ellipse cx="45" cy="35" rx="20" ry="8"/>
</g>
```

**Sky Gradient**
```svg
<defs>
  <linearGradient id="sky" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#1E88E5"/>
    <stop offset="100%" stop-color="#90CAF9"/>
  </linearGradient>
</defs>
<rect x="0" y="0" width="100" height="70" fill="url(#sky)"/>
```

## Best Practices Summary

### For Visual Accuracy

1. **Plan before generating** - Sketch mental layout, identify key elements
2. **Use appropriate viewBox** - Match aspect ratio to content
3. **Work in layers** - Group background, midground, foreground
4. **Verify proportions** - Check relative sizes match description
5. **Use gradients for depth** - Add dimension with color transitions
6. **Test visual balance** - Ensure composition is balanced

### For Code Quality

1. **Use semantic grouping** - Group related elements with `<g>`
2. **Define reusable elements** - Use `<defs>` and `<use>` for repeated content
3. **Round coordinates** - Use 1-2 decimal places maximum
4. **Add comments** - Use XML comments for complex sections
5. **Consistent formatting** - Maintain readable structure
6. **Optimize paths** - Use relative commands, remove unnecessary points

### For Accessibility

1. **Add title and desc** - For screen readers
2. **Use semantic colors** - Ensure sufficient contrast
3. **Provide fallback** - Consider non-SVG alternatives
4. **Size appropriately** - Ensure text is readable

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" role="img" aria-labelledby="title desc">
  <title id="title">Checkmark Icon</title>
  <desc id="desc">A green checkmark indicating success or completion</desc>
  <path d="M 20,50 L 40,70 L 80,30" stroke="green" stroke-width="5" fill="none"/>
</svg>
```
