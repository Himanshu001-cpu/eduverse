import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import '../widgets/favourite_batches_section.dart';
import '../widgets/continue_learning_section.dart';
import '../widgets/browse_by_exam_section.dart';
import '../widgets/explore_batch_button.dart';
import '../widgets/live_classes_section.dart';
import '../widgets/timetable_timeline_widget.dart';
import '../widgets/combo_batches_section.dart';

class StudyHomeScreen extends StatelessWidget {
  const StudyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);

    if (controller.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Error: ${controller.error}', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    if (controller.enrolledBatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_rounded, size: 64, color: Colors.blue[700]),
              ),
              const SizedBox(height: 24),
              const Text(
                'No enrolled batches yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Visit the Store to enroll in your first batch!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Dynamic Homepage layout: Combo Pack vs Individual Batch
    StudyBatch? selectedBatch;
    try {
      selectedBatch = controller.enrolledBatches.firstWhere((b) => b.id == controller.selectedBatchId);
    } catch (_) {}

    if (selectedBatch == null || selectedBatch.isCombo) {
      return Column(
        key: const Key('combo_pack_layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LiveClassesSection(),
          const FavouriteBatchesSection(),
          const SizedBox(height: 16),
          const ContinueLearningSection(),
          const SizedBox(height: 16),
          const BrowseByExamSection(),
          const SizedBox(height: 16),
          const ComboBatchesSection(),
          const SizedBox(height: 16),
          const TimetableTimelineWidget(),
        ],
      );
    } else {
      return Column(
        key: const Key('individual_batch_layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LiveClassesSection(),
          const ContinueLearningSection(),
          const SizedBox(height: 16),
          const ExploreBatchButton(),
          const SizedBox(height: 16),
          TimetableTimelineWidget(courseId: selectedBatch.courseId),
        ],
      );
    }
  }
}
