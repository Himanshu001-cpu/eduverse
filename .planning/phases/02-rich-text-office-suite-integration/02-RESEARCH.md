# Phase 02: Rich Text & Office Suite Integration - Research

**Researched:** 2026-09-20
**Domain:** WYSIWYG rich text editing, LaTeX mathematical notation, vector diagramming, responsive tables, dual-format persistence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Dual-format storage: Save both structured Delta JSON (`contentDelta`) for lossless editor state and pre-rendered HTML (`contentHtml`) for fast, zero-overhead student viewing, synchronizing a plain-text fallback into legacy fields (`content`/`description`) for backward compatibility.
- **D-02:** Auto-detect & transparent upgrade: When opening legacy documents lacking `contentDelta`, the editor auto-detects markdown/plain text from legacy fields, populates the editor session seamlessly, and upgrades the document to dual-format on subsequent save.
- **D-03:** Hybrid palette & live preview: Provide categorized symbol quick-picks (Algebra, Calculus, Greek, Matrices, Symbols) combined with an editable LaTeX syntax field and instant live rendering preview.
- **D-04:** Native Flutter math rendering via `flutter_math_fork`: Student mobile apps and web viewers render inline `$...$` and block `$$...$$` equations natively on canvas without webview performance overhead, adapting automatically to light/dark themes.
- **D-05:** Firebase Storage image assets: Upload exported whiteboard diagrams (`tldraw` SVG/PNG) directly to Firebase Storage (`/diagrams/`) and embed CDN image URLs (`<img src='...' />`) in document HTML to prevent Firestore document bloat.
- **D-06:** Replace & Preview interaction: Tapping an inserted diagram in the editor allows previewing full-screen, deleting, or launching a clean whiteboard canvas to draw and upload a replacement diagram.
- **D-07:** Horizontally scrollable mobile card: Wrap rendered tables in horizontal scroll containers (`SingleChildScrollView(scrollDirection: Axis.horizontal)`) with subtle shadow indicators and preserved column widths to prevent text squishing on compact phone screens.
- **D-08:** Visual grid builder dialog + property controls: Intuitive modal dialog allowing creators to configure grid dimensions up to 20x20, toggle header row formatting, and preview before inserting.

### The Agent's Discretion
None — all UX patterns and storage strategies were explicitly agreed upon.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed strictly within phase scope.
</user_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dual-Format Document Storage (`contentDelta` + `contentHtml` + plain text) | Database/Storage (Firestore) | Client (Admin Editor / RichTextService) | Firestore persists canonical document snapshots; client serializes and unpacks payloads. |
| Auto-detect & Legacy Transparent Upgrade | Client (Admin Editor) | Database/Storage (Firestore) | Client identifies legacy fields (`body`/`questionText`), maps them into the editor controller, and commits dual-format fields on save. |
| Hybrid LaTeX Palette & Live Preview | Client (Admin Editor) | — | Interactive authoring widget running on local Flutter canvas. |
| Canvas-Native Math Rendering (`$...$` & `$$...$$`) | Client (Student Viewer & Web) | — | Uses `flutter_math_fork` directly on Skia/Impeller canvas; avoids webview process spawning. |
| Whiteboard Diagram Asset Uploads | API/Storage (Firebase Storage `/diagrams/`) | Client (Tldraw Webview & Admin Editor) | Client rasterizes/exports SVG/PNG and uploads to Firebase Storage `/diagrams/`; HTML stores lightweight CDN URLs. |
| Diagram Preview, Delete & Replace Workflow | Client (Admin Editor) | API/Storage (Firebase Storage) | Admin editor parses inserted diagram tags into interactive cards with modal preview, replacement canvas, or removal. |
| Horizontally Scrollable Mobile Table Cards | Client (Student Viewer) | — | Wrapped inside `SingleChildScrollView(scrollDirection: Axis.horizontal)` with subtle edge shadows to guarantee responsive legibility on narrow viewports. |
| Visual Table Builder Dialog (Up to 20x20) | Client (Admin Editor) | — | Creator modal dialog with input validation, header toggle, and mini-grid preview before markup injection. |
</architectural_responsibility_map>

<research_summary>
## Summary

Phase 02 delivers a production-grade WYSIWYG rich text and office suite integration across all Eduverse content authoring and consumption touchpoints (Articles, Quizzes, Test Series, and Lecture Notes). Currently, the codebase already possesses a working foundation in `lib/admin/widgets/rich_document_editor.dart`, `lib/common/widgets/rich_content_viewer.dart`, `lib/admin/widgets/equation_builder.dart`, `lib/admin/widgets/tldraw_webview.dart`, and `lib/core/services/rich_text_service.dart`, backed by a 38-scenario E2E test suite (`test/e2e/rich_text_e2e_test.dart`) running 78 unit/widget assertions.

The required enhancements bridge the gap between this functional baseline and the strict user requirements outlined in Decisions D-01 through D-08. Specifically:
1. **Storage & Backward Compatibility:** Upgrade document persistence to dual-format (`contentDelta` + `contentHtml` + plain text fallback in legacy fields) across `feed_editor_screen.dart`, `quiz_editor_screen.dart`, `batch_quiz_editor_screen.dart`, and `test_series_test_editor_screen.dart`, while allowing `RichDocumentEditor` to accept legacy text and transparently upgrade documents on subsequent saves.
2. **Mathematical Notation:** Expand `EquationBuilder` from 5 presets to a categorized tabbed quick-pick palette (Algebra, Calculus, Greek, Matrices, Symbols), while ensuring student viewers in `RichContentViewer` parse both inline `$...$` and block `$$...$$` natively via `flutter_math_fork` with theme-adaptive colors.
3. **Whiteboard Diagrams:** Route diagram exports from `TldrawWebview` to Firebase Storage `/diagrams/` to prevent Firestore document bloat, embed CDN `<img src="...">` tags, and provide interactive diagram cards in the editor supporting full-screen preview, deletion, and clean replacement canvas drawing.
4. **Interactive & Responsive Tables:** Enhance the table creation dialog with header row toggling and live preview (up to 20x20), and ensure `RichContentViewer` wraps tables in horizontally scrollable cards with subtle shadow indicators and preserved minimum column widths.

**Primary recommendation:** Build upon the existing `RichDocumentEditor`, `RichContentViewer`, and `RichTextService` without rewriting core contracts; maintain all existing widget keys (`Key('editor_text_field')`, `Key('btn_insert_table')`, `Key('preset_fraction')`, etc.) so that all 38 existing E2E tests pass while implementing the D-01 to D-08 enhancements.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_math_fork` | `^0.7.2` | Canvas-native LaTeX mathematical typesetting | KaTeX-compliant rendering directly on Flutter Canvas without spawning WebView processes; instant startup, zero layout shift, low memory. |
| `flutter_widget_from_html_core` | `^0.10.6` | High-performance HTML rendering | Lightweight core HTML tree parsing into Flutter widgets; extensible via `customWidgetBuilder` and `WidgetFactory` without webview overhead. |
| `firebase_storage` | `^13.0.1` | Cloud storage for diagram and media assets | Direct, authenticated blob uploads to `/diagrams/` with CDN download URLs and automatic token generation. |
| `webview_flutter` | `^4.10.0` | Container for `tldraw` vector whiteboard editor | Runs web-based whiteboard tools on mobile and desktop platforms with full touch/stylus support. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_markdown` | `^0.7.5` | Fallback markdown renderer | Used when legacy documents without HTML snapshots are rendered in student views. |
| `cached_network_image` | `^3.4.1` | Cached network image loader | Loading CDN images and diagram snapshots with offline disk caching and shimmer placeholders. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_math_fork` | `webview_flutter` + KaTeX/MathJax | WebViews incur 200–500ms lag per equation, introduce severe CLS (Cumulative Layout Shift) in scrollable feeds, and consume 30MB+ RAM per instance. |
| Firebase Storage CDN URL for diagrams | Inline base64 SVG in Firestore | Base64 SVGs balloon Firestore document sizes toward the 1MB hard quota, degrading query latency and caching. Firebase Storage URLs keep documents under 15KB. |
| Dual-format storage | HTML-only or Delta-only | HTML-only loses cursor state and structured metadata; Delta-only requires CPU-heavy client-side AST compilation on every mobile screen render. Dual-format offers the optimal balance. |

**Installation:**
All dependencies are already declared in `pubspec.yaml` (`flutter_math_fork: any`, `flutter_widget_from_html_core: any`, `firebase_storage: ^13.0.1`, `webview_flutter: ^4.10.0`).
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure

```
lib/
├── admin/
│   ├── widgets/
│   │   ├── rich_document_editor.dart     # Core editor widget, dual-format state & diagram cards
│   │   ├── rich_editor_toolbar.dart      # Formatting toolbar, dropdowns & insertion triggers
│   │   ├── equation_builder.dart         # Categorized LaTeX palette (Algebra, Calculus, Greek, Matrices, Symbols)
│   │   ├── tldraw_webview.dart           # Whiteboard canvas & SVG export
│   │   └── find_replace_panel.dart       # Floating regex/case-sensitive find & replace
│   └── screens/
│       ├── feed_editor_screen.dart       # Article, current affairs & answer writing authoring
│       ├── quiz_editor_screen.dart       # Standalone practice quiz authoring
│       ├── batch_quiz_editor_screen.dart # Cohort batch quiz authoring
│       └── test_series_test_editor_screen.dart # Timed test question & explanation authoring
├── common/
│   └── widgets/
│       └── rich_content_viewer.dart      # Student viewer, custom WidgetFactory, math & table scroll
└── core/
    └── services/
        └── rich_text_service.dart        # LaTeX HTML parser, markdown fallback, storage upload & Firestore serializer
```

### Pattern 1: Dual-Format Serialization & Auto-Detect Upgrade (D-01, D-02)
**What:** Save both Delta JSON (`contentDelta`) and pre-rendered HTML (`contentHtml`), synchronizing a plain-text fallback into legacy fields (`content`, `description`, `questionText`). When opening existing documents lacking `contentDelta`, detect plain text or markdown from legacy fields and initialize the editor seamlessly.
**When to use:** In `RichDocumentEditor` and `RichTextService.serializeForFirestore`.

### Pattern 2: Categorized LaTeX Palette with Live Math Preview (D-03, D-04)
**What:** Categorized quick-picks organized into Algebra, Calculus, Greek, Matrices, and Symbols tabs/chips, updating an editable LaTeX text field that feeds an instant preview via `Math.tex`.
**When to use:** In `EquationBuilder`.

### Pattern 3: Diagram Firebase Storage Pipeline with CDN Image Tagging (D-05, D-06)
**What:** On whiteboard diagram export, upload SVG/PNG bytes to Firebase Storage under `/diagrams/` and embed `<img src="...">` in HTML. In the editor, parse diagram blocks into interactive preview cards offering Full-screen Preview, Replace, and Delete.
**When to use:** In `TldrawWebview`, `RichDocumentEditor`, and `RichTextService`.

### Pattern 4: Responsive Mobile Table Rendering with Scroll Shadow Indicators (D-07, D-08)
**What:** Wrap tables rendered in `RichContentViewer` inside a `SingleChildScrollView(scrollDirection: Axis.horizontal)` wrapped in a card with subtle shadow indicators. Table creation features a dialog with dimension inputs (up to 20x20), header toggle, and visual preview.
**When to use:** In `RichContentViewer` via `WidgetFactory` or `customWidgetBuilder`, and `RichDocumentEditor._insertTable`.

### Anti-Patterns to Avoid
- **Embedding raw SVG XML directly in Firestore:** Leads to document size explosion (> 1MB) and high read latency. Always upload to Firebase Storage `/diagrams/` and store the CDN URL.
- **Using WebView for math rendering in student feeds:** Causes noticeable lag, flash of unstyled content (FOUC), and memory exhaustion on mobile devices. Always use canvas-native `flutter_math_fork`.
- **Breaking existing test keys during toolbar/palette refactoring:** Modifying or deleting keys such as `btn_bold`, `btn_insert_table`, `preset_fraction`, or `table_rows_input` breaks the 38 existing E2E tests. Retain existing keys exactly as written.
- **Hardcoding black font colors in LaTeX math widgets:** Prevents equations from adapting to dark theme in student mobile view. Always bind `textStyle` to the ambient theme's text color.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mathematical typesetting | Custom Canvas text rendering or regex HTML tags | `flutter_math_fork` (`Math.tex`) | Mathematical layout requires complex TeX box layout algorithms (superscripts, subscripts, fractions, radical signs, matrices). |
| HTML DOM Parsing | Custom string splitting / RegExp replacers | `flutter_widget_from_html_core` | HTML parsing has edge cases like nested tags, unclosed elements, whitespace collapsing, and inline-block CSS layout. |
| Diagram drawing engine | Custom Flutter CustomPainter drawing tool | `tldraw` via WebView | High-performance vector drawing, shape snapping, eraser, arrow connections, and SVG export are battle-tested in `tldraw`. |
| Full-screen image zoom & pan | Custom `GestureDetector` with matrix transformations | `InteractiveViewer` | Double-tap to zoom, spring bounce-back, pan constraints, and smooth gesture physics are already solved. |
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Unescaped LaTeX Characters & Malformed Percent-Encoding in `data-latex`
**What goes wrong:** LaTeX equations containing `%`, `&`, `\`, or `#` fail to render or crash with `FormatException` when decoded.
**Why it happens:** In HTML, `data-latex` attributes must be URL-encoded (`Uri.encodeComponent`), but special characters can produce invalid percent escapes (e.g. `%E2%82`).
**How to avoid:** Always wrap `Uri.decodeComponent` in a `try-catch` block (as verified in test B21), falling back to the raw attribute value if decoding fails.
**Warning signs:** Red italic error text or empty boxes appearing instead of mathematical formulas in student viewer.

### Pitfall 2: Firestore Document Size Exceeded by Diagram Vectors
**What goes wrong:** Firestore write fails with `firestore/document-too-large` (exceeding the 1,048,576 bytes limit).
**Why it happens:** Complex whiteboard diagrams with hundreds of paths generate large SVG XML files (often 500KB–2MB).
**How to avoid:** Enforce D-05: Whiteboard SVG/PNG exports must be uploaded directly to Firebase Storage (`/diagrams/`), embedding only `<img src="..." />` tags in the document HTML.
**Warning signs:** Save operations failing when educators add multiple diagrams to a single lecture or quiz explanation.

### Pitfall 3: Mobile Viewport Overflow & Layout Truncation on Wide Tables
**What goes wrong:** 10+ column tables get compressed into unreadable narrow columns, causing text overlap or horizontal overflow exceptions (`RenderFlex overflowed by X pixels`).
**Why it happens:** Tables default to intrinsic fitting within parent width constraints without scroll boundaries.
**How to avoid:** Enforce D-07: Wrap rendered tables in `SingleChildScrollView(scrollDirection: Axis.horizontal)` with `minWidth: 80px` per column and visual scroll shadow indicators.
**Warning signs:** Yellow-and-black striped overflow banners appearing on mobile screens when viewing tables.

### Pitfall 4: Loss of Editor State When Opening Legacy Documents
**What goes wrong:** An existing quiz or article has text in `description` or `questionText`, but opening it in `RichDocumentEditor` displays a blank editor field.
**Why it happens:** `RichDocumentEditor` only checks `initialDeltaJson` and `initialHtml`. If both are null on legacy documents, `initialContent` defaults to empty string.
**How to avoid:** Enforce D-02: Pass `initialText: legacyField` to `RichDocumentEditor` and prioritize `initialDeltaJson -> initialHtml -> initialText`.
**Warning signs:** Creators complaining that existing test questions "disappear" when clicking Edit.

### Pitfall 5: Invisible Math Equations in Dark Mode
**What goes wrong:** LaTeX formulas rendered with `flutter_math_fork` appear black on black backgrounds when students use dark mode.
**Why it happens:** `Math.tex` defaults to `Colors.black` if no `textStyle` or explicit `color` is provided.
**How to avoid:** In `RichContentViewer`, supply `textStyle: TextStyle(fontSize: 16.0, color: Theme.of(context).textTheme.bodyMedium?.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87))`.
**Warning signs:** Formula areas displaying empty black boxes when dark theme is activated.
</common_pitfalls>

<code_examples>
## Code Examples

### 1. Categorized LaTeX Symbol Palette with Live Preview (D-03)
Organize presets into 5 distinct categories (Algebra, Calculus, Greek, Matrices, Symbols), keeping the existing 5 legacy preset keys (`preset_fraction`, `preset_sqrt`, `preset_integral`, `preset_pi`, `preset_sum`) intact for test backwards-compatibility while rendering ChoiceChips for category switching.

### 2. Table Creation Dialog with Dimension Validation & Header Toggle (D-08)
Support 1-20 rows and 1-20 columns with validation, a checkbox for header row formatting, and clear error text (`table_error_text`).

### 3. Student Mobile Table Card with Horizontal Scrolling & Shadows (D-07)
Extend `WidgetFactory` in `flutter_widget_from_html_core` to intercept `table` elements, wrapping them inside a `Card` with a horizontal `SingleChildScrollView` and subtle right-edge shadow gradient.

### 4. Interactive Diagram Cards in Editor (D-06)
Render interactive preview cards in the editor for inserted diagrams with buttons for Fullscreen Preview, Replace Diagram (launching canvas), and Delete.
</code_examples>

<sota_updates>
## State of the Art (2024-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| In-memory base64 / SVG strings embedded in Firestore | Pre-uploaded CDN assets in Firebase Storage (`/diagrams/`) | 2024–2025 | Eliminates 1MB document quota failures and keeps Firestore read payloads minimal. |
| In-app WebView Math rendering (MathJax/KaTeX JS) | Flutter canvas-native rendering (`flutter_math_fork`) | 2024 | Eliminates async WebView layout shifts (CLS) and reduces memory from 30MB+ per page to near-zero. |
| Unconstrained HTML table layouts on mobile | Horizontally scrollable cards with edge shadow hints | 2025 | Solves text squishing on compact screens (360px–412px width). |
| Static JSON editor payloads requiring full migrations | Dual-format (`contentDelta` + `contentHtml`) with transparent upgrade | 2025 | Seamless backward compatibility with legacy documents without complex background database migrations. |
</sota_updates>

<open_questions>
## Open Questions

1. **Storage Bucket Rules for Public Diagram Access**
   - Ensure `/diagrams/{allPaths=**}` allows public read while restricting write to authenticated admins.
2. **Full-screen Pinch-to-Zoom Interaction on Diagrams**
   - Use Flutter's native `InteractiveViewer` inside a `showDialog` modal for zero-dependency full-screen preview.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `lib/admin/widgets/rich_document_editor.dart` — Existing WYSIWYG editor implementation, table blocks, autosave timer, and toolbar bindings.
- `lib/common/widgets/rich_content_viewer.dart` — Existing student viewer, `HtmlWidget` configuration, and `flutter_math_fork` integration.
- `lib/admin/widgets/equation_builder.dart` — Existing LaTeX builder dialog and preset chips.
- `lib/admin/widgets/tldraw_webview.dart` — Whiteboard canvas integration and SVG export.
- `lib/core/services/rich_text_service.dart` — Serialization, math parsing, and media upload mocks.
- `test/e2e/rich_text_e2e_test.dart` — 38 E2E test scenarios validating formatting, math, tables, auto-save, and diagrams (78 passed assertions).
- `flutter_widget_from_html_core` (v0.10.6) source code in `.pub-cache` — Inspected `TagTable`, `HtmlTable`, `BuildOp`, and `WidgetFactory` extension points.
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Flutter rich text editing & rendering (`super_editor`, `flutter_widget_from_html_core`, `flutter_math_fork`, `firebase_storage`, `webview_flutter`)
- Ecosystem: Admin authoring tools, student mobile viewers, LaTeX math typography, whiteboard diagramming, Firestore dual-format persistence
- Patterns: Dual-format storage, categorized LaTeX symbol quick-picks, Firebase Storage asset upload pipeline, responsive mobile tables
- Pitfalls: Firestore 1MB document quota, percent-encoding in LaTeX attributes, mobile horizontal table overflow, dark theme contrast

**Confidence breakdown:**
- Standard stack: HIGH — All libraries are already installed in `pubspec.yaml` and verified with working tests.
- Architecture: HIGH — Clear mapping from user decisions D-01 through D-08 to existing codebase structures.
- Pitfalls: HIGH — Root causes identified in existing tests (B1–B30) and confirmed via package source code inspection.
- Code examples: HIGH — Tested patterns directly compatible with Flutter 3.47 / Dart 3.13.

**Research date:** 2026-09-20
**Valid until:** 2026-10-20 (30 days)
</metadata>

---

*Phase: 02-rich-text-office-suite-integration*
*Research completed: 2026-09-20*
*Ready for planning: yes*
