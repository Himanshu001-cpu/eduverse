# Project: Comprehensive Rich Text Editing System (Mini Office Suite)

## Architecture
The comprehensive rich text editing system replaces raw Markdown fields in the Eduverse admin panel with a structured WYSIWYG editor using `super_editor`. It features point-and-click LaTeX equations, interactive tables, a whiteboard diagramming component via an embedded `tldraw` WebView, and media uploads to Firebase Storage. 

Content is saved in Firestore in a dual-format:
1. **Delta JSON**: A structured document layout format for reloading/editing.
2. **HTML Snapshot**: A pre-rendered HTML document for fast read performance.

On the student side, the `RichContentViewer` renders the pre-rendered HTML using `flutter_widget_from_html_core` with custom widget factories for equations (LaTeX), diagrams (SVGs/Network Images), and tables.

## Code Layout
- Custom Editor Widget: `lib/admin/widgets/rich_document_editor.dart`
- Custom Viewer Widget: `lib/common/widgets/rich_content_viewer.dart`
- Toolbar & Find/Replace Panel: `lib/admin/widgets/rich_editor_toolbar.dart` and `lib/admin/widgets/find_replace_panel.dart`
- Equation Builder: `lib/admin/widgets/equation_builder.dart`
- Diagram/tldraw WebView: `lib/admin/widgets/tldraw_webview.dart`
- Services/Helpers: `lib/core/services/rich_text_service.dart` (Firestore serializing, Firebase Storage uploads, LaTeX parser)
- Migration Script: `scripts/migrate_markdown_to_delta.js`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Dependency Setup & E2E Testing Infrastructure | Setup dependencies in `pubspec.yaml`, write comprehensive E2E tests (Tiers 1-4) in `test/e2e/rich_text_e2e_test.dart`, publish `TEST_READY.md`. | None | DONE |
| 2 | Rich Text Editor Core & Formatting Toolbar | Create `RichDocumentEditor` using `super_editor`, implement full formatting toolbar, auto-save (1-minute debounced), and Find & Replace floating panel with regex support. | M1 | IN_PROGRESS (impl: 38fd0eea-59ac-45ae-8b38-179737f98cac) |
| 3 | Custom Elements Integration | Integrate inline images, native editable tables (max 20x20), LaTeX math equations builder, and tldraw whiteboard diagramming WebView (Firebase Hosting + Storage). | M2 | PLANNED |
| 4 | Dual-Format Storage, Student Viewer & Migration | Implement Delta JSON and HTML Firestore serialization, student `RichContentViewer` with custom widget factories, and run migration script. | M3 | PLANNED |
| 5 | Code Cleanup & Verification | Remove legacy `FormattedTextField`, run final E2E test suite (Tiers 1-4), execute Tier 5 adversarial testing, and perform Forensic Audit verification. | M4 | PLANNED |

## Interface Contracts

### RichDocumentEditor Widget
```dart
class RichDocumentEditor extends StatefulWidget {
  final String? initialDeltaJson;
  final String? initialHtml;
  final String labelText;
  final String? hintText;
  final void Function(String deltaJson, String html) onSave;
  
  const RichDocumentEditor({
    super.key,
    this.initialDeltaJson,
    this.initialHtml,
    required this.labelText,
    this.hintText,
    required this.onSave,
  });
}
```

### RichContentViewer Widget
```dart
class RichContentViewer extends StatelessWidget {
  final String? htmlContent;
  final String? legacyMarkdown; // Fallback for backward compatibility
  
  const RichContentViewer({
    super.key,
    this.htmlContent,
    this.legacyMarkdown,
  });
}
```
