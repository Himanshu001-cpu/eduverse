// file: lib/admin/widgets/formatted_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduverse/core/utils/markdown_utils.dart';

/// A reusable text field with formatting toolbar for bold and italic text.
/// Uses markdown syntax: **bold** and *italic*
class FormattedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final int maxLines;
  final String? Function(String?)? validator;

  const FormattedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.maxLines = 4,
    this.validator,
  });

  @override
  State<FormattedTextField> createState() => _FormattedTextFieldState();
}

class _FormattedTextFieldState extends State<FormattedTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _wrapSelectedText(String prefix, String suffix) {
    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isCollapsed) {
      // No text selected, insert at cursor
      final newText =
          '${text.substring(0, selection.start)}$prefix$suffix${text.substring(selection.start)}';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length,
        ),
      );
    } else {
      // Wrap selected text
      final selectedText = text.substring(selection.start, selection.end);
      final newText =
          '${text.substring(0, selection.start)}$prefix$selectedText$suffix${text.substring(selection.end)}';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.end + prefix.length + suffix.length,
        ),
      );
    }

    // Keep focus on the text field
    _focusNode.requestFocus();
  }

  void _makeBold() {
    _wrapSelectedText('**', '**');
  }

  void _makeItalic() {
    _wrapSelectedText('*', '*');
  }

  void _togglePreview() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
      if (!_isPreviewMode) {
        // Delay request focus slightly to allow the text field to rebuild
        Future.microtask(() => _focusNode.requestFocus());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formatting Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            border: Border.all(
              color: _hasFocus ? colorScheme.primary : colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              _ToolbarButton(
                icon: Icons.format_bold,
                tooltip: 'Bold (wrap with **)',
                onPressed: _isPreviewMode ? null : _makeBold,
              ),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.format_italic,
                tooltip: 'Italic (wrap with *)',
                onPressed: _isPreviewMode ? null : _makeItalic,
              ),
              const Spacer(),
              _ToolbarButton(
                icon: _isPreviewMode ? Icons.edit : Icons.preview,
                tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Markdown',
                onPressed: _togglePreview,
                color: _isPreviewMode ? colorScheme.primary : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Markdown supported',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Text Field / Preview Area
        _isPreviewMode
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  minHeight:
                      widget.maxLines *
                      24.0, // Approximate height matching text field
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: widget.controller.text.isEmpty
                    ? Text(
                        'Nothing to preview',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : MarkdownBody(
                        data: MarkdownUtils.normalizeMarkdown(
                          widget.controller.text,
                        ),
                        selectable: true,
                      ),
              )
            : TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                validator: widget.validator,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                      topLeft: Radius.zero,
                      topRight: Radius.zero,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

/// Individual toolbar button
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
          child: Icon(
            icon,
            size: 20,
            color: color ?? (onPressed == null ? Colors.grey : null),
          ),
        ),
      ),
    );
  }
}
