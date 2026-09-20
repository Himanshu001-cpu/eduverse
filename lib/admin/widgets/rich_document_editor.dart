import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rich_editor_toolbar.dart';
import 'find_replace_panel.dart';
import 'equation_builder.dart';
import 'tldraw_webview.dart';
import 'editable_table_widget.dart';
import '../../core/services/rich_text_service.dart';

class RichDocumentEditor extends StatefulWidget {
  final String? initialDeltaJson;
  final String? initialHtml;
  final String? initialText;
  final String labelText;
  final String? hintText;
  final void Function(String deltaJson, String html) onSave;
  final void Function(Map<String, dynamic> payload)? onSaveDualFormat;
  final Duration autoSaveDebounceDuration;

  const RichDocumentEditor({
    super.key,
    this.initialDeltaJson,
    this.initialHtml,
    this.initialText,
    required this.labelText,
    this.hintText,
    required this.onSave,
    this.onSaveDualFormat,
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
  bool _tableHasHeader = false;
  String? _tableError;

  Timer? _autoSaveTimer;
  int _autoSaveCount = 0;
  TextAlign _currentAlignment = TextAlign.left;
  double _currentFontSize = 16.0;

  @override
  void initState() {
    super.initState();
    String initialText = '';
    if (widget.initialDeltaJson != null && widget.initialDeltaJson!.trim().isNotEmpty) {
      try {
        final decoded = json.decode(widget.initialDeltaJson!);
        if (decoded is Map && decoded.containsKey('ops')) {
          final ops = decoded['ops'] as List;
          initialText = ops.map((op) => op['insert']?.toString() ?? '').join();
        }
      } catch (_) {
        // Fallback to initialHtml parsing or initialText
      }
    }
    if (initialText.trim().isEmpty && widget.initialHtml != null && widget.initialHtml!.trim().isNotEmpty) {
      // Very simple extraction of text from html tags for editing
      initialText = widget.initialHtml!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
    }
    if (initialText.trim().isEmpty && widget.initialText != null && widget.initialText!.isNotEmpty) {
      initialText = widget.initialText!;
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
    final payload = RichTextService.serializeForFirestore(
      deltaJson: delta,
      html: html,
      plainText: _textController.text,
    );
    widget.onSaveDualFormat?.call(payload);
  }

  void _forceSave() {
    _autoSaveTimer?.cancel();
    final delta = _generateDeltaJson();
    final html = _generateHtml();
    widget.onSave(delta, html);
    final payload = RichTextService.serializeForFirestore(
      deltaJson: delta,
      html: html,
      plainText: _textController.text,
    );
    widget.onSaveDualFormat?.call(payload);
  }

  String _generateDeltaJson() {
    return json.encode({
      'ops': [
        {
          'insert': _textController.text,
          'attributes': {
            'align': _currentAlignment.name,
            'size': _currentFontSize,
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

    // Parse block display math $$...$$
    final blockMathRegex = RegExp(r'\$\$(.*?)\$\$', dotAll: true);
    html = html.replaceAllMapped(blockMathRegex, (match) {
      final math = match.group(1)?.trim() ?? '';
      return '<div class="math-latex math-block" data-latex="${Uri.encodeComponent(math)}">$math</div>';
    });

    // Parse inline math $...$
    final inlineMathRegex = RegExp(r'(?<!\$)\$(?!\$)([^\$\n]+?)(?<!\$)\$(?!\$)');
    html = html.replaceAllMapped(inlineMathRegex, (match) {
      final math = match.group(1)?.trim() ?? '';
      return '<span class="math-latex math-inline" data-latex="${Uri.encodeComponent(math)}">$math</span>';
    });

    // Parse custom whiteboard diagram blocks
    final diagRegex = RegExp(r'\[diagram\](.*?)\[/diagram\]');
    html = html.replaceAllMapped(diagRegex, (match) {
      return '<div class="rich-diagram">${match.group(1)}</div>';
    });

    // Parse custom table blocks
    final tableRegex = RegExp(r'\[table rows=(\d+) cols=(\d+)(?:\s+header=(true|false))?\](.*?)\[/table\]', dotAll: true);
    html = html.replaceAllMapped(tableRegex, (match) {
      final rows = int.tryParse(match.group(1) ?? '1') ?? 1;
      final cols = int.tryParse(match.group(2) ?? '1') ?? 1;
      final hasHeader = match.group(3) == 'true';
      final content = match.group(4) ?? '';
      
      final cells = content.split('|');
      var cellIndex = 0;
      
      final sb = StringBuffer();
      sb.writeln('<table class="rich-table" border="1" style="border-collapse: collapse; width: 100%;">');
      for (int r = 0; r < rows; r++) {
        sb.writeln('  <tr>');
        final isHeaderRow = hasHeader && r == 0;
        for (int c = 0; c < cols; c++) {
          final cellText = cellIndex < cells.length ? cells[cellIndex].trim() : '';
          final formatted = RichTextService.convertMarkdownToHtml(cellText);
          if (isHeaderRow) {
            sb.writeln('    <th style="padding: 8px; font-weight: bold; background-color: rgba(0,0,0,0.06); text-align: left;">$formatted</th>');
          } else {
            sb.writeln('    <td style="padding: 8px;">$formatted</td>');
          }
          cellIndex++;
        }
        sb.writeln('  </tr>');
      }
      sb.writeln('</table>');
      return sb.toString();
    });

    // Wrap with formatting styles
    var styles = 'font-size: ${_currentFontSize}px; text-align: ${_currentAlignment.name};';

    return '<div style="$styles">$html</div>';
  }

  void _applyFormatting(String startTag, String endTag, {bool requireSelection = false}) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    if (requireSelection && (!selection.isValid || selection.isCollapsed)) {
      return;
    }

    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    if (start == end && text.isNotEmpty) {
      if (requireSelection) return;
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
    final cells = List.generate(cellCount, (i) {
      if (_tableHasHeader && i < cols) {
        return 'Header ${i + 1}';
      }
      return 'Cell ${i + 1}';
    }).join(' | ');
    final headerAttr = _tableHasHeader ? ' header=true' : '';
    final tableTag = '\n[table rows=$rows cols=$cols$headerAttr]$cells[/table]\n';
    
    final text = _textController.text;
    final selection = _textController.selection;
    int index = selection.isValid ? selection.start : text.length;
    
    final newText = text.substring(0, index) + tableTag + text.substring(index);
    setState(() {
      _textController.text = newText;
    });
    _tableRowsController.clear();
    _tableColsController.clear();
    _onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
            if (color != null) {
              _applyFormatting('<mark style="background-color: $color">', '</mark>');
            }
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
                  const SizedBox(height: 8.0),
                  CheckboxListTile(
                    key: const Key('table_header_toggle'),
                    title: const Text('Format first row as table header'),
                    value: _tableHasHeader,
                    onChanged: (val) {
                      setState(() {
                        _tableHasHeader = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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

        CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => _applyFormatting('**', '**'),
            const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () => _applyFormatting('**', '**'),
            const SingleActivator(LogicalKeyboardKey.keyI, control: true): () => _applyFormatting('*', '*'),
            const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () => _applyFormatting('*', '*'),
            const SingleActivator(LogicalKeyboardKey.keyU, control: true): () => _applyFormatting('<u>', '</u>'),
            const SingleActivator(LogicalKeyboardKey.keyU, meta: true): () => _applyFormatting('<u>', '</u>'),
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
              setState(() {
                _showFindReplace = !_showFindReplace;
              });
            },
            const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
              setState(() {
                _showFindReplace = !_showFindReplace;
              });
            },
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): _forceSave,
            const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _forceSave,
          },
          child: Container(
            height: 120,
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
        
        // Render any visual tables detected in the text
        ..._buildVisualTableEditors(),

        // Render any visual diagrams detected in the text (D-06)
        ..._buildVisualDiagramEditors(),
        
        // Debug output widget for testing auto-save triggering
        SizedBox(
          height: 1,
          width: 1,
          key: Key('autosave_count_$_autoSaveCount'),
        ),
      ],
    ),
  );
}

  List<_ParsedTable> _parseTablesFromText(String text) {
    final List<_ParsedTable> list = [];
    final regex = RegExp(r'\[table rows=(\d+) cols=(\d+)(?:\s+header=(true|false))?\](.*?)\[/table\]', dotAll: true);
    final matches = regex.allMatches(text).toList();
    
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final rows = int.tryParse(match.group(1) ?? '1') ?? 1;
      final cols = int.tryParse(match.group(2) ?? '1') ?? 1;
      final hasHeader = match.group(3) == 'true';
      final content = match.group(4) ?? '';
      
      final cellStrings = content.split('|');
      final cells = List.generate(
        rows,
        (r) => List.generate(
          cols,
          (c) {
            final cellIndex = (r * cols) + c;
            return cellIndex < cellStrings.length ? cellStrings[cellIndex].trim() : '';
          },
        ),
      );
      
      list.add(_ParsedTable(
        index: i,
        rows: rows,
        cols: cols,
        cells: cells,
        rawText: match.group(0)!,
        hasHeader: hasHeader,
      ));
    }
    return list;
  }

  void _updateTableInText(int tableIndex, List<List<String>> newCells, int newRows, int newCols) {
    final text = _textController.text;
    final parsed = _parseTablesFromText(text);
    if (tableIndex >= parsed.length) return;
    
    final target = parsed[tableIndex];
    final cellCount = newRows * newCols;
    final cellStrings = List.generate(cellCount, (i) {
      final r = i ~/ newCols;
      final c = i % newCols;
      return (r < newCells.length && c < newCells[r].length) ? newCells[r][c] : '';
    });
    
    final headerAttr = target.hasHeader ? ' header=true' : '';
    final newTableMarkdown = '[table rows=$newRows cols=$newCols$headerAttr]${cellStrings.join(' | ')}[/table]';
    final newText = text.replaceFirst(target.rawText, newTableMarkdown);
    
    final selection = _textController.selection;
    _textController.text = newText;
    if (selection.isValid && selection.end <= newText.length) {
      _textController.selection = selection;
    }
    _onTextChanged();
  }

  List<Widget> _buildVisualTableEditors() {
    final parsed = _parseTablesFromText(_textController.text);
    return List.generate(parsed.length, (index) {
      final pt = parsed[index];
      return EditableTableWidget(
        key: Key('editable_table_$index'),
        initialRows: pt.rows,
        initialCols: pt.cols,
        initialData: pt.cells,
        onTableChanged: (cells, rows, cols) {
          _updateTableInText(index, cells, rows, cols);
        },
      );
    });
  }

  List<_ParsedDiagram> _parseDiagramsFromText(String text) {
    final List<_ParsedDiagram> list = [];
    final regex = RegExp(r'\[diagram\](.*?)\[/diagram\]', dotAll: true);
    final matches = regex.allMatches(text).toList();
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      list.add(_ParsedDiagram(
        index: i,
        content: match.group(1) ?? '',
        rawText: match.group(0)!,
      ));
    }
    return list;
  }

  void _deleteDiagram(int index) {
    final text = _textController.text;
    final parsed = _parseDiagramsFromText(text);
    if (index >= parsed.length) return;
    final target = parsed[index];
    final newText = text.replaceFirst(target.rawText, '').trim();
    setState(() {
      _textController.text = newText;
    });
    _onTextChanged();
  }

  void _showFullscreenDiagram(String content) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Diagram Fullscreen Preview'),
            actions: [
              IconButton(
                key: const Key('btn_close_diagram_fullscreen'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                alignment: Alignment.center,
                child: content.contains('<svg')
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          content,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      )
                    : Text(content),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _replaceDiagram(int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            children: [
              AppBar(
                title: const Text('Replace Diagram'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Expanded(
                child: TldrawWebview(
                  key: Key('replace_whiteboard_$index'),
                  onDiagramExported: (newSvg) {
                    Navigator.of(ctx).pop();
                    final text = _textController.text;
                    final parsed = _parseDiagramsFromText(text);
                    if (index < parsed.length) {
                      final target = parsed[index];
                      final newBlock = '[diagram]$newSvg[/diagram]';
                      setState(() {
                        _textController.text = text.replaceFirst(target.rawText, newBlock);
                      });
                      _onTextChanged();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVisualDiagramEditors() {
    final parsed = _parseDiagramsFromText(_textController.text);
    if (parsed.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Text(
          'Diagrams (${parsed.length}):',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      ...List.generate(parsed.length, (index) {
        final diagram = parsed[index];
        final snippet = diagram.content.length > 60
            ? '${diagram.content.substring(0, 60)}...'
            : diagram.content;

        return Card(
          key: Key('diagram_card_$index'),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: const Icon(Icons.draw, color: Colors.blue),
            title: Text('Diagram #${index + 1}'),
            subtitle: Text(
              snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('btn_preview_diagram_$index'),
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Fullscreen Preview',
                  onPressed: () => _showFullscreenDiagram(diagram.content),
                ),
                IconButton(
                  key: Key('btn_replace_diagram_$index'),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Replace Diagram',
                  onPressed: () => _replaceDiagram(index),
                ),
                IconButton(
                  key: Key('btn_delete_diagram_$index'),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Diagram',
                  onPressed: () => _deleteDiagram(index),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}

class _ParsedDiagram {
  final int index;
  final String content;
  final String rawText;

  _ParsedDiagram({
    required this.index,
    required this.content,
    required this.rawText,
  });
}

class _ParsedTable {
  final int index;
  final int rows;
  final int cols;
  final List<List<String>> cells;
  final String rawText;
  final bool hasHeader;

  _ParsedTable({
    required this.index,
    required this.rows,
    required this.cols,
    required this.cells,
    required this.rawText,
    this.hasHeader = false,
  });
}

