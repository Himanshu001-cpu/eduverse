// file: lib/feed/widgets/rich_text_block.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduverse/core/utils/markdown_utils.dart';

/// A reusable widget for displaying styled text blocks with a title and body.
/// Used across detail screens for consistent section styling.
/// Supports markdown formatting for bold (**text**) and italic (*text*).
class RichTextBlock extends StatelessWidget {
  final String title;
  final String body;
  final IconData? icon;
  final Color? iconColor;
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  const RichTextBlock({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.iconColor,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: MarkdownUtils.normalizeMarkdown(body),
            selectable: true,
            softLineBreak: true,
            styleSheet: MarkdownStyleSheet(
              p: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              strong: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                height: 1.6,
              ),
              em: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),
          if (showDivider) ...[
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

/// A variant for bulleted lists
class RichTextBulletList extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData? icon;
  final Color? iconColor;
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  const RichTextBulletList({
    super.key,
    required this.title,
    required this.items,
    this.icon,
    this.iconColor,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showDivider) ...[
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

/// Info chip widget for metadata display
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
