import 'package:flutter/material.dart';
import 'package:eduverse/admin/models/test_quiz_models.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

class SectionTabs extends StatelessWidget {
  final List<TestSection> sections;
  final String? activeSectionId; // null = 'All'
  final Map<String?, int> questionCounts; // sectionId -> count, null -> all count
  final ValueChanged<String?> onSelectSection;
  final VoidCallback onAddSection;
  final void Function(TestSection section) onRenameSection;
  final void Function(TestSection section) onDeleteSection;

  const SectionTabs({
    super.key,
    required this.sections,
    required this.activeSectionId,
    required this.questionCounts,
    required this.onSelectSection,
    required this.onAddSection,
    required this.onRenameSection,
    required this.onDeleteSection,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onAddSection,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Section'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Organize questions into sections (e.g. Section A: Macro & Budget)',
              style: TextStyle(fontSize: 12, color: EduverseColors.outline),
            ),
          ],
        ),
      );
    }

    final allCount = questionCounts[null] ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 'All' tab
          _buildTab(
            context: context,
            isSelected: activeSectionId == null,
            label: 'All Questions',
            count: allCount,
            onTap: () => onSelectSection(null),
          ),
          const SizedBox(width: 8),

          // Each section tab
          for (final sec in sections) ...[
            _buildTab(
              context: context,
              isSelected: activeSectionId == sec.id,
              label: sec.name,
              count: questionCounts[sec.id] ?? 0,
              onTap: () => onSelectSection(sec.id),
              onLongPress: () => _showSectionOptions(context, sec),
              trailing: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: activeSectionId == sec.id
                      ? Colors.white70
                      : EduverseColors.outline,
                ),
                onSelected: (val) {
                  if (val == 'rename') {
                    onRenameSection(sec);
                  } else if (val == 'delete') {
                    onDeleteSection(sec);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Rename Section'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Section', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Add Section button
          FilledButton.tonalIcon(
            onPressed: onAddSection,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Section'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: EduverseColors.surfaceContainerHigh,
              foregroundColor: EduverseColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required int count,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? EduverseColors.primary
              : EduverseColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EduverseColors.primary
                : EduverseColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : EduverseColors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? EduverseColors.primaryContainer
                    : EduverseColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : EduverseColors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  void _showSectionOptions(BuildContext context, TestSection section) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename Section'),
              onTap: () {
                Navigator.pop(ctx);
                onRenameSection(section);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Section', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Questions in this section will become unassigned.'),
              onTap: () {
                Navigator.pop(ctx);
                onDeleteSection(section);
              },
            ),
          ],
        ),
      ),
    );
  }
}
