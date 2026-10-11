import 'package:flutter/material.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

class TestStatsStrip extends StatelessWidget {
  final int totalQuestions;
  final double totalMarks;
  final double marksPerQuestion;
  final double negativeMarks;
  final Duration timeLimit;
  final int sectionsCount;
  final DateTime? scheduledAt;
  final VoidCallback onTapCard;

  const TestStatsStrip({
    super.key,
    required this.totalQuestions,
    required this.totalMarks,
    required this.marksPerQuestion,
    required this.negativeMarks,
    required this.timeLimit,
    required this.sectionsCount,
    this.scheduledAt,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    final cards = [
      _StatCardData(
        icon: Icons.assignment_outlined,
        iconColor: EduverseColors.primary,
        title: 'Total Questions',
        value: '$totalQuestions Qs',
        subtitle: totalQuestions > 0 ? '$totalQuestions in paper' : 'Add questions',
      ),
      _StatCardData(
        icon: Icons.stars_outlined,
        iconColor: EduverseColors.tertiary,
        title: 'Total Scoring',
        value: '${totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Marks',
        subtitle: '+${marksPerQuestion.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} / -${negativeMarks.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} Neg.',
      ),
      _StatCardData(
        icon: Icons.timer_outlined,
        iconColor: EduverseColors.secondary,
        title: 'Time Allocation',
        value: timeLimit > Duration.zero
            ? (timeLimit.inHours > 0
                ? (timeLimit.inMinutes % 60 > 0
                    ? '${timeLimit.inHours}h ${timeLimit.inMinutes % 60}m'
                    : '${timeLimit.inHours}h')
                : '${timeLimit.inMinutes} Mins')
            : 'No Limit',
        subtitle: timeLimit > Duration.zero ? 'Unified Timer' : 'Untimed',
      ),
      _StatCardData(
        icon: Icons.view_column_outlined,
        iconColor: EduverseColors.emeraldVivid,
        title: 'Sections',
        value: '$sectionsCount ${sectionsCount == 1 ? "Section" : "Sections"}',
        subtitle: sectionsCount > 0 ? 'Categorized' : 'Single section',
      ),
      _StatCardData(
        icon: Icons.calendar_month_outlined,
        iconColor: const Color(0xFF6366F1),
        title: 'Schedule',
        value: scheduledAt != null
            ? '${scheduledAt!.day}/${scheduledAt!.month}/${scheduledAt!.year}'
            : 'Immediate',
        subtitle: scheduledAt != null
            ? '${scheduledAt!.hour.toString().padLeft(2, '0')}:${scheduledAt!.minute.toString().padLeft(2, '0')} IST'
            : 'Unscheduled',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: EduverseColors.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1000) {
            return Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _buildCard(context, cards[i]),
                  ),
                ],
              ],
            );
          }

          // Mobile / tablet scrollable row
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: _buildCard(context, cards[i]),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, _StatCardData data) {
    return InkWell(
      onTap: onTapCard,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EduverseColors.surfaceBright,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: EduverseColors.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: data.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(data.icon, size: 16, color: data.iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: EduverseColors.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: EduverseColors.deepNavy,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              style: TextStyle(
                fontSize: 11,
                color: EduverseColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  _StatCardData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}
