import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'rich_editor_toolbar.dart';
import 'find_replace_panel.dart';
import 'equation_builder.dart';
import 'tldraw_webview.dart';
import '../../core/services/rich_text_service.dart';

class RichDocumentEditor extends StatefulWidget {
  final String? initialDeltaJson;
  final String? initialHtml;
  final String labelText;
  final String? hintText;
  final void Function(String deltaJson, String html) onSave;
  final Duration autoSaveDebounceDuration;

  const RichDocumentEditor({
    super.key,
    this.initialDeltaJson,
    this.initialHtml,
    required this.labelText,
    this.hintText,
    required this.onSave,
    this.autoSaveDebounceDuration = const Duration(minutes: 1),
  });

  @override
  State<RichDocumentEditor> createState() => _RichDocumentEditorState();
}

class _RichDocumentEditorState extends State<RichDocumentEditor> {
  late final TextEditingController _textController;
  
  bool _showFindReplace = false;
  bool _showEquationBuilder = false;
  bool _showWhiteboard = false;
  bool _showTableDialog = false;

  final TextEditingController _tableRowsController = TextEditingController();
  final TextEditingController _tableColsController = TextEditingController();
  String? _tableError;

  Timer? _autoSaveTimer;
  int _autoSaveCount = 0;
  TextAlign _currentAlignment = TextAlign.left;
  double _currentFontSize = 16.0;
  String? _currentHighlight;

  @override
  void initState() {
    super.initState();
    String initialText = '';
    if (widget.initialDeltaJson != null) {
      try {
        final decoded = json.decode(widget.initialDeltaJson!);
        if (decoded is Map && decoded.containsKey('ops')) {
          final ops = decoded['ops'] as List;
          initialText = ops.map((op) => op['insert']?.toString() ?? '').join();
        }
      } catch (_) {
        // Fallback to initialHtml parsing or empty
      }
    }
    if (initialText.isEmpty && widget.initialHtml != null) {
      // Very simple extraction of text from html tags for editing
      initialText = widget.initialHtml!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
    }

    _textController = TextEditingController(text: initialText);
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _tableRowsController.dispose();
    _tableColsController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Reset auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(widget.autoSaveDebounceDuration, _triggerAutoSave);
  }

  void _triggerAutoSave() {
    _autoSaveCount++;
    final delta = _generateDeltaJson();
    final html = _generateHtml();
    widget.onSave(delta, html);
  }

  void _forceSave() {
    _autoSaveTimer?.cancel();
    final delta = _generateDeltaJson();
    final html = _generateHtml();
    widget.onSave(delta, html);
  }

  String _generateDeltaJson() {
    return json.encode({
      'ops': [
        {
          'insert': _textController.text,
          'attributes': {
            'align': _currentAlignment.name,
            'size': _currentFontSize,
            if (_currentHighlight != null) 'highlight': _currentHighlight,
          }
        }
      ]
    });
  }

  String _generateHtml() {
    final text = _textController.text;
    var html = RichTextService.convertMarkdownToHtml(text);

    // Parse custom equation blocks
    final eqRegex = RegExp(r'\[latex\](.*?)\[/latex\]');
    html = html.replaceAllMapped(eqRegex, (match) {
      return RichTextService.parseLatexToHtml(match.group(1) ?? '');
    });

    // Parse custom whiteboard diagram blocks
    final diagRegex = RegExp(r'\[diagram\](.*?)\[/diagram\]');
    html = html.replaceAllMapped(diagRegex, (match) {
      return '<div class="rich-diagram">${match.group(1)}</div>';
    });

    // Parse custom table blocks
    final tableRegex = RegExp(r'\[table rows=(\d+) cols=(\d+)\](.*?)\[/table\]');
    html = html.replaceAllMapped(tableRegex, (match) {
      final rows = int.tryParse(match.group(1) ?? '1') ?? 1;
      final cols = int.tryParse(match.group(2) ?? '1') ?? 1;
      final content = match.group(3) ?? '';
      
      final cells = content.split('|');
      var cellIndex = 0;
      
      final sb = StringBuffer();
      sb.writeln('<table class="rich-table" border="1" style="border-collapse: collapse; width: 100%;">');
      for (int r = 0; r < rows; r++) {
        sb.writeln('  <tr>');
        for (int c = 0; c < cols; c++) {
          final cellText = cellIndex < cells.length ? cells[cellIndex].trim() : '';
          sb.writeln('    <td style="padding: 8px;">${RichTextService.convertMarkdownToHtml(cellText)}</td>');
          cellIndex++;
        }
        sb.writeln('  </tr>');
      }
      sb.writeln('</table>');
      return sb.toString();
    });

    // Wrap with formatting styles
    var styles = 'font-size: ${_currentFontSize}px; text-align: ${_currentAlignment.name};';
    if (_currentHighlight != null) {
      styles += ' background-color: ${_currentHighlight};';
    }

    return '<div style="$styles">$html</div>';
  }

  void _applyFormatting(String startTag, String endTag) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    if (start == end && text.isNotEmpty) {
      start = 0;
      end = text.length;
    }

    final selectedText = text.substring(start, end);
    final formattedText = '$startTag$selectedText$endTag';
    
    final newText = text.substring(0, start) + formattedText + text.substring(end);
    _textController.text = newText;
    
    // Set selection back
    _textController.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + formattedText.length,
    );
  }

  void _insertTable() {
    final rows = int.tryParse(_tableRowsController.text) ?? 0;
    final cols = int.tryParse(_tableColsController.text) ?? 0;

    if (rows <= 0 || cols <= 0) {
      setState(() {
        _tableError = 'Dimensions must be greater than 0';
      });
      return;
    }

    if (rows > 20 || cols > 20) {
      setState(() {
        _tableError = 'Table dimensions cannot exceed 20x20';
      });
      return;
    }

    setState(() {
      _tableError = null;
      _showTableDialog = false;
    });

    // Create empty cells content string
    final cellCount = rows * cols;
    final cells = List.generate(cellCount, (i) => 'Cell ${i + 1}').join(' | ');
    final tableTag = '\n[table rows=$rows cols=$cols]$cells[/table]\n';
    
    final text = _textController.text;
    final selection = _textController.selection;
    int index = selection.isValid ? selection.start : text.length;
    
    final newText = text.substring(0, index) + tableTag + text.substring(index);
    _textController.text = newText;
    _tableRowsController.clear();
    _tableColsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichEditorToolbar(
          onBoldPressed: () => _applyFormatting('**', '**'),
          onItalicPressed: () => _applyFormatting('*', '*'),
          onUnderlinePressed: () => _applyFormatting('<u>', '</u>'),
          onAlignmentChanged: (align) {
            setState(() {
              _currentAlignment = align;
            });
            _onTextChanged();
          },
          onListStyleChanged: (style) {
            if (style == 'bullet') {
              _applyFormatting('\n- ', '\n');
            } else {
              _applyFormatting('\n1. ', '\n');
            }
          },
          onFontSizeChanged: (size) {
            if (size != null) {
              setState(() {
                _currentFontSize = size;
              });
              _onTextChanged();
            }
          },
          onHighlightChanged: (color) {
            setState(() {
              _currentHighlight = color;
            });
            _onTextChanged();
          },
          onInsertTablePressed: () {
            setState(() {
              _showTableDialog = !_showTableDialog;
              _tableError = null;
            });
          },
          onInsertEquationPressed: () {
            setState(() {
              _showEquationBuilder = !_showEquationBuilder;
            });
          },
          onInsertDiagramPressed: () {
            setState(() {
              _showWhiteboard = !_showWhiteboard;
            });
          },
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                widget.labelText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('btn_toggle_find_replace'),
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _showFindReplace = !_showFindReplace;
                    });
                  },
                ),
                TextButton.icon(
                  key: const Key('btn_manual_save'),
                  onPressed: _forceSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            )
          ],
        ),

        if (_showFindReplace)
          FindReplacePanel(
            key: const Key('editor_find_replace_panel'),
            textController: _textController,
          ),

        if (_showTableDialog)
          Card(
            key: const Key('table_dialog_card'),
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Insert Table', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('table_rows_input'),
                          controller: _tableRowsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rows'),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: TextField(
                          key: const Key('table_cols_input'),
                          controller: _tableColsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Columns'),
                        ),
                      ),
                    ],
                  ),
                  if (_tableError != null) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      _tableError!,
                      key: const Key('table_error_text'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: const Key('btn_cancel_table'),
                        onPressed: () {
                          setState(() {
                            _showTableDialog = false;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        key: const Key('btn_submit_table'),
                        onPressed: _insertTable,
                        child: const Text('Insert'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        if (_showEquationBuilder)
          EquationBuilder(
            key: const Key('editor_equation_builder'),
            onEquationSaved: (eq) {
              setState(() {
                _showEquationBuilder = false;
              });
              final latexBlock = '[latex]$eq[/latex]';
              final text = _textController.text;
              final selection = _textController.selection;
              int index = selection.isValid ? selection.start : text.length;
              _textController.text = text.substring(0, index) + latexBlock + text.substring(index);
            },
          ),

        if (_showWhiteboard)
          SizedBox(
            height: 250,
            child: TldrawWebview(
              key: const Key('editor_whiteboard'),
              onDiagramExported: (svg) {
                setState(() {
                  _showWhiteboard = false;
                });
                final diagramBlock = '[diagram]$svg[/diagram]';
                final text = _textController.text;
                final selection = _textController.selection;
                int index = selection.isValid ? selection.start : text.length;
                _textController.text = text.substring(0, index) + diagramBlock + text.substring(index);
              },
            ),
          ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: TextField(
              key: const Key('editor_text_field'),
              controller: _textController,
              maxLines: null,
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText ?? 'Start typing here...',
              ),
            ),
          ),
        ),
        
        // Debug output widget for testing auto-save triggering
        Container(
          height: 1,
          width: 1,
          key: Key('autosave_count_$_autoSaveCount'),
        ),
      ],
    );
  }
}
