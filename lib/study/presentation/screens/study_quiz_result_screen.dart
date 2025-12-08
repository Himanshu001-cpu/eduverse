import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/study/presentation/screens/study_quiz_screen.dart';
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

  const StudyQuizResultScreen({
    Key? key,
    required this.quizTitle,
    required this.questions,
    required this.userAnswers,
    required this.correctCount,
    this.themeColor = Colors.purple,
    this.quizId,
    this.source = 'batch',
  }) : super(key: key);

  @override
  State<StudyQuizResultScreen> createState() => _StudyQuizResultScreenState();
}

class _StudyQuizResultScreenState extends State<StudyQuizResultScreen> {
  bool _statsSaved = false;

  double get _percentage => (widget.correctCount / widget.questions.length) * 100;

  String get _message {
    if (_percentage >= 90) return 'Excellent! Outstanding performance! 🌟';
    if (_percentage >= 70) return 'Great job! Keep up the good work! 👏';
    if (_percentage >= 50) return 'Good effort! Room for improvement. 📚';
    if (_percentage >= 30) return 'Keep practicing! You can do better. 💪';
    return 'Don\'t give up! Review the concepts. 📖';
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
      quizId: widget.quizId ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
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
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [widget.themeColor, widget.themeColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              '${widget.correctCount} / ${widget.questions.length}',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Statistics row
                    Row(
                      children: [
                        _buildStatCard(context, 'Correct', widget.correctCount.toString(), Colors.green, Icons.check_circle),
                        const SizedBox(width: 12),
                        _buildStatCard(context, 'Wrong', (widget.questions.length - widget.correctCount).toString(), Colors.red, Icons.cancel),
                        const SizedBox(width: 12),
                        _buildStatCard(context, 'Total', widget.questions.length.toString(), colorScheme.primary, Icons.quiz),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Question review header
                    Row(
                      children: [
                        Icon(Icons.list_alt, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Question Review', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Question list
                    ...List.generate(widget.questions.length, (index) => _buildQuestionReviewCard(context, index)),
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
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
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

  Widget _buildStatCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionReviewCard(BuildContext context, int index) {
    final question = widget.questions[index];
    final userAnswer = widget.userAnswers[index];
    final isCorrect = userAnswer == question.correctIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isCorrect ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(isCorrect ? Icons.check : Icons.close, color: isCorrect ? Colors.green : Colors.red, size: 20)),
        ),
        title: Text(
          'Q${index + 1}. ${question.question}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          if (userAnswer != null) ...[
            _buildAnswerRow(context, 'Your Answer', question.options[userAnswer].text, isCorrect ? Colors.green : Colors.red, isCorrect ? Icons.check_circle : Icons.cancel),
            const SizedBox(height: 8),
          ],
          if (!isCorrect) ...[
            _buildAnswerRow(context, 'Correct Answer', question.options[question.correctIndex].text, Colors.green, Icons.check_circle),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(question.explanation ?? 'No explanation provided.', style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(BuildContext context, String label, String answer, Color color, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            Text(answer, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
