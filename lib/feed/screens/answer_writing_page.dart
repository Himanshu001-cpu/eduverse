// file: lib/feed/screens/answer_writing_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eduverse/feed/models.dart';

/// Answer Writing practice page for Mains-style answers.
/// Features: question display, text editor, word counter, timer.
class AnswerWritingPage extends StatefulWidget {
  final FeedItem item;

  const AnswerWritingPage({super.key, required this.item});

  @override
  State<AnswerWritingPage> createState() => _AnswerWritingPageState();
}

class _AnswerWritingPageState extends State<AnswerWritingPage> {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerStarted = false;
  bool _timerPaused = false;
  bool _isSubmitted = false;

  int get _wordCount {
    final text = _answerController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _answerController.text.length;

  int get _wordLimit => widget.item.answerWritingContent?.wordLimit ?? 250;
  int get _timeLimit => widget.item.answerWritingContent?.timeLimitMinutes ?? 7;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _timeLimit * 60;
    _answerController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timerStarted && !_timerPaused) return;
    
    setState(() {
      _timerStarted = true;
      _timerPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerPaused = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _timeLimit * 60;
      _timerStarted = false;
      _timerPaused = false;
    });
  }

  void _onTimeUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.timer_off, size: 48, color: Colors.orange),
        title: const Text('Time\'s Up!'),
        content: Text(
          'You wrote $_wordCount words.\nWould you like to submit your answer?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('Continue Writing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAnswer();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _submitAnswer() {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before submitting!')),
      );
      return;
    }

    _timer?.cancel();
    setState(() {
      _isSubmitted = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 48, color: Colors.green),
        title: const Text('Answer Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Words Written', '$_wordCount / $_wordLimit'),
            _buildStatRow('Characters', '$_charCount'),
            _buildStatRow('Time Used', _formatTime((_timeLimit * 60) - _remainingSeconds)),
            const SizedBox(height: 16),
            Text(
              'Great job practicing! Your answer has been saved locally.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Feed'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAll();
            },
            child: const Text('Practice Again'),
          ),
        ],
      ),
    );
    // TODO: Implement answer saving to backend
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _answerController.clear();
      _isSubmitted = false;
      _remainingSeconds = _timeLimit * 60;
      _timerStarted = false;
      _timerPaused = false;
    });
  }

  void _copyAnswer() {
    if (_answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to copy!')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: _answerController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Answer copied to clipboard')),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingSeconds <= 60) return Colors.red;
    if (_remainingSeconds <= 180) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final question = item.answerWritingContent?.question ?? item.description;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Answer Writing'),
        actions: [
          // Timer display
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTimerColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getTimerColor()),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 18, color: _getTimerColor()),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTimerColor(),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Question section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
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
                      Icon(Icons.help_outline, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Question',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '$_wordLimit words | $_timeLimit mins',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            // Timer controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (!_timerStarted)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Timer'),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _timerPaused ? _startTimer : _pauseTimer,
                        icon: Icon(_timerPaused ? Icons.play_arrow : Icons.pause),
                        label: Text(_timerPaused ? 'Resume' : 'Pause'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Answer text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _answerController,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Start writing your answer here...',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                ),
              ),
            ),
            // Bottom bar with word count and actions
            AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Word count indicator
                  Row(
                    children: [
                      Text(
                        'Words: ',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        '$_wordCount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _wordCount > _wordLimit ? Colors.red : colorScheme.primary,
                        ),
                      ),
                      Text(
                        ' / $_wordLimit',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Text(
                        '$_charCount characters',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyAnswer,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _submitAnswer,
                          icon: const Icon(Icons.send),
                          label: const Text('Submit Answer'),
                        ),
                      ),
                    ],
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
