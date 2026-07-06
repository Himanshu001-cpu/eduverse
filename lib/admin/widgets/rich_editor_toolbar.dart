import 'package:flutter/material.dart';

class RichEditorToolbar extends StatelessWidget {
  final VoidCallback? onBoldPressed;
  final VoidCallback? onItalicPressed;
  final VoidCallback? onUnderlinePressed;
  final ValueChanged<TextAlign>? onAlignmentChanged;
  final ValueChanged<String>? onListStyleChanged; // 'bullet' or 'number'
  final ValueChanged<double?>? onFontSizeChanged;
  final ValueChanged<String?>? onHighlightChanged; // e.g. '#FFFF00' for yellow
  final VoidCallback? onInsertTablePressed;
  final VoidCallback? onInsertEquationPressed;
  final VoidCallback? onInsertDiagramPressed;

  const RichEditorToolbar({
    super.key,
    this.onBoldPressed,
    this.onItalicPressed,
    this.onUnderlinePressed,
    this.onAlignmentChanged,
    this.onListStyleChanged,
    this.onFontSizeChanged,
    this.onHighlightChanged,
    this.onInsertTablePressed,
    this.onInsertEquationPressed,
    this.onInsertDiagramPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              key: const Key('btn_bold'),
              icon: const Icon(Icons.format_bold),
              tooltip: 'Bold',
              onPressed: onBoldPressed,
            ),
            IconButton(
              key: const Key('btn_italic'),
              icon: const Icon(Icons.format_italic),
              tooltip: 'Italic',
              onPressed: onItalicPressed,
            ),
            IconButton(
              key: const Key('btn_underline'),
              icon: const Icon(Icons.format_underlined),
              tooltip: 'Underline',
              onPressed: onUnderlinePressed,
            ),
            const VerticalDivider(),
            IconButton(
              key: const Key('btn_align_left'),
              icon: const Icon(Icons.format_align_left),
              tooltip: 'Align Left',
              onPressed: onAlignmentChanged != null ? () => onAlignmentChanged!(TextAlign.left) : null,
            ),
            IconButton(
              key: const Key('btn_align_center'),
              icon: const Icon(Icons.format_align_center),
              tooltip: 'Align Center',
              onPressed: onAlignmentChanged != null ? () => onAlignmentChanged!(TextAlign.center) : null,
            ),
            IconButton(
              key: const Key('btn_align_right'),
              icon: const Icon(Icons.format_align_right),
              tooltip: 'Align Right',
              onPressed: onAlignmentChanged != null ? () => onAlignmentChanged!(TextAlign.right) : null,
            ),
            const VerticalDivider(),
            IconButton(
              key: const Key('btn_list_bullet'),
              icon: const Icon(Icons.format_list_bulleted),
              tooltip: 'Bulleted List',
              onPressed: onListStyleChanged != null ? () => onListStyleChanged!('bullet') : null,
            ),
            IconButton(
              key: const Key('btn_list_number'),
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'Numbered List',
              onPressed: onListStyleChanged != null ? () => onListStyleChanged!('number') : null,
            ),
            const VerticalDivider(),
            DropdownButton<double>(
              key: const Key('dropdown_font_size'),
              value: 16.0,
              items: const [
                DropdownMenuItem(value: 12.0, child: Text('12')),
                DropdownMenuItem(value: 14.0, child: Text('14')),
                DropdownMenuItem(value: 16.0, child: Text('16')),
                DropdownMenuItem(value: 18.0, child: Text('18')),
                DropdownMenuItem(value: 24.0, child: Text('24')),
              ],
              onChanged: onFontSizeChanged,
            ),
            const SizedBox(width: 8.0),
            DropdownButton<String>(
              key: const Key('dropdown_highlight'),
              hint: const Text('Highlight'),
              items: const [
                DropdownMenuItem(value: '#FFFF00', child: Text('Yellow')),
                DropdownMenuItem(value: '#00FF00', child: Text('Green')),
                DropdownMenuItem(value: '#00FFFF', child: Text('Cyan')),
              ],
              onChanged: onHighlightChanged,
            ),
            const VerticalDivider(),
            IconButton(
              key: const Key('btn_insert_table'),
              icon: const Icon(Icons.table_chart),
              tooltip: 'Insert Table',
              onPressed: onInsertTablePressed,
            ),
            IconButton(
              key: const Key('btn_insert_equation'),
              icon: const Icon(Icons.functions),
              tooltip: 'Insert Equation',
              onPressed: onInsertEquationPressed,
            ),
            IconButton(
              key: const Key('btn_insert_diagram'),
              icon: const Icon(Icons.draw),
              tooltip: 'Insert Diagram',
              onPressed: onInsertDiagramPressed,
            ),
          ],
        ),
      ),
    );
  }
}
