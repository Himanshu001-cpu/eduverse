import 'dart:async';
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
    super.key,
    required this.courseId,
    required this.batchId,
    required this.quizId,
    required this.quizTitle,
    this.themeColor = Colors.purple,
  });

  @override
  State<StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<StudyQuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  List<int?> _userAnswers = [];
  bool _instructionsShown = false;
  bool _isLoading = true;
  List<QuizQuestion> _questions = [];
  String? _error;

  // Timer and instructions state
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerStarted = false;
  String? _instructions;
  int? _timeLimitMinutes;
  int? _timeLimitSeconds;
  double? _marksPerQuestion;
  double? _negativeMarking;
  bool get _hasTimeLimit =>
      (_timeLimitSeconds != null && _timeLimitSeconds! > 0) ||
      (_timeLimitMinutes != null && _timeLimitMinutes! > 0);

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

      // Load instructions and time limit
      _instructions = data['instructions'] as String?;
      _timeLimitSeconds = data['timeLimitSeconds'] as int?;
      _timeLimitMinutes = data['timeLimitMinutes'] as int?;
      _marksPerQuestion = (data['marksPerQuestion'] as num?)?.toDouble();
      _negativeMarking = (data['negativeMarking'] as num?)?.toDouble();
      // Use seconds if available (more precise), otherwise use minutes
      if (_timeLimitSeconds != null && _timeLimitSeconds! > 0) {
        _remainingSeconds = _timeLimitSeconds!;
      } else if (_timeLimitMinutes != null && _timeLimitMinutes! > 0) {
        _remainingSeconds = _timeLimitMinutes! * 60;
      }

      _questions = questionsData.map((q) {
        final optionsData = (q['options'] as List<dynamic>?) ?? [];
        final options = optionsData
            .map(
              (o) => AnswerOption(
                id: o['id'] ?? '',
                text: o['text'] ?? '',
                isCorrect: o['isCorrect'] ?? false,
              ),
            )
            .toList();

        return QuizQuestion(
          id: q['id'] ?? '',
          questionText: q['questionText'] ?? '',
          answerType: q['answerType'] == 'trueFalse'
              ? AnswerType.trueFalse
              : AnswerType.multipleChoice,
          options: options,
          explanation: q['explanation'],
          score: q['score'] ?? 1,
          subject: q['subject'],
          negativeMarks: (q['negativeMarks'] as num?)?.toDouble(),
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

  void _startTimer() {
    if (!_hasTimeLimit) return;
    if (_timerStarted) return;

    _timerStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoSubmit();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _autoSubmit() {
    _timer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time\'s up! Quiz submitted automatically.'),
      ),
    );
    _finishQuiz();
  }

  String _formatTimer(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTimeLimitDisplay() {
    final totalSeconds = _timeLimitSeconds ?? (_timeLimitMinutes! * 60);
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    List<String> parts = [];
    if (hours > 0) parts.add('$hours hour${hours > 1 ? 's' : ''}');
    if (mins > 0) parts.add('$mins minute${mins > 1 ? 's' : ''}');
    if (secs > 0) parts.add('$secs second${secs > 1 ? 's' : ''}');

    return parts.isEmpty ? '0 minutes' : parts.join(' ');
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() {
      if (_selectedOptionIndex != null) {
        _userAnswers[_currentIndex] = _selectedOptionIndex;
      }
      _currentIndex = index;
      _selectedOptionIndex = _userAnswers[_currentIndex];
    });
  }

  QuizQuestion get _currentQuestion => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

  void _selectOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
      _userAnswers[_currentIndex] = index;
    });
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      _finishQuiz();
    } else {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = _userAnswers[_currentIndex];
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedOptionIndex = _userAnswers[_currentIndex];
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
          marksPerQuestion: _marksPerQuestion,
          negativeMarking: _negativeMarking,
        ),
      ),
    );
  }

  Color _getOptionColor(int optionIndex) {
    if (_selectedOptionIndex == optionIndex) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getOptionBorderColor(int optionIndex) {
    if (_selectedOptionIndex == optionIndex) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);
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
              Text(
                _error ?? 'No questions in this quiz',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_instructionsShown) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: widget.themeColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Quiz Instructions',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildInstructionItem(
                context,
                'Total Questions',
                '${_questions.length} Questions',
              ),
              _buildInstructionItem(context, 'Type', 'Multiple Choice'),
              if (_hasTimeLimit)
                _buildInstructionItem(
                  context,
                  'Time Limit',
                  _formatTimeLimitDisplay(),
                ),
              if (_marksPerQuestion != null && _marksPerQuestion! > 0)
                _buildInstructionItem(
                  context,
                  'Marks Per Question',
                  '$_marksPerQuestion',
                ),
              if (_negativeMarking != null && _negativeMarking! > 0)
                _buildInstructionItem(
                  context,
                  'Negative Marking',
                  '-$_negativeMarking',
                ),
              if ((_marksPerQuestion == null || _marksPerQuestion == 0) &&
                  (_negativeMarking == null || _negativeMarking == 0))
                _buildInstructionItem(
                  context,
                  'Marking',
                  'No negative marking',
                ),
              if (_instructions != null && _instructions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: widget.themeColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Additional Instructions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_instructions!, style: TextStyle(height: 1.5)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _instructionsShown = true;
                  });
                  _startTimer();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Start Quiz', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quizTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Timer display
          if (_hasTimeLimit)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 60
                        ? Colors.red.shade100
                        : colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: _remainingSeconds < 60
                            ? Colors.red
                            : colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimer(_remainingSeconds),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds < 60
                              ? Colors.red
                              : colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(widget.themeColor),
            ),
            // Question Navigation Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.surfaceContainerLow,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_questions.length, (index) {
                    final isAnswered = _userAnswers[index] != null;
                    final isCurrent = index == _currentIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Material(
                        color: isCurrent
                            ? widget.themeColor
                            : isAnswered
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _goToQuestion(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Colors.white
                                    : isAnswered
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Question ${_currentIndex + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.themeColor,
                            ),
                          ),
                        ),
                        if (_currentQuestion.subject != null &&
                            _currentQuestion.subject!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentQuestion.subject!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentQuestion.question,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
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
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedOptionIndex == index
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.2,
                                          )
                                        : colorScheme.surfaceContainerHighest,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
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
                                Expanded(
                                  child: Text(
                                    _currentQuestion.options[index].text,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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
                  if (_currentIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    )
                  else
                    const SizedBox(width: 100),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isLastQuestion ? _finishQuiz : _nextQuestion,
                    icon: Icon(
                      _isLastQuestion ? Icons.flag : Icons.arrow_forward,
                    ),
                    label: Text(_isLastQuestion ? 'Submit Quiz' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
