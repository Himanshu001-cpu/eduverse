import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/study/presentation/screens/study_quiz_result_screen.dart';

/// Quiz taking screen for Study section batches.
class StudyQuizScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final String quizId;
  final String quizTitle;
  final Color themeColor;

  const StudyQuizScreen({
    Key? key,
    required this.courseId,
    required this.batchId,
    required this.quizId,
    required this.quizTitle,
    this.themeColor = Colors.purple,
  }) : super(key: key);

  @override
  State<StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<StudyQuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  List<int?> _userAnswers = [];
  bool _showingAnswer = false;
  bool _isLoading = true;
  List<QuizQuestion> _questions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('batches')
          .doc(widget.batchId)
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Quiz not found';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final questionsData = (data['questions'] as List<dynamic>?) ?? [];
      
      _questions = questionsData.map((q) {
        final optionsData = (q['options'] as List<dynamic>?) ?? [];
        final options = optionsData.map((o) => AnswerOption(
          id: o['id'] ?? '',
          text: o['text'] ?? '',
          isCorrect: o['isCorrect'] ?? false,
        )).toList();

        return QuizQuestion(
          id: q['id'] ?? '',
          questionText: q['questionText'] ?? '',
          answerType: q['answerType'] == 'trueFalse' ? AnswerType.trueFalse : AnswerType.multipleChoice,
          options: options,
          explanation: q['explanation'],
          score: q['score'] ?? 1,
        );
      }).toList();

      _userAnswers = List.filled(_questions.length, null);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  QuizQuestion get _currentQuestion => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

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
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctIndex) {
        correctCount++;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudyQuizResultScreen(
          quizTitle: widget.quizTitle,
          questions: _questions,
          userAnswers: _userAnswers,
          correctCount: correctCount,
          themeColor: widget.themeColor,
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
    if (optionIndex == _currentQuestion.correctIndex) {
      return Colors.green.withOpacity(0.2);
    }
    if (_selectedOptionIndex == optionIndex && optionIndex != _currentQuestion.correctIndex) {
      return Colors.red.withOpacity(0.2);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getOptionBorderColor(int optionIndex) {
    if (!_showingAnswer) {
      if (_selectedOptionIndex == optionIndex) {
        return Theme.of(context).colorScheme.primary;
      }
      return Theme.of(context).colorScheme.outline.withOpacity(0.5);
    }
    if (optionIndex == _currentQuestion.correctIndex) {
      return Colors.green;
    }
    if (_selectedOptionIndex == optionIndex && optionIndex != _currentQuestion.correctIndex) {
      return Colors.red;
    }
    return Theme.of(context).colorScheme.outline.withOpacity(0.3);
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'No questions in this quiz', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(widget.themeColor),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Question ${_currentIndex + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.themeColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentQuestion.question,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 24),
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
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedOptionIndex == index
                                        ? colorScheme.primary.withOpacity(0.2)
                                        : colorScheme.surfaceContainerHighest,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedOptionIndex == index ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_currentQuestion.options[index].text, style: Theme.of(context).textTheme.bodyLarge)),
                                if (_getOptionIcon(index) != null)
                                  Icon(
                                    _getOptionIcon(index),
                                    color: index == _currentQuestion.correctIndex ? Colors.green : Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_showingAnswer && _currentQuestion.explanation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Explanation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentQuestion.explanation ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: colorScheme.onSurfaceVariant),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton.icon(onPressed: _previousQuestion, icon: const Icon(Icons.arrow_back), label: const Text('Previous'))
                  else
                    const SizedBox(width: 100),
                  const Spacer(),
                  if (!_showingAnswer)
                    FilledButton.icon(onPressed: _checkAnswer, icon: const Icon(Icons.check), label: const Text('Check Answer'))
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
