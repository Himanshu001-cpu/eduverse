# Phase 2: Rich Text & Office Suite Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-20
**Phase:** 2-Rich Text & Office Suite Integration
**Areas discussed:** Document Storage Schema & Backward Compatibility, LaTeX Equation UX & Math Rendering, Whiteboard Diagram Storage, Table Editor & Mobile Responsive Display

---

## Document Storage Schema & Backward Compatibility

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-format storage | Save both structured Delta JSON and pre-rendered HTML, with plain-text fallback in legacy fields | ✓ |
| HTML-only | Store pre-rendered HTML with embedded data attributes, converting back to editor state on open | |
| Delta JSON primary | Store Delta JSON as primary source of truth, converting to HTML on student clients at runtime | |

**User's choice:** Dual-format storage: Save both structured Delta JSON and pre-rendered HTML, with plain-text fallback in legacy fields
**Notes:** Legacy documents without Delta will be transparently upgraded on open/save without requiring batch database migrations.

---

## LaTeX Equation UX & Math Rendering

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid palette & live preview | Category buttons (Algebra, Calculus, Greek, Matrices) + editable LaTeX field + instant live preview | ✓ |
| Visual form wizard | Step-by-step visual builders for fractions, matrices, and roots hiding LaTeX code | |
| Fast code-first | LaTeX text editor with real-time rendering preview window | |

**User's choice:** Hybrid palette & live preview: Category buttons (Algebra, Calculus, Greek, Matrices) + editable LaTeX field + instant live preview
**Notes:** Math equations will render natively for students via `flutter_math_fork` widgets on canvas with zero webview overhead and automatic dark/light theme support.

---

## Whiteboard Diagram Storage

| Option | Description | Selected |
|--------|-------------|----------|
| Firebase Storage image assets | Upload exported SVG/PNG to Firebase Storage and embed clean CDN image tags with caching | ✓ |
| Inline SVG elements | Embed raw SVG directly in document HTML without external asset upload | |
| Firebase Storage + Editable Vector JSON | Store both CDN image for viewing and raw tldraw JSON file for future re-editing | |

**User's choice:** Firebase Storage image assets: Upload exported SVG/PNG to Firebase Storage and embed clean CDN image tags with caching
**Notes:** Diagram interaction in editor allows previewing full-screen, deleting, or launching the canvas to draw and upload a replacement.

---

## Table Editor & Mobile Responsive Display

| Option | Description | Selected |
|--------|-------------|----------|
| Horizontally scrollable card | Smooth horizontal scrolling with subtle shadow indicators and preserved column widths | ✓ |
| Full-screen table viewer | Tap to open table in a full-screen zoomable landscape modal viewer | |
| Responsive column wrapping | Allow columns to wrap or shrink to fit phone viewport without scrolling | |

**User's choice:** Horizontally scrollable card: Smooth horizontal scrolling with subtle shadow indicators and preserved column widths
**Notes:** Table creation features an intuitive visual dialog to set dimensions (up to 20x20) and header styling with clean insertion into the editor.

---

## The Agent's Discretion

None — all decisions were selected explicitly.

## Deferred Ideas

None — discussion stayed within phase scope.
