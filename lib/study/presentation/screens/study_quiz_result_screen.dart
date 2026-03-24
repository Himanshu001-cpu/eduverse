import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/core/firebase/quiz_stats_service.dart';

/// Quiz result screen for Study section.
class StudyQuizResultScreen extends StatefulWidget {
  final String quizTitle;
  final List<QuizQuestion> questions;
  final List<int?> userAnswers;
  final int correctCount;
  final Color themeColor;
  final String? quizId;
  final String source; // 'batch' or 'feed'
  final double? marksPerQuestion;
  final double? negativeMarking;

  const StudyQuizResultScreen({
    super.key,
    required this.quizTitle,
    required this.questions,
    required this.userAnswers,
    required this.correctCount,
    this.themeColor = Colors.purple,
    this.quizId,
    this.source = 'batch',
    this.marksPerQuestion,
    this.negativeMarking,
  });

  @override
  State<StudyQuizResultScreen> createState() => _StudyQuizResultScreenState();
}

class _StudyQuizResultScreenState extends State<StudyQuizResultScreen> {
  bool _statsSaved = false;

  double get _totalMarksObtained {
    double total = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final isAttempted = widget.userAnswers[i] != null;
      if (!isAttempted) continue;

      final isCorrect = widget.userAnswers[i] == q.correctIndex;
      final markForQ = widget.marksPerQuestion ?? q.score.toDouble();
      final negForQ = widget.negativeMarking ?? q.negativeMarks ?? 0.0;

      if (isCorrect) {
        total += markForQ;
      } else {
        total -= negForQ;
      }
    }
    return total;
  }

  double get _maxMarks {
    double total = 0;
    for (var q in widget.questions) {
      total += widget.marksPerQuestion ?? q.score.toDouble();
    }
    return total;
  }

  double get _percentage => _maxMarks > 0
      ? ((_totalMarksObtained / _maxMarks) * 100).clamp(0, 100)
      : 0;

  int get _unattemptedCount =>
      widget.userAnswers.where((a) => a == null).length;
  int get _wrongCount =>
      widget.questions.length - widget.correctCount - _unattemptedCount;

  String get _message {
    if (_percentage >= 90) return 'Excellent! Outstanding performance! 🌟';
    if (_percentage >= 70) return 'Great job! Keep up the good work! 👏';
    if (_percentage >= 50) return 'Good effort! Room for improvement. 📚';
    if (_percentage >= 30) return 'Keep practicing! You can do better. 💪';
    return 'Don\'t give up! Review the concepts. 📖';
  }

  Map<String, Map<String, dynamic>> get _subjectBreakdown {
    Map<String, Map<String, dynamic>> breakdown = {};
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final subject = q.subject ?? 'Uncategorized';
      if (!breakdown.containsKey(subject)) {
        breakdown[subject] = {
          'correct': 0,
          'wrong': 0,
          'skipped': 0,
          'total': 0,
        };
      }
      breakdown[subject]!['total'] = (breakdown[subject]!['total'] as int) + 1;

      if (widget.userAnswers[i] == null) {
        breakdown[subject]!['skipped'] =
            (breakdown[subject]!['skipped'] as int) + 1;
      } else if (widget.userAnswers[i] == q.correctIndex) {
        breakdown[subject]!['correct'] =
            (breakdown[subject]!['correct'] as int) + 1;
      } else {
        breakdown[subject]!['wrong'] =
            (breakdown[subject]!['wrong'] as int) + 1;
      }
    }
    return breakdown;
  }

  @override
  void initState() {
    super.initState();
    _saveQuizStats();
  }

  Future<void> _saveQuizStats() async {
    if (_statsSaved) return;
    _statsSaved = true;

    await QuizStatsService().saveQuizAttempt(
      quizId:
          widget.quizId ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      quizTitle: widget.quizTitle,
      questionsAttempted: widget.questions.length,
      correctAnswers: widget.correctCount,
      completed: true, // They reached the result screen, so completed
      source: widget.source,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Score card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              widget.themeColor,
                              widget.themeColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              '${_totalMarksObtained.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} / ${_maxMarks.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Statistics row
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          'Correct',
                          widget.correctCount.toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context,
                          'Wrong',
                          _wrongCount.toString(),
                          Colors.red,
                          Icons.cancel,
                        ),
                        if (_unattemptedCount > 0) ...[
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            'Skipped',
                            _unattemptedCount.toString(),
                            Colors.orange,
                            Icons.remove_circle_outline,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Subject Breakdown
                    if (_subjectBreakdown.keys.length > 1 ||
                        (_subjectBreakdown.keys.length == 1 &&
                            _subjectBreakdown.keys.first !=
                                'Uncategorized')) ...[
                      Row(
                        children: [
                          Icon(Icons.category, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Subject Breakdown',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: _subjectBreakdown.entries.map((e) {
                            final subjectName = e.key;
                            final stats = e.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      subjectName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${stats['correct']}C, ${stats['wrong']}W, ${stats['skipped']}S / ${stats['total']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Question review header
                    Row(
                      children: [
                        Icon(Icons.list_alt, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Question Review',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Question list
                    ...List.generate(
                      widget.questions.length,
                      (index) => _buildQuestionReviewCard(context, index),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Batch'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionReviewCard(BuildContext context, int index) {
    final question = widget.questions[index];
    final userAnswer = widget.userAnswers[index];
    final isUnattempted = userAnswer == null;
    final isCorrect = !isUnattempted && userAnswer == question.correctIndex;
    final colorScheme = Theme.of(context).colorScheme;

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    if (isUnattempted) {
      statusColor = Colors.orange;
      statusIcon = Icons.remove_circle_outline;
    } else if (isCorrect) {
      statusColor = Colors.green;
      statusIcon = Icons.check;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.close;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(statusIcon, color: statusColor, size: 20)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.subject != null && question.subject!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    question.subject!,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            Text(
              'Q${index + 1}. ${question.question}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        subtitle: isUnattempted
            ? Text(
                'Not attempted',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              )
            : null,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          // Your answer (if attempted)
          if (!isUnattempted) ...[
            _buildAnswerRow(
              context,
              'Your Answer',
              question.options[userAnswer].text,
              isCorrect ? Colors.green : Colors.red,
              isCorrect ? Icons.check_circle : Icons.cancel,
            ),
            const SizedBox(height: 8),
          ] else ...[
            _buildAnswerRow(
              context,
              'Your Answer',
              '(Not attempted)',
              Colors.orange,
              Icons.remove_circle_outline,
            ),
            const SizedBox(height: 8),
          ],
          // Correct answer (if wrong or unattempted)
          if (!isCorrect) ...[
            _buildAnswerRow(
              context,
              'Correct Answer',
              question.options[question.correctIndex].text,
              Colors.green,
              Icons.check_circle,
            ),
            const SizedBox(height: 12),
          ],
          // Explanation
          if (question.explanation != null && question.explanation!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.explanation!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(
    BuildContext context,
    String label,
    String answer,
    Color color,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(answer, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
