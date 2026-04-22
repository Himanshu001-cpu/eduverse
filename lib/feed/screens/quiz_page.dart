import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduverse/core/utils/markdown_utils.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/screens/quiz_result_page.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _instructionsShown = false;

  // Timer state
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerStarted = false;

  List<QuizQuestion> get _questions {
    return widget.item.quizQuestions ?? [];
  }

  QuizQuestion get _currentQuestion => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;
  int? get _timeLimitMinutes => widget.item.quizTimeLimitMinutes;
  int? get _timeLimitSeconds => widget.item.quizTimeLimitSeconds;
  String? get _customInstructions => widget.item.quizInstructions;
  bool get _hasTimeLimit =>
      (_timeLimitSeconds != null && _timeLimitSeconds! > 0) ||
      (_timeLimitMinutes != null && _timeLimitMinutes! > 0);

  @override
  void initState() {
    super.initState();
    _userAnswers.addAll(List.filled(_questions.length, null));
    // Debug: print timer values
    print(
      'DEBUG Quiz Timer - Minutes: $_timeLimitMinutes, Seconds: $_timeLimitSeconds',
    );
    // Use seconds if available (more precise), otherwise use minutes
    if (_timeLimitSeconds != null && _timeLimitSeconds! > 0) {
      _remainingSeconds = _timeLimitSeconds!;
      print('DEBUG: Using seconds value: $_remainingSeconds');
    } else if (_timeLimitMinutes != null && _timeLimitMinutes! > 0) {
      _remainingSeconds = _timeLimitMinutes! * 60;
      print(
        'DEBUG: Using minutes value converted to seconds: $_remainingSeconds',
      );
    } else {
      print('DEBUG: No time limit set');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    // Format for display in instructions (human readable)
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
      // Save current answer if selected
      if (_selectedOptionIndex != null) {
        _userAnswers[_currentIndex] = _selectedOptionIndex;
      }
      _currentIndex = index;
      _selectedOptionIndex = _userAnswers[_currentIndex];
    });
  }

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

  void _handleShare() {
    final String deepLink =
        'https://theeduverse.co.in/app/feed/${widget.item.id}';
    final String shareText =
        'Take this Quiz on EduVerse:\n\n'
        '${widget.item.title}\n\n'
        'Attempt here: $deepLink';

    SharePlus.instance.share(ShareParams(text: shareText));
  }

  Color _getOptionBackground(int optionIndex) {
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
              Text(
                'No questions available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'This quiz has no questions yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_instructionsShown) {
      return Scaffold(
        appBar: AppBar(
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: _handleShare),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: colorScheme.primary,
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
              if (item.quizMarksPerQuestion != null &&
                  item.quizMarksPerQuestion! > 0)
                _buildInstructionItem(
                  context,
                  'Marks Per Question',
                  '${item.quizMarksPerQuestion}',
                ),
              if (item.quizNegativeMarking != null &&
                  item.quizNegativeMarking! > 0)
                _buildInstructionItem(
                  context,
                  'Negative Marking',
                  '-${item.quizNegativeMarking}',
                ),
              if ((item.quizMarksPerQuestion == null ||
                      item.quizMarksPerQuestion == 0) &&
                  (item.quizNegativeMarking == null ||
                      item.quizNegativeMarking == 0))
                _buildInstructionItem(
                  context,
                  'Marking',
                  'No negative marking',
                ),
              if (_customInstructions != null &&
                  _customInstructions!.isNotEmpty) ...[
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
                            color: colorScheme.primary,
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
                      Text(_customInstructions!, style: TextStyle(height: 1.5)),
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
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _handleShare),
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
          // Progress indicator
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
            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(item.color),
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
                            ? colorScheme.primary
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
                                    ? colorScheme.onPrimary
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
                    // Question number badge and Subject
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                    // Question text
                    MarkdownBody(
                      data: MarkdownUtils.normalizeMarkdown(
                        _currentQuestion.question,
                      ),
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
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
                              color: _getOptionBackground(index),
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
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.2,
                                          )
                                        : colorScheme.surfaceContainerHighest,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(
                                        65 + index,
                                      ), // A, B, C, D
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
                  // Next/Finish button
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
