import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/data_table_card.dart';
import 'batch_quiz_editor_screen.dart';

class BatchQuizListScreen extends StatelessWidget {
  final String courseId;
  final String batchId;

  const BatchQuizListScreen({
    Key? key, 
    required this.courseId, 
    required this.batchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<FirebaseAdminService>(context, listen: false);

    return AdminScaffold(
      title: 'Manage Batch Quizzes',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BatchQuizEditorScreen(
                  courseId: courseId,
                  batchId: batchId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Quiz'),
        ),
      ],
      body: StreamBuilder<List<AdminQuiz>>(
        stream: adminService.getBatchQuizzes(courseId, batchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = snapshot.data ?? [];

          if (quizzes.isEmpty) {
            return const Center(
              child: Text(
                'No quizzes found for this batch.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: const Icon(Icons.quiz, color: Colors.purple),
                  ),
                  title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${quiz.questions.length} Questions • ${quiz.description}',
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton(
                         icon: const Icon(Icons.edit, color: Colors.blue),
                         onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BatchQuizEditorScreen(
                                  courseId: courseId,
                                  batchId: batchId,
                                  quiz: quiz,
                                ),
                              ),
                            );
                         },
                       ),
                       IconButton(
                         icon: const Icon(Icons.delete, color: Colors.red),
                         onPressed: () async {
                           final confirm = await showDialog<bool>(
                             context: context,
                             builder: (context) => AlertDialog(
                               title: const Text('Delete Quiz?'),
                               content: const Text('This action cannot be undone.'),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                 TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                               ],
                             ),
                           );
                           if (confirm == true) {
                             await adminService.deleteBatchQuiz(courseId, batchId, quiz.id);
                           }
                         },
                       ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
