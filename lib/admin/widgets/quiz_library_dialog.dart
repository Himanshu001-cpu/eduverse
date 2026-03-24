import 'package:flutter/material.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/services/firebase_admin_service.dart';

/// Reusable dialog that shows all quizzes from the global [quizzes_pool]
/// collection. The caller receives the selected [AdminQuiz] as the dialog
/// result and can clone it into their local state as needed.
///
/// Usage:
/// ```dart
/// final selected = await showDialog<AdminQuiz>(
///   context: context,
///   builder: (_) => const QuizLibraryDialog(),
/// );
/// if (selected != null) { /* populate editor */ }
/// ```
class QuizLibraryDialog extends StatefulWidget {
  /// Pass the [FirebaseAdminService] from the parent context.
  /// This is necessary because [showDialog] creates a new route whose
  /// [BuildContext] does not have access to the parent's [Provider] tree.
  final FirebaseAdminService adminService;

  const QuizLibraryDialog({super.key, required this.adminService});

  @override
  State<QuizLibraryDialog> createState() => _QuizLibraryDialogState();
}

class _QuizLibraryDialogState extends State<QuizLibraryDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = widget.adminService;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 560,
          maxHeight: 620,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.library_books_rounded,
                      color: colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Import from Quiz Library',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // ── Search Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search quizzes…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),

            // ── Quiz List ───────────────────────────────────────────────────
            Flexible(
              child: StreamBuilder<List<AdminQuiz>>(
                stream: adminService.getQuizPool(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error loading library: ${snapshot.error}',
                          style: TextStyle(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final filtered = _query.isEmpty
                      ? all
                      : all
                          .where((q) =>
                              q.title.toLowerCase().contains(_query))
                          .toList();

                  if (all.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.quiz_outlined,
                                size: 48,
                                color: colorScheme.onSurface.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'No quizzes in the library yet.\nSave a quiz with "Save to Global Library" first.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No quizzes match "$_query".',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final quiz = filtered[index];
                      final qCount = quiz.questions.length;
                      final mins = quiz.timeLimitMinutes ??
                          (quiz.timeLimitSeconds != null
                              ? (quiz.timeLimitSeconds! / 60).ceil()
                              : null);

                      return Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                          title: Text(
                            quiz.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              '$qCount question${qCount == 1 ? '' : 's'}',
                              if (mins != null && mins > 0) '${mins}m',
                              if (quiz.marksPerQuestion != null)
                                '${quiz.marksPerQuestion} marks/q',
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Delete from library
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: colorScheme.error,
                                ),
                                tooltip: 'Remove from library',
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Remove from Library?'),
                                      content: Text(
                                        'Delete "${quiz.title}" from the global library?\n\nExisting batch/test-series copies are not affected.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: colorScheme.error,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await adminService
                                        .deleteFromQuizPool(quiz.id);
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              // Import into current editor
                              FilledButton.tonal(
                                onPressed: () =>
                                    Navigator.pop(context, quiz),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Import'),
                              ),
                            ],
                          ),
                        ),

                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
