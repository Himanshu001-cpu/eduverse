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
    return widget.item.quizQuestions ?? _defaultQuestions;
  }

  QuizQuestion get _currentQuestion => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

  // Default questions if none provided
  static final List<QuizQuestion> _defaultQuestions = [
    QuizQuestion(
      id: 'q1',
      questionText: 'Which article of the Indian Constitution deals with the Right to Equality?',
      answerType: AnswerType.multipleChoice,
      options: [
        const AnswerOption(id: 'q1a', text: 'Article 12-18'),
        const AnswerOption(id: 'q1b', text: 'Article 14-18', isCorrect: true),
        const AnswerOption(id: 'q1c', text: 'Article 19-22'),
        const AnswerOption(id: 'q1d', text: 'Article 25-28'),
      ],
      explanation: 'Articles 14-18 of the Indian Constitution deal with the Right to Equality. Article 14 guarantees equality before law and equal protection of laws.',
    ),
    QuizQuestion(
      id: 'q2',
      questionText: 'The "Collegium System" is related to which of the following?',
      answerType: AnswerType.multipleChoice,
      options: [
        const AnswerOption(id: 'q2a', text: 'Election Commission'),
        const AnswerOption(id: 'q2b', text: 'Appointment of Judges', isCorrect: true),
        const AnswerOption(id: 'q2c', text: 'Civil Services'),
        const AnswerOption(id: 'q2d', text: 'Defense Services'),
      ],
      explanation: 'The Collegium System is a system for the appointment and transfer of judges in the Supreme Court and High Courts. It evolved through judicial interpretation.',
    ),
    QuizQuestion(
      id: 'q3',
      questionText: 'Which Five Year Plan in India was termed as "Industry and Transport" Plan?',
      answerType: AnswerType.multipleChoice,
      options: [
        const AnswerOption(id: 'q3a', text: 'First Five Year Plan'),
        const AnswerOption(id: 'q3b', text: 'Second Five Year Plan', isCorrect: true),
        const AnswerOption(id: 'q3c', text: 'Third Five Year Plan'),
        const AnswerOption(id: 'q3d', text: 'Fourth Five Year Plan'),
      ],
      explanation: 'The Second Five Year Plan (1956-61), also known as the Mahalanobis Plan, emphasized rapid industrialization with focus on heavy and basic industries.',
    ),
    QuizQuestion(
      id: 'q4',
      questionText: 'The concept of "Judicial Review" in India has been adopted from which country?',
      answerType: AnswerType.multipleChoice,
      options: [
        const AnswerOption(id: 'q4a', text: 'UK'),
        const AnswerOption(id: 'q4b', text: 'USA', isCorrect: true),
        const AnswerOption(id: 'q4c', text: 'France'),
        const AnswerOption(id: 'q4d', text: 'Germany'),
      ],
      explanation: 'Judicial Review in India has been adopted from the USA. The Supreme Court can declare any law unconstitutional if it violates fundamental rights.',
    ),
    QuizQuestion(
      id: 'q5',
      questionText: 'Which commission recommended the creation of All India Services?',
      answerType: AnswerType.multipleChoice,
      options: [
        const AnswerOption(id: 'q5a', text: 'Sarkaria Commission'),
        const AnswerOption(id: 'q5b', text: 'Simon Commission'),
        const AnswerOption(id: 'q5c', text: 'Lee Commission', isCorrect: true),
        const AnswerOption(id: 'q5d', text: 'Kothari Commission'),
      ],
      explanation: 'The Lee Commission (1923-24) recommended the creation of All India Services for maintaining unity and integrity of the country.',
    ),
  ];

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
