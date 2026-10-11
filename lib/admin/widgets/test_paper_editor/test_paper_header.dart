import 'package:flutter/material.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

class TestPaperHeader extends StatelessWidget {
  final String title;
  final String category;
  final String? testCode;
  final String? autosaveText;
  final bool isAutoSaving;
  final bool hasUnsavedChanges;
  final VoidCallback onOpenSettings;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final VoidCallback onSaveAndClose;

  const TestPaperHeader({
    super.key,
    required this.title,
    required this.category,
    this.testCode,
    this.autosaveText,
    this.isAutoSaving = false,
    this.hasUnsavedChanges = false,
    required this.onOpenSettings,
    required this.onDiscard,
    required this.onSave,
    required this.onSaveAndClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceBright,
        border: Border(
          bottom: BorderSide(
            color: EduverseColors.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top metadata row: breadcrumb & autosave badge
          Row(
            children: [
              Icon(
                Icons.collections_bookmark_outlined,
                size: 16,
                color: EduverseColors.outline,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Curriculum & Assessment  ›  Test Series  ›  Test Paper Studio',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EduverseColors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAutoSaving) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                Text(
                  'Saving...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EduverseColors.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else if (autosaveText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: EduverseColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: EduverseColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 13,
                        color: EduverseColors.emeraldVivid,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        autosaveText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: EduverseColors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Chips strip: Category pill, Test ID/Code
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EduverseColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              if (testCode != null && testCode!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: EduverseColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CODE: ${testCode!.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: EduverseColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (hasUnsavedChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    'UNSAVED CHANGES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Header Row: Title and action buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final titleWidget = Text(
                title.trim().isEmpty ? 'Untitled Test Paper' : title,
                style: EduverseTypography.headlineMd(
                  color: EduverseColors.deepNavy,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );

              final actionsWidget = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Test Settings'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDiscard,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EduverseColors.error,
                      side: BorderSide(
                        color: EduverseColors.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onSaveAndClose,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save & Close'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EduverseColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 16),
                    actionsWidget,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 12),
                  actionsWidget,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
