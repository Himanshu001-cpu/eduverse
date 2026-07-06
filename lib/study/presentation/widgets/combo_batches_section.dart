import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/batch_detail_screen.dart';
import 'batch_thumbnail_widget.dart';

/// Displays all individual batches/courses that are part of the currently
/// selected combo pack, shown as a vertical list with progress indicators.
class ComboBatchesSection extends StatelessWidget {
  const ComboBatchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);

    // Get the currently selected combo pack
    StudyBatch? selectedCombo;
    try {
      selectedCombo = controller.enrolledBatches
          .firstWhere((b) => b.id == controller.selectedBatchId && b.isCombo);
    } catch (_) {}

    if (selectedCombo == null) return const SizedBox.shrink();

    // Find all individual batches whose courseId is in the combo's courseIds
    final combosCourseIds = selectedCombo.courseIds ?? [];
    final batchesInCombo = controller.enrolledBatches
        .where((b) =>
            !b.isCombo &&
            (combosCourseIds.contains(b.courseId) ||
                combosCourseIds.contains(b.id)))
        .toList();

    if (batchesInCombo.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Courses in this Pack',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${batchesInCombo.length} course${batchesInCombo.length == 1 ? '' : 's'} included',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ListView.builder(
          key: const Key('combo_batches_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          itemCount: batchesInCombo.length,
          itemBuilder: (context, index) {
            final batch = batchesInCombo[index];
            final progressPct =
                batch.totalLectures > 0 ? batch.progress : 0.0;

            return Container(
              key: Key('combo_batch_tile_${batch.id}'),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: controller,
                          child: BatchDetailScreen(batch: batch),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        BatchThumbnailWidget(
                          batch: batch,
                          width: 52,
                          height: 52,
                          borderRadius: 14,
                          emojiSize: 26,
                        ),
                        const SizedBox(width: 14),
                        // Text & progress
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batch.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                batch.courseName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progressPct,
                                        backgroundColor: Colors.grey.shade100,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.blue.shade600),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    batch.totalLectures > 0
                                        ? '${batch.completedLectures}/${batch.totalLectures}'
                                        : 'View',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Arrow
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
