# Phase 2: Rich Text & Office Suite Integration - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide content creators with an advanced WYSIWYG rich text document editor supporting LaTeX equations, interactive tables, and whiteboard diagramming across all content creation surfaces (Articles/Feed, Quizzes, Course Tests, and Lecture Notes). Guarantee seamless native student mobile rendering without webview lag, dual-format persistence in Firestore, and 100% backward compatibility with legacy documents.

</domain>

<decisions>
## Implementation Decisions

### Document Storage Schema & Backward Compatibility
- **D-01:** Dual-format storage: Save both structured Delta JSON (`contentDelta`) for lossless editor state and pre-rendered HTML (`contentHtml`) for fast, zero-overhead student viewing, synchronizing a plain-text fallback into legacy fields (`content`/`description`) for backward compatibility.
- **D-02:** Auto-detect & transparent upgrade: When opening legacy documents lacking `contentDelta`, the editor auto-detects markdown/plain text from legacy fields, populates the editor session seamlessly, and upgrades the document to dual-format on subsequent save.

### LaTeX Equation UX & Math Rendering
- **D-03:** Hybrid palette & live preview: Provide categorized symbol quick-picks (Algebra, Calculus, Greek, Matrices, Symbols) combined with an editable LaTeX syntax field and instant live rendering preview.
- **D-04:** Native Flutter math rendering via `flutter_math_fork`: Student mobile apps and web viewers render inline `$...$` and block `$$...$$` equations natively on canvas without webview performance overhead, adapting automatically to light/dark themes.

### Whiteboard Diagram Storage
- **D-05:** Firebase Storage image assets: Upload exported whiteboard diagrams (`tldraw` SVG/PNG) directly to Firebase Storage (`/diagrams/`) and embed CDN image URLs (`<img src='...' />`) in document HTML to prevent Firestore document bloat.
- **D-06:** Replace & Preview interaction: Tapping an inserted diagram in the editor allows previewing full-screen, deleting, or launching a clean whiteboard canvas to draw and upload a replacement diagram.

### Table Editor & Mobile Responsive Display
- **D-07:** Horizontally scrollable mobile card: Wrap rendered tables in horizontal scroll containers (`SingleChildScrollView(scrollDirection: Axis.horizontal)`) with subtle shadow indicators and preserved column widths to prevent text squishing on compact phone screens.
- **D-08:** Visual grid builder dialog + property controls: Intuitive modal dialog allowing creators to configure grid dimensions up to 20x20, toggle header row formatting, and preview before inserting.

### The Agent's Discretion
None — all UX patterns and storage strategies were explicitly agreed upon.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture & Data Models
- `docs/ARCHITECTURE.md` — Admin module structure and state management
- `docs/DATA_MODELS.md` — Document schemas for quizzes, tests, feeds, and lectures

### Rich Text & Editor Subsystem
- `lib/admin/widgets/rich_document_editor.dart` — Core WYSIWYG editor widget and toolbar integration
- `lib/common/widgets/rich_content_viewer.dart` — Student rendering widget with HTML and math integration
- `lib/admin/widgets/equation_builder.dart` — Modal formula and LaTeX builder dialog
- `lib/admin/widgets/tldraw_webview.dart` — Whiteboard canvas integration and SVG export
- `test/e2e/rich_text_e2e_test.dart` — 38 E2E test scenarios validating formatting, math, tables, and diagrams

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/services/rich_text_service.dart` — Markdown-to-HTML and HTML sanitization utilities
- `lib/admin/widgets/rich_editor_toolbar.dart` — Formatting toolbar with bold, italic, underline, alignment, font size, and highlight
- `lib/admin/widgets/equation_builder.dart` — Formula modal dialog with math templates
- `lib/admin/widgets/tldraw_webview.dart` — Webview integration with simulated test environment fallback

### Established Patterns
- Dual-format storage: `contentDelta` + `contentHtml` + plain text fallback
- Test isolation via `Platform.environment.containsKey('FLUTTER_TEST')`
- Zero external network calls during automated testing

### Integration Points
- `lib/admin/screens/test_series_test_editor_screen.dart` — Course test question and explanation editor
- `lib/admin/screens/feed_editor_screen.dart` — Community feed and article composer
- `lib/admin/screens/batch_quiz_editor_screen.dart` — Batch quiz editor
- `lib/admin/screens/quiz_editor_screen.dart` — Global quiz pool editor

</code_context>

<specifics>
## Specific Ideas

- Ensure clean 20x20 table dimension validation and clear error states.
- Smooth horizontal scroll indicators on mobile to hint to students that wider tables can be panned.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 2-Rich Text & Office Suite Integration*
*Context gathered: 2026-09-20*
