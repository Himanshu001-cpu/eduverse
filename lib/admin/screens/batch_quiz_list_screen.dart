import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';
import 'batch_quiz_screen.dart';

class BatchQuizListScreen extends StatelessWidget {
  final String courseId;
  final String batchId;

  const BatchQuizListScreen({
    super.key, 
    required this.courseId, 
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<FirebaseAdminService>(context, listen: false);

    return AdminScaffold(
      title: 'Batch Quizzes & Test Series',
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BatchQuizScreen(
                  courseId: courseId,
                  batchId: batchId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: const Text('+ Add Quiz in Studio'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduverseTheme.primary,
            foregroundColor: EduverseTheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
      body: StreamBuilder<List<AdminQuiz>>(
        stream: adminService.getCourseQuizzes(courseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text('Error loading quizzes: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = snapshot.data ?? [];

          if (quizzes.isEmpty) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EduverseTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.quiz_outlined, size: 40, color: EduverseTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Quizzes in this Cohort',
                      style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Design proctored sectionals, mock assessments, and automated answer keys using the Academic Futurist Quiz Studio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: EduverseTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BatchQuizScreen(
                              courseId: courseId,
                              batchId: batchId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Open Quiz Studio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EduverseTheme.primary,
                        foregroundColor: EduverseTheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Container(
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EduverseTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.quiz, color: EduverseTheme.primary),
                  ),
                  title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: EduverseTheme.deepNavy)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${quiz.questions.length} Questions • ${quiz.timeLimitMinutes ?? 60}m Duration • +${quiz.marksPerQuestion ?? 2.0}/-${quiz.negativeMarking ?? 0.66} Marking • ${quiz.description}',
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: EduverseTheme.primary),
                        tooltip: 'Open in Quiz Studio',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BatchQuizScreen(
                                courseId: courseId,
                                batchId: batchId,
                                existingQuiz: quiz,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Quiz',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Quiz?'),
                              content: Text('Are you sure you want to delete "${quiz.title}"? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await adminService.deleteCourseQuiz(courseId, quiz.id);
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
