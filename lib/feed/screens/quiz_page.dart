// file: lib/feed/screens/quiz_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/screens/quiz_result_page.dart';

/// Quiz page for practicing multiple choice questions.
/// Shows one question at a time with option tiles and navigation.
class QuizPage extends StatefulWidget {
  final FeedItem item;

  const QuizPage({super.key, required this.item});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  final List<int?> _userAnswers = [];
  bool _showingAnswer = false;

  List<QuizQuestion> get _questions {
    return widget.item.quizQuestions ?? [];
  }

  QuizQuestion get _currentQuestion => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

  @override
  void initState() {
    super.initState();
    _userAnswers.addAll(List.filled(_questions.length, null));
  }

  void _selectOption(int index) {
    if (_showingAnswer) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option')),
      );
      return;
    }
    setState(() {
      _showingAnswer = true;
      _userAnswers[_currentIndex] = _selectedOptionIndex;
    });
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      _finishQuiz();
    } else {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = _userAnswers[_currentIndex];
        _showingAnswer = _selectedOptionIndex != null;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedOptionIndex = _userAnswers[_currentIndex];
        _showingAnswer = _selectedOptionIndex != null;
      });
    }
  }

  void _finishQuiz() {
    // Calculate score
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctIndex) {
        correctCount++;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultPage(
          item: widget.item,
          questions: _questions,
          userAnswers: _userAnswers,
          correctCount: correctCount,
        ),
      ),
    );
  }

  Color _getOptionColor(int optionIndex) {
    if (!_showingAnswer) {
      if (_selectedOptionIndex == optionIndex) {
        return Theme.of(context).colorScheme.primaryContainer;
      }
      return Theme.of(context).colorScheme.surface;
    }

    // Showing answer
    if (optionIndex == _currentQuestion.correctIndex) {
      return Colors.green.withValues(alpha: 0.2);
    }
    if (_selectedOptionIndex == optionIndex && optionIndex != _currentQuestion.correctIndex) {
      return Colors.red.withValues(alpha: 0.2);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getOptionBorderColor(int optionIndex) {
    if (!_showingAnswer) {
      if (_selectedOptionIndex == optionIndex) {
        return Theme.of(context).colorScheme.primary;
      }
      return Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);
    }

    // Showing answer
    if (optionIndex == _currentQuestion.correctIndex) {
      return Colors.green;
    }
    if (_selectedOptionIndex == optionIndex && optionIndex != _currentQuestion.correctIndex) {
      return Colors.red;
    }
    return Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
  }

  IconData? _getOptionIcon(int optionIndex) {
    if (!_showingAnswer) return null;

    if (optionIndex == _currentQuestion.correctIndex) {
      return Icons.check_circle;
    }
    if (_selectedOptionIndex == optionIndex && optionIndex != _currentQuestion.correctIndex) {
      return Icons.cancel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;

    // Handle empty questions
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No questions available', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('This quiz has no questions yet.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_questions.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(item.color),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Question ${_currentIndex + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Question text
                    Text(
                      _currentQuestion.question,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Options
                    ...List.generate(
                      _currentQuestion.options.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectOption(index),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getOptionColor(index),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getOptionBorderColor(index),
                                width: _selectedOptionIndex == index ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Option letter
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedOptionIndex == index
                                        ? colorScheme.primary.withValues(alpha: 0.2)
                                        : colorScheme.surfaceContainerHighest,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index), // A, B, C, D
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedOptionIndex == index
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Option text
                                Expanded(
                                  child: Text(
                                    _currentQuestion.options[index].text,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                // Correct/Wrong icon
                                if (_getOptionIcon(index) != null)
                                  Icon(
                                    _getOptionIcon(index),
                                    color: index == _currentQuestion.correctIndex
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Explanation (when answer is shown)
                    if (_showingAnswer) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Explanation',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentQuestion.explanation ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom navigation
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
                  // Previous button
                  if (_currentIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    )
                  else
                    const SizedBox(width: 100),
                  const Spacer(),
                  // Check/Next/Finish button
                  if (!_showingAnswer)
                    FilledButton.icon(
                      onPressed: _checkAnswer,
                      icon: const Icon(Icons.check),
                      label: const Text('Check Answer'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _nextQuestion,
                      icon: Icon(_isLastQuestion ? Icons.flag : Icons.arrow_forward),
                      label: Text(_isLastQuestion ? 'Finish Quiz' : 'Next'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
