import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';

class BatchQuizScreen extends StatelessWidget {
  final String courseId;
  final String batchId;

  const BatchQuizScreen({super.key, required this.courseId, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Batch Quizzes',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Quiz Management coming soon!'),
            const SizedBox(height: 8),
            Text('Course: $courseId\nBatch: $batchId', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
