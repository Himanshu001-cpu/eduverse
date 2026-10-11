import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';
import 'question_status.dart';

class QuestionPaletteRail extends StatelessWidget {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final ValueChanged<int> onSelectQuestion;
  final void Function(int oldIndex, int newIndex) onReorderQuestions;
  final VoidCallback onAddQuestion;
  final VoidCallback onAddMultiple;
  final VoidCallback onImportFromLibrary;

  const QuestionPaletteRail({
    super.key,
    required this.questions,
    required this.currentIndex,
    required this.onSelectQuestion,
    required this.onReorderQuestions,
    required this.onAddQuestion,
    required this.onAddMultiple,
    required this.onImportFromLibrary,
  });

  @override
  Widget build(BuildContext context) {
    int validatedCount = 0;
    int flaggedCount = 0;
    int incompleteCount = 0;

    int easyCount = 0;
    int mediumCount = 0;
    int hardCount = 0;
    int untaggedCount = 0;

    for (final q in questions) {
      final isComplete = isQuestionComplete(q);
      if (q.flaggedForReview) {
        flaggedCount++;
      } else if (isComplete) {
        validatedCount++;
      } else {
        incompleteCount++;
      }

      switch (q.difficulty) {
        case QuestionDifficulty.easy:
          easyCount++;
          break;
        case QuestionDifficulty.medium:
          mediumCount++;
          break;
        case QuestionDifficulty.hard:
          hardCount++;
          break;
        case null:
          untaggedCount++;
          break;
      }
    }

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: EduverseColors.surfaceBright,
        border: Border(
          left: BorderSide(
            color: EduverseColors.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail title & stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Question Matrix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EduverseColors.deepNavy,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: EduverseColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${questions.length} Qs',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: EduverseColors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Legend Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildLegendPill(
                      icon: Icons.check_circle_rounded,
                      color: EduverseColors.emeraldVivid,
                      label: '$validatedCount Validated',
                    ),
                    _buildLegendPill(
                      icon: Icons.flag_rounded,
                      color: const Color(0xFFD97706),
                      label: '$flaggedCount Flagged',
                    ),
                    _buildLegendPill(
                      icon: Icons.error_outline_rounded,
                      color: EduverseColors.error,
                      label: '$incompleteCount Incomplete',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Grid of Numbered Question Chips
          Expanded(
            child: questions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No questions in this test.\nTap below to add questions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: EduverseColors.outline),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < questions.length; i++)
                              _buildPaletteChip(context, i),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Difficulty summary card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: EduverseColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: EduverseColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DIFFICULTY DISTRIBUTION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: EduverseColors.outline,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _diffTag('Easy', easyCount, const Color(0xFF10B981)),
                                  _diffTag('Medium', mediumCount, const Color(0xFFF59E0B)),
                                  _diffTag('Hard', hardCount, const Color(0xFFEF4444)),
                                  _diffTag('None', untaggedCount, EduverseColors.outline),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onImportFromLibrary,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Import Pool'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddMultiple,
                        icon: const Icon(Icons.playlist_add, size: 16),
                        label: const Text('Add Multi'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onAddQuestion,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Question'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffTag(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: EduverseColors.outline),
        ),
      ],
    );
  }

  Widget _buildPaletteChip(BuildContext context, int index) {
    final q = questions[index];
    final isSelected = index == currentIndex;
    final isComplete = isQuestionComplete(q);
    final isFlagged = q.flaggedForReview;

    final statusColor = QuestionStatusHelper.getStatusColor(
      isComplete: isComplete,
      isFlagged: isFlagged,
    );

    final chipNumber = (index + 1).toString();

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onReorderQuestions(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;

        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EduverseColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chipNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _chipBox(
              chipNumber: chipNumber,
              isSelected: isSelected,
              statusColor: statusColor,
              isFlagged: isFlagged,
              isDropTarget: isDropTarget,
            ),
          ),
          child: InkWell(
            onTap: () => onSelectQuestion(index),
            borderRadius: BorderRadius.circular(8),
            child: _chipBox(
              chipNumber: chipNumber,
              isSelected: isSelected,
              statusColor: statusColor,
              isFlagged: isFlagged,
              isDropTarget: isDropTarget,
            ),
          ),
        );
      },
    );
  }

  Widget _chipBox({
    required String chipNumber,
    required bool isSelected,
    required Color statusColor,
    required bool isFlagged,
    required bool isDropTarget,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? statusColor.withValues(alpha: 0.2)
            : (isDropTarget
                ? EduverseColors.primary.withValues(alpha: 0.15)
                : EduverseColors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? EduverseColors.primary
              : (isDropTarget
                  ? EduverseColors.primary
                  : statusColor.withValues(alpha: 0.6)),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            chipNumber,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? EduverseColors.deepNavy : EduverseColors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (isFlagged)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD97706),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
