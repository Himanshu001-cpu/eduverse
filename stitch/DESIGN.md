---
name: Academic Futurist
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#3f4947'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#6f7977'
  outline-variant: '#bec9c6'
  surface-tint: '#0b6a60'
  primary: '#004c44'
  on-primary: '#ffffff'
  primary-container: '#00665c'
  on-primary-container: '#92e1d4'
  inverse-primary: '#86d5c8'
  secondary: '#006875'
  on-secondary: '#ffffff'
  secondary-container: '#00e3fd'
  on-secondary-container: '#00616d'
  tertiary: '#705d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c9a900'
  on-tertiary-container: '#4c3e00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a2f1e4'
  primary-fixed-dim: '#86d5c8'
  on-primary-fixed: '#00201c'
  on-primary-fixed-variant: '#005048'
  secondary-fixed: '#9cf0ff'
  secondary-fixed-dim: '#00daf3'
  on-secondary-fixed: '#001f24'
  on-secondary-fixed-variant: '#004f58'
  tertiary-fixed: '#ffe16d'
  tertiary-fixed-dim: '#e9c400'
  on-tertiary-fixed: '#221b00'
  on-tertiary-fixed-variant: '#544600'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
  deep-navy: '#040B14'
  surface-gray: '#F8F9FA'
  emerald-vivid: '#0E9272'
typography:
  display-lg:
    fontFamily: Playfair Display
    fontSize: 56px
    fontWeight: '700'
    lineHeight: '1.1'
  display-lg-mobile:
    fontFamily: Playfair Display
    fontSize: 36px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-lg:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.3'
  headline-md:
    fontFamily: Playfair Display
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1280px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 48px
  section-gap: 80px
---

## Brand & Style

The design system is built to project an image of "Academic Excellence meeting the Future." It balances the weight of traditional educational institutions with the dynamic energy of digital learning. The target audience includes ambitious students, educators, and lifelong learners who value both reliability and technological progress.

The aesthetic follows a **Corporate / Modern** approach with **Glassmorphism** accents. It utilizes clean layouts and ample white space to ensure high information density remains readable, while using rich gradients and vibrant primary colors to maintain an inspiring, non-stagnant environment. The visual mood is authoritative, intellectual, and forward-thinking.

## Colors

The palette is anchored by **Emerald Green**, signifying growth and stability. **Cyan** is used as a functional accent for interactive elements, providing a "high-tech" feel. **Gold** is reserved for high-value achievements, micro-interactions, and status indicators (e.g., certifications, premium badges).

**Neutral Navy and Charcoal** provide the necessary grounding for typography and structural borders. Backgrounds should primarily remain `#FFFFFF` for content clarity, with `#F8F9FA` used to differentiate secondary sections or sidebar containers. Subtle gradients should transition from the primary Emerald to the vivid Emerald or Cyan to create depth in headers and hero sections.

## Typography

This design system employs a classic serif/sans-serif pairing. **Playfair Display** provides an authoritative, literary feel for all major headings. It should be used with tight tracking in display sizes to maintain a sophisticated editorial look.

**Inter** is the workhorse for all functional UI and long-form body text. Its neutral, highly legible character ensures that complex educational material is accessible. Labels and navigation items use Inter with increased weight and slight letter spacing to ensure they stand out against body content.

## Layout & Spacing

The layout follows a **Fixed Grid** model on desktop, centering content within a 1280px container to ensure readability of long-form text. A 12-column system is used for dashboard layouts and course galleries, allowing for 2, 3, or 4-up card configurations.

Vertical rhythm is based on an **8px base unit**. Large sections are separated by significant gaps (80px+) to maintain an "airy" and premium feel. On mobile, margins reduce to 16px, and grids typically collapse to a single column, though small decorative elements may remain in 2-column layouts if they contain minimal text.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Ambient Shadows**. 

1.  **Level 0 (Base):** White or Light Gray (#F8F9FA) surfaces.
2.  **Level 1 (Cards/Inputs):** White surfaces with a very soft, diffused shadow (0px 4px 20px rgba(0, 0, 0, 0.05)).
3.  **Level 2 (Hover/Active):** Slightly deeper shadow with a hint of the primary color in the tint (0px 10px 30px rgba(0, 102, 92, 0.12)).
4.  **Overlays:** Backdrop blurs (Glassmorphism) are used for navigation bars and modal backdrops to maintain a sense of context and modernity.

Borders should be kept minimal and low-contrast, using the Navy color at 10% opacity for structural definition.

## Shapes

The shape language is **Rounded**, reflecting the approachable and organic nature of growth. Standard components like buttons and inputs use a 0.5rem radius. Larger containers like course cards and hero image containers use a 1rem radius (`rounded-lg`) to create a softer, more modern framing effect. 

Circular shapes are used exclusively for user avatars and icon containers to contrast against the rectangular layout of the grid.

## Components

### Buttons
- **Primary:** Solid Emerald Green with white text. High-emphasis CTAs.
- **Secondary:** Outlined Emerald Green or Solid Cyan for "Explore" actions.
- **Tertiary:** Ghost style with underlined text for low-priority links.

### Cards (Courses)
Course cards are the central component. They feature a top image, a category chip (using Gold or Cyan backgrounds at low opacity), a Playfair Display title, and a bottom meta-info row (e.g., duration, rating). On hover, cards should lift slightly using the Level 2 shadow.

### Inputs & Selects
Field labels use `label-lg` in Navy. Input fields have a 1px border in light gray that transitions to Primary Emerald on focus. Error states use a standard semantic red, but success states must use the Vivid Emerald.

### Lists & Curriculum
Educational content lists use a "Wreath" or "Check" icon in Gold to denote progress. Use horizontal dividers at 5% Navy opacity to separate modules without adding visual clutter.

### Icons
Use a thin-stroke (light) icon set to complement the Inter typeface. Where possible, incorporate the globe or laurel motifs from the logo as subtle watermark backgrounds for certificates or profile headers.