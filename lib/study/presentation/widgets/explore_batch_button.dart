import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/batch_detail_screen.dart';

class ExploreBatchButton extends StatelessWidget {
  const ExploreBatchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);

    // Find selected batch
    final selectedBatch = controller.enrolledBatches.firstWhere(
      (b) => b.id == controller.selectedBatchId,
      orElse: () => controller.enrolledBatches.first,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ElevatedButton(
        key: const Key('explore_batch_button'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: controller,
                child: BatchDetailScreen(batch: selectedBatch),
              ),
            ),
          );
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Explore Batch Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
