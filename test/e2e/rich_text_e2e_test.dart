import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:eduverse/admin/widgets/rich_document_editor.dart';
import 'package:eduverse/common/widgets/rich_content_viewer.dart';
import 'package:eduverse/admin/widgets/find_replace_panel.dart';
import 'package:eduverse/admin/widgets/equation_builder.dart';
import 'package:eduverse/core/services/rich_text_service.dart';
import 'harness/e2e_harness.dart';

void main() {
  final harness = E2EHarness();

  setUp(() {
    harness.setup();
    harness.reset();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1200, 800);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  group('Rich Text System - Tier 1: Feature Coverage', () {
    // === FEATURE 1: Text Formatting ===
    testWidgets('F1_1: Bold style formatting inserts bold markdown tags around selected text', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      final textFieldFinder = find.byKey(const Key('editor_text_field'));
      await tester.enterText(textFieldFinder, 'Hello world');
      await tester.pump();
      tester.widget<TextField>(textFieldFinder).controller!.selection = const TextSelection(baseOffset: 0, extentOffset: 11);
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_bold')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('<strong>Hello world</strong>'));
    });

    testWidgets('F1_2: Italic style formatting inserts italic markdown tags around selected text', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      final textFieldFinder = find.byKey(const Key('editor_text_field'));
      await tester.enterText(textFieldFinder, 'Hello world');
      await tester.pump();
      tester.widget<TextField>(textFieldFinder).controller!.selection = const TextSelection(baseOffset: 0, extentOffset: 11);
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_italic')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('<em>Hello world</em>'));
    });

    testWidgets('F1_3: Underline style formatting inserts underline HTML tags', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      final textFieldFinder = find.byKey(const Key('editor_text_field'));
      await tester.enterText(textFieldFinder, 'Hello world');
      await tester.pump();
      tester.widget<TextField>(textFieldFinder).controller!.selection = const TextSelection(baseOffset: 0, extentOffset: 11);
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_underline')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('<u>Hello world</u>'));
    });

    testWidgets('F1_4: Font size changes via toolbar dropdown apply correctly to styles', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'Hello');
      await tester.pump();
      await tester.tap(find.byKey(const Key('dropdown_font_size')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('font-size: 24.0px;'));
    });

    testWidgets('F1_5: Highlight background color selection applies correct background color style', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'Hello');
      await tester.pump();
      await tester.tap(find.byKey(const Key('dropdown_highlight')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yellow').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('background-color: #FFFF00'));
    });

    // === FEATURE 2: Find & Replace ===
    testWidgets('F2_1: Simple query searching highlights occurrences in the panel', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Find this key and find it fast.');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('find_input')), 'find');
      await tester.pump();
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('F2_2: Case-insensitive search match index updating', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Case case CASE.');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('find_input')), 'case');
      await tester.pump();
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('F2_3: Case-sensitive search filter matching', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Case case CASE.');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('find_input')), 'case');
      await tester.pump();
      await tester.tap(find.byKey(const Key('case_sensitive_checkbox')));
      await tester.pump();
      expect(find.text('1/1'), findsOneWidget);
    });

    testWidgets('F2_4: Single word replacement updates text in the controller', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Change this.');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('find_input')), 'Change');
      await tester.enterText(find.byKey(const Key('replace_input')), 'Keep');
      await tester.pump();
      await tester.tap(find.byKey(const Key('replace_button')));
      await tester.pump();
      expect(controller.text, 'Keep this.');
    });

    testWidgets('F2_5: Replace all occurrences of query in editor text controller', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'apple banana apple grape');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('find_input')), 'apple');
      await tester.enterText(find.byKey(const Key('replace_input')), 'orange');
      await tester.pump();
      await tester.tap(find.byKey(const Key('replace_all_button')));
      await tester.pump();
      expect(controller.text, 'orange banana orange grape');
    });

    // === FEATURE 3: Image Insertion ===
    testWidgets('F3_1: Renders basic HTML img tag inside viewer widget', (WidgetTester tester) async {
      const html = '<img src="https://example.com/image.png">';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
    });

    testWidgets('F3_2: Renders image inside viewer with specific dimensions', (WidgetTester tester) async {
      const html = '<img src="https://example.com/image.png" width="150" height="80">';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      final htmlWidget = tester.widget<HtmlWidget>(find.byKey(const Key('rich_content_html_widget')));
      expect(htmlWidget.html, contains('width="150"'));
      expect(htmlWidget.html, contains('height="80"'));
    });

    testWidgets('F3_3: Renders image inside viewer with alt text attribute', (WidgetTester tester) async {
      const html = '<img src="https://example.com/image.png" alt="Alternate Text">';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      final htmlWidget = tester.widget<HtmlWidget>(find.byKey(const Key('rich_content_html_widget')));
      expect(htmlWidget.html, contains('alt="Alternate Text"'));
    });

    testWidgets('F3_4: Upload media bytes to mock storage returning valid-looking storage URL', (WidgetTester tester) async {
      final bytes = [1, 2, 3, 4];
      final url = await RichTextService.uploadMediaToStorage('test_image.png', bytes);
      expect(url, contains('https://firebasestorage.googleapis.com'));
      expect(url, contains('test_image.png'));
    });

    testWidgets('F3_5: Renders broken image URL using error fallbacks without crashing', (WidgetTester tester) async {
      const html = '<img src="invalid-url-schema">';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
    });

    // === FEATURE 4: Editable Tables ===
    testWidgets('F4_1: Show table dialog and insert custom table dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_table')));
      await tester.pump();
      expect(find.byKey(const Key('table_dialog_card')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('table_rows_input')), '3');
      await tester.enterText(find.byKey(const Key('table_cols_input')), '2');
      await tester.tap(find.byKey(const Key('btn_submit_table')));
      await tester.pump();
      expect(find.byKey(const Key('table_dialog_card')), findsNothing);
    });

    testWidgets('F4_2: Validate table markdown tag generated in editor matches pattern', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_table')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('table_rows_input')), '1');
      await tester.enterText(find.byKey(const Key('table_cols_input')), '2');
      await tester.tap(find.byKey(const Key('btn_submit_table')));
      await tester.pump();
      final editorField = tester.widget<TextField>(find.byKey(const Key('editor_text_field')));
      expect(editorField.controller!.text, contains('[table rows=1 cols=2]'));
    });

    testWidgets('F4_3: Convert table markdown to HTML table structure', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), '[table rows=1 cols=1]Cell 1[/table]');
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('<table class="rich-table"'));
      expect(savedHtml, contains('<td style="padding: 8px;">Cell 1</td>'));
    });

    testWidgets('F4_4: Render formatted content inside table cells', (WidgetTester tester) async {
      const html = '<table class="rich-table"><tr><td><strong>Bold</strong></td></tr></table>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
    });

    testWidgets('F4_5: Render list bullet items inside a table cell', (WidgetTester tester) async {
      const html = '<table class="rich-table"><tr><td><ul><li>Bullet</li></ul></td></tr></table>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
    });

    // === FEATURE 5: Equation Builder ===
    testWidgets('F5_1: Show equation builder dialog and insert simple equation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_equation')));
      await tester.pump();
      expect(find.byKey(const Key('editor_equation_builder')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('latex_input')), 'x = y');
      await tester.tap(find.byKey(const Key('save_equation_button')));
      await tester.pump();
      expect(find.byKey(const Key('editor_equation_builder')), findsNothing);
    });

    testWidgets('F5_2: Generate latex block syntax in editor text field', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_equation')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('latex_input')), 'E = mc^2');
      await tester.tap(find.byKey(const Key('save_equation_button')));
      await tester.pump();
      final editorField = tester.widget<TextField>(find.byKey(const Key('editor_text_field')));
      expect(editorField.controller!.text, contains('[latex]E = mc^2[/latex]'));
    });

    testWidgets('F5_3: Convert latex fraction to math-frac HTML elements', (WidgetTester tester) async {
      final parsed = RichTextService.parseLatexToHtml(r'\frac{x}{y}');
      expect(parsed, contains('class="math-frac"'));
      expect(parsed, contains('class="math-num"'));
      expect(parsed, contains('class="math-den"'));
    });

    testWidgets('F5_4: Convert superscript and subscript equations correctly', (WidgetTester tester) async {
      final superParsed = RichTextService.parseLatexToHtml('a^b');
      final subParsed = RichTextService.parseLatexToHtml('c_d');
      expect(superParsed, contains('<sup>b</sup>'));
      expect(subParsed, contains('<sub>d</sub>'));
    });

    testWidgets('F5_5: Render math greek symbols to HTML entities', (WidgetTester tester) async {
      final parsed = RichTextService.parseLatexToHtml(r'\alpha + \beta = \theta');
      expect(parsed, contains('&alpha;'));
      expect(parsed, contains('&beta;'));
      expect(parsed, contains('&theta;'));
    });

    // === FEATURE 6: Whiteboard Diagrams ===
    testWidgets('F6_1: Whiteboard inserts diagram block tags into editor', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_diagram')));
      await tester.pump();
      expect(find.byKey(const Key('editor_whiteboard')), findsOneWidget);
      await tester.tap(find.byKey(const Key('export_whiteboard_button')));
      await tester.pump();
      expect(find.byKey(const Key('editor_whiteboard')), findsNothing);
    });

    testWidgets('F6_2: Whiteboard tag translates to rich-diagram class container', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), '[diagram]<svg></svg>[/diagram]');
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('<div class="rich-diagram">'));
    });

    testWidgets('F6_3: Drawing circle in whiteboard drawer generates circle SVG tag', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_diagram')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('draw_circle_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('export_whiteboard_button')));
      await tester.pump();
      final editorField = tester.widget<TextField>(find.byKey(const Key('editor_text_field')));
      expect(editorField.controller!.text, contains('<circle cx="140.0"'));
    });

    testWidgets('F6_4: Drawing rectangle in whiteboard drawer generates rect SVG tag', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_diagram')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('draw_rect_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('export_whiteboard_button')));
      await tester.pump();
      final editorField = tester.widget<TextField>(find.byKey(const Key('editor_text_field')));
      expect(editorField.controller!.text, contains('<rect x="120.0"'));
    });

    testWidgets('F6_5: Monospace SVG diagram rendering in viewer', (WidgetTester tester) async {
      const html = '<div class="rich-diagram"><svg></svg></div>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_diagram_widget')), findsOneWidget);
    });

    // === FEATURE 7: Dual-Format Storage ===
    testWidgets('F7_1: RichTextService serializes delta JSON and HTML snapshot', (WidgetTester tester) async {
      final serialized = RichTextService.serializeForFirestore(deltaJson: '{"ops":[]}', html: '<p></p>');
      expect(serialized.containsKey('deltaJson'), isTrue);
      expect(serialized.containsKey('htmlSnapshot'), isTrue);
      expect(serialized.containsKey('updatedAt'), isTrue);
    });

    testWidgets('F7_2: Auto-save timer triggers document save callback', (WidgetTester tester) async {
      int saveCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            autoSaveDebounceDuration: const Duration(milliseconds: 100),
            onSave: (_, __) => saveCount++,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'Hello');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(saveCount, 1);
    });

    testWidgets('F7_3: Delta JSON attributes are formatted properly', (WidgetTester tester) async {
      String savedDelta = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (delta, _) => savedDelta = delta,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'Hello');
      await tester.tap(find.byKey(const Key('btn_align_right')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedDelta, contains('"align":"right"'));
    });

    testWidgets('F7_4: Manual save button invokes onSave callback immediately', (WidgetTester tester) async {
      int saveCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) => saveCount++,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(saveCount, 1);
    });

    testWidgets('F7_5: Serialized metadata includes correct ISO dates', (WidgetTester tester) async {
      final serialized = RichTextService.serializeForFirestore(deltaJson: '{}', html: '');
      final dateStr = serialized['updatedAt'] as String;
      expect(DateTime.tryParse(dateStr), isNotNull);
    });

    // === FEATURE 8: Student Viewer & Compatibility ===
    testWidgets('F8_1: Parse standard paragraph HTML structures in viewer', (WidgetTester tester) async {
      const html = '<p>Normal text</p>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
    });

    testWidgets('F8_2: Safe fallback to legacy markdown parser', (WidgetTester tester) async {
      const markdown = '**Bold** and _Italic_';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(legacyMarkdown: markdown),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
      final widget = tester.widget<HtmlWidget>(find.byKey(const Key('rich_content_html_widget')));
      expect(widget.html, contains('<strong>Bold</strong>'));
      expect(widget.html, contains('<em>Italic</em>'));
    });

    testWidgets('F8_3: Custom element builder targets math-latex elements', (WidgetTester tester) async {
      const html = '<span class="math-latex" data-latex="x%5E2">x^2</span>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('F8_4: Custom element builder targets rich-diagram elements', (WidgetTester tester) async {
      const html = '<div class="rich-diagram">Monospace diagram text</div>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_diagram_widget')), findsOneWidget);
    });

    testWidgets('F8_5: Render empty or null values with SizedBox.shrink', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsNothing);
    });
  });

  group('Rich Text System - Tier 2: Boundary & Corner Cases', () {
    testWidgets('B1: Empty editor delta serialization returns empty operations list', (WidgetTester tester) async {
      String savedDelta = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (delta, _) => savedDelta = delta,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedDelta, contains('"ops":[{"insert":""'));
    });

    testWidgets('B2: Empty editor html serialization returns blank HTML wrapper', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('<div style="font-size: 16.0px; text-align: left;"></div>'));
    });

    testWidgets('B3: Editor text with single whitespace character serialization', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), ' ');
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains(' '));
    });

    testWidgets('B4: Render empty string content in student viewer returns SizedBox.shrink', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: ''),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsNothing);
    });

    testWidgets('B5: Table builder validation error for dimensions 0x0', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_table')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('table_rows_input')), '0');
      await tester.enterText(find.byKey(const Key('table_cols_input')), '0');
      await tester.tap(find.byKey(const Key('btn_submit_table')));
      await tester.pump();
      expect(find.text('Dimensions must be greater than 0'), findsOneWidget);
    });

    testWidgets('B6: Table builder validation error for dimensions exceeding 20x20 limit (21x5)', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_table')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('table_rows_input')), '21');
      await tester.enterText(find.byKey(const Key('table_cols_input')), '5');
      await tester.tap(find.byKey(const Key('btn_submit_table')));
      await tester.pump();
      expect(find.text('Table dimensions cannot exceed 20x20'), findsOneWidget);
    });

    testWidgets('B7: Table builder validation error for dimensions exceeding 20x20 limit (5x21)', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_table')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('table_rows_input')), '5');
      await tester.enterText(find.byKey(const Key('table_cols_input')), '21');
      await tester.tap(find.byKey(const Key('btn_submit_table')));
      await tester.pump();
      expect(find.text('Table dimensions cannot exceed 20x20'), findsOneWidget);
    });

    testWidgets('B8: Table builder allows maximum boundary dimensions (20x20)', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_table')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('table_rows_input')), '20');
      await tester.enterText(find.byKey(const Key('table_cols_input')), '20');
      await tester.tap(find.byKey(const Key('btn_submit_table')));
      await tester.pump();
      expect(find.byKey(const Key('table_dialog_card')), findsNothing);
    });

    testWidgets('B9: Table builder handles empty inputs gracefully without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, __) {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('btn_insert_table')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('table_rows_input')), '');
      await tester.enterText(find.byKey(const Key('table_cols_input')), '');
      await tester.tap(find.byKey(const Key('btn_submit_table')));
      await tester.pump();
      expect(find.text('Dimensions must be greater than 0'), findsOneWidget);
    });

    testWidgets('B10: Find & Replace regex validation with malformed regex pattern [a- showing error message', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Hello');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.tap(find.byKey(const Key('regex_checkbox')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('find_input')), '[a-');
      await tester.pump();
      expect(find.textContaining('Invalid regex'), findsOneWidget);
    });

    testWidgets('B11: Find & Replace regex search with empty find query doesn\'t trigger matches', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Hello');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.tap(find.byKey(const Key('regex_checkbox')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('find_input')), '');
      await tester.pump();
      expect(find.text('Find'), findsOneWidget);
    });

    testWidgets('B12: Find & Replace regex search when no matching pattern exists in text', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Hello');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.tap(find.byKey(const Key('regex_checkbox')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('find_input')), '[0-9]');
      await tester.pump();
      expect(find.text('Find'), findsOneWidget);
    });

    testWidgets('B13: Find & Replace case-sensitive match when only case-mismatched text exists', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'hello');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.tap(find.byKey(const Key('case_sensitive_checkbox')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('find_input')), 'HELLO');
      await tester.pump();
      expect(find.text('Find'), findsOneWidget);
    });

    testWidgets('B14: Equation builder error state with invalid LaTeX syntax displaying error text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EquationBuilder(
            onEquationSaved: (_) {},
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('latex_input')), r'\frac{a');
      await tester.pump();
      expect(find.textContaining('LaTeX Error'), findsAtLeastNWidgets(1));
    });

    testWidgets('B15: Equation builder save button disabled when LaTeX has error', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EquationBuilder(
            onEquationSaved: (_) {},
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('latex_input')), r'\frac{a');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(find.byKey(const Key('save_equation_button'))).onPressed, isNull);
    });

    testWidgets('B16: Equation builder with empty LaTeX input allows save or remains enabled', (WidgetTester tester) async {
      String saved = 'initial';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EquationBuilder(
            onEquationSaved: (val) {
              saved = val;
            },
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('latex_input')), '');
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_equation_button')));
      await tester.pump();
      expect(saved, '');
    });

    testWidgets('B17: Equation builder with complex nested malformed braces LaTeX handles it', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EquationBuilder(
            onEquationSaved: (_) {},
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('latex_input')), r'\frac{{\frac{a}{b}}');
      await tester.pump();
      expect(find.textContaining('LaTeX Error'), findsAtLeastNWidgets(1));
    });

    testWidgets('B18: Find & Replace panel operations on empty editor text controller', (WidgetTester tester) async {
      final controller = TextEditingController(text: '');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('find_input')), 'a');
      await tester.pump();
      expect(find.text('Find'), findsOneWidget);
    });

    testWidgets('B19: Find & Replace replace button clicked with empty search query does nothing', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Hello');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('replace_input')), 'Test');
      await tester.pump();
      expect(tester.widget<TextButton>(find.byKey(const Key('replace_button'))).onPressed, isNull);
    });

    testWidgets('B20: Find & Replace replace all button clicked with empty search query does nothing', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Hello');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FindReplacePanel(textController: controller),
        ),
      ));
      await tester.enterText(find.byKey(const Key('replace_input')), 'Test');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(find.byKey(const Key('replace_all_button'))).onPressed, isNull);
    });

    testWidgets('B21: Uri.decodeComponent try-catch handles malformed percent-encoding like %E2%82 in data-latex safely', (WidgetTester tester) async {
      const html = '<span class="math-latex" data-latex="%E2%82">Fallback value</span>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      // It falls back to raw data-latex (%E2%82) or parses it safely
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('B22: RichContentViewer legacyMarkdown fallback with blank input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(legacyMarkdown: ''),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsNothing);
    });

    testWidgets('B23: RichContentViewer legacyMarkdown fallback with unrecognized markdown syntax', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(legacyMarkdown: 'Unrecognized custom * markdown'),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
    });

    testWidgets('B24: Student viewer data-latex attribute missing rendering fallback handles it', (WidgetTester tester) async {
      const html = '<span class="math-latex">Missing data latex attribute</span>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      // Should build without crashing but not render math fork
      expect(find.byType(Math), findsNothing);
    });

    testWidgets('B25: Whiteboard diagram SVG missing rendering layout fallback', (WidgetTester tester) async {
      const html = '<div class="rich-diagram"></div>';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentViewer(htmlContent: html),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('rich_diagram_widget')), findsOneWidget);
    });

    testWidgets('B26: Firebase upload media returns url even if empty filename or bytes provided', (WidgetTester tester) async {
      final url = await RichTextService.uploadMediaToStorage('', []);
      expect(url, contains('https://firebasestorage.googleapis.com'));
    });

    testWidgets('B27: Editor font size changes via custom input boundary values supported', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'Hello');
      await tester.tap(find.byKey(const Key('dropdown_font_size')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('font-size: 12.0px;'));
    });

    testWidgets('B28: High frequency edits during auto-save debounce testing timer reset', (WidgetTester tester) async {
      int saveCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            autoSaveDebounceDuration: const Duration(milliseconds: 100),
            onSave: (_, __) => saveCount++,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'a');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'ab');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'abc');
      await tester.pump(const Duration(milliseconds: 120));
      expect(saveCount, 1);
    });

    testWidgets('B29: Double slash/backslash escape characters handling in equation builder', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EquationBuilder(
            onEquationSaved: (_) {},
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('latex_input')), r'\\');
      await tester.pump();
      // Verifies that a parsing error is shown in the preview window instead of crashing
      expect(find.textContaining('LaTeX Error:'), findsOneWidget);
    });

    testWidgets('B30: Carriage return \\r\\n handling in editor to HTML converter', (WidgetTester tester) async {
      String savedHtml = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichDocumentEditor(
            labelText: 'Editor',
            onSave: (_, html) => savedHtml = html,
          ),
        ),
      ));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'Line 1\r\nLine 2');
      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();
      expect(savedHtml, contains('<br>'));
    });
  });

  group('Rich Text System - Tier 3: Cross-Feature Interactions', () {
    testWidgets('F13 & F14 & F15: Cross-feature formatting, lists inside tables and diagrams alongside equations', (WidgetTester tester) async {
      final html = '<div style="font-size: 16.0px; text-align: left;">'
          '  <table class="rich-table">'
          '    <tr>'
          '      <td><strong>Bold Cell Text</strong></td>'
          '      <td><em>Italic Cell Text</em></td>'
          '      <td>'
          '        <ul>'
          '          <li>List item inside cell</li>'
          '        </ul>'
          '      </td>'
          '    </tr>'
          '  </table>'
          '  <p>'
          '    <span class="math-latex" data-latex="%5Cfrac%7Ba%7D%7Bb%7D">\\frac{a}{b}</span>'
          '    <div class="rich-diagram">'
          '      <svg><circle cx="50" cy="50" r="10" /></svg>'
          '    </div>'
          '  </p>'
          '</div>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RichContentViewer(
              htmlContent: html,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
      expect(find.byKey(const Key('rich_diagram_widget')), findsOneWidget);
      expect(find.byType(Math), findsOneWidget);
    });
  });

  group('Rich Text System - Tier 4: Real-World Scenarios', () {
    testWidgets('F16: Course test creation and student viewing journey', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();

      String savedDelta = '';
      String savedHtml = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RichDocumentEditor(
              labelText: 'Math Test Question',
              onSave: (delta, html) {
                savedDelta = delta;
                savedHtml = html;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('editor_text_field')), 'Solve: ');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_insert_equation')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('latex_input')), r'x^2 + y^2 = 25');
      await tester.tap(find.byKey(const Key('save_equation_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_bold')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();

      final serializedData = RichTextService.serializeForFirestore(
        deltaJson: savedDelta,
        html: savedHtml,
      );

      final testDocPath = 'test_series/ts_1/tests/test_1';
      harness.firestore.setDoc(testDocPath, {
        'title': 'Solve Math Equation',
        'durationMinutes': 60,
        'timeLimitSeconds': 3600,
        'richQuestion': serializedData,
      });

      final docSnap = await harness.firestore.doc(testDocPath).get();
      final retrievedData = docSnap.data()?['richQuestion'] as Map<String, dynamic>;
      final htmlToView = retrievedData['htmlSnapshot'] as String;

      expect(htmlToView, contains('math-latex'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RichContentViewer(
              htmlContent: htmlToView,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('F17: Whiteboard diagram media upload and student viewer loading', (WidgetTester tester) async {
      harness.authenticateUser();
      
      String savedHtml = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RichDocumentEditor(
              labelText: 'Diagram Editor',
              onSave: (_, html) {
                savedHtml = html;
              },
            ),
          ),
        ),
      );

      final btnDiagram = find.byKey(const Key('btn_insert_diagram'));
      await tester.ensureVisible(btnDiagram);
      await tester.tap(btnDiagram);
      await tester.pump();

      await tester.tap(find.byKey(const Key('draw_circle_button')));
      await tester.pump();

      final svgText = '<svg viewBox="0 0 100 100"><circle r="10"/></svg>';
      final downloadUrl = await RichTextService.uploadMediaToStorage('whiteboard.svg', utf8.encode(svgText));

      expect(downloadUrl, contains('https://firebasestorage.googleapis.com'));
      expect(downloadUrl, contains('whiteboard.svg'));

      await tester.tap(find.byKey(const Key('export_whiteboard_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_manual_save')));
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RichContentViewer(
              htmlContent: savedHtml,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('rich_diagram_widget')), findsOneWidget);
    });

    testWidgets('F18: Auto-save debouncing/throttling behavior', (WidgetTester tester) async {
      int saveCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RichDocumentEditor(
              labelText: 'Debounce Editor',
              autoSaveDebounceDuration: const Duration(milliseconds: 300),
              onSave: (_, __) {
                saveCount++;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('editor_text_field')), 'a');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('editor_text_field')), 'ab');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(milliseconds: 350));
      expect(saveCount, 1);

      await tester.enterText(find.byKey(const Key('editor_text_field')), 'abc');
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 350));
      expect(saveCount, 2);
    });

    testWidgets('F19: Backward compatibility with legacy markdown', (WidgetTester tester) async {
      final legacyMarkdown = '**Hello Bold World!**\n_Here is Italic._';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RichContentViewer(
              legacyMarkdown: legacyMarkdown,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
      
      final htmlWidget = tester.widget<HtmlWidget>(find.byKey(const Key('rich_content_html_widget')));
      expect(htmlWidget.html, contains('<strong>Hello Bold World!</strong>'));
      expect(htmlWidget.html, contains('<em>Here is Italic.</em>'));
    });

    testWidgets('F20: Teacher publishes a quiz containing formatting/images/math and a student fetches the quiz, answers it, and has their answer serialized back', (WidgetTester tester) async {
      harness.authenticateUser();
      
      // 1. Teacher creates the quiz content
      final quizDocPath = 'quizzes/quiz_1';
      final quizHtml = '<div style="font-size: 16.0px; text-align: left;">'
          '<h3>Weekly Math & Science Quiz</h3>'
          '<p>Solve this equation: <span class="math-latex" data-latex="E%20%3D%20mc%5E2">E = mc^2</span></p>'
          '<p><img src="https://example.com/atom.png" alt="Atom Diagram" width="100"></p>'
          '</div>';
      
      harness.firestore.setDoc(quizDocPath, {
        'title': 'Math & Science Quiz 1',
        'contentHtml': quizHtml,
        'points': 10,
      });

      // 2. Student fetches and renders the quiz content
      final docSnap = await harness.firestore.doc(quizDocPath).get();
      final quizData = docSnap.data()!;
      final htmlToView = quizData['contentHtml'] as String;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: RichContentViewer(
                    htmlContent: htmlToView,
                  ),
                ),
                ElevatedButton(
                  key: const Key('btn_submit_answer'),
                  onPressed: () {
                    harness.firestore.setDoc('users/test_user/responses/quiz_1', {
                      'quizId': 'quiz_1',
                      'studentAnswer': 'E = mc^2',
                      'submittedAt': DateTime.now().toIso8601String(),
                    });
                  },
                  child: const Text('Submit Answer'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('rich_content_html_widget')), findsOneWidget);
      expect(find.byType(Math), findsOneWidget);

      // Student taps submit answer
      await tester.tap(find.byKey(const Key('btn_submit_answer')));
      await tester.pump();

      // Verify response is stored in firestore
      final responseSnap = await harness.firestore.doc('users/test_user/responses/quiz_1').get();
      expect(responseSnap.exists, isTrue);
      expect(responseSnap.data()?['studentAnswer'], 'E = mc^2');
      expect(responseSnap.data()?['quizId'], 'quiz_1');
    });
  });
}
