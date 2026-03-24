// file: lib/feed/screens/answer_writing_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eduverse/feed/models.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduverse/core/utils/markdown_utils.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/core/firebase/auth_service.dart';

/// Answer Writing practice page for Mains-style answers.
/// Features: question display, text editor, word counter, timer.
class AnswerWritingPage extends StatefulWidget {
  final FeedItem item;

  const AnswerWritingPage({super.key, required this.item});

  @override
  State<AnswerWritingPage> createState() => _AnswerWritingPageState();
}

class _AnswerWritingPageState extends State<AnswerWritingPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerStarted = false;
  bool _timerPaused = false;
  bool _isSubmitted = false;

  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    _answerController.addListener(() {
      if (!_timerStarted &&
          !_timerPaused &&
          _answerController.text.trim().isNotEmpty) {
        _startTimer();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
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
    // Auto-submit when time is up
    if (!_isSubmitted) {
      _submitAnswer(autoSubmit: true);
    }
  }

  void _submitAnswer({bool autoSubmit = false}) {
    if (!autoSubmit && _answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something before submitting!'),
        ),
      );
      return;
    }

    _timer?.cancel();
    setState(() {
      _isSubmitted = true;
    });

    if (autoSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time is up! auto-submitting answer.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      final feedRepo = FeedRepository();
      final timeTaken = (_timeLimit * 60) - _remainingSeconds;
      feedRepo
          .submitAnswer(
            widget.item.id,
            user.uid,
            _answerController.text.trim(),
            timeTaken,
          )
          .catchError((e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving answer: $e')),
              );
            }
          });
    }
  }

  void _resetAll() {
    setState(() {
      _answerController.clear();
      _isSubmitted = false;
      _remainingSeconds = _timeLimit * 60;
      _timerStarted = false;
      _timerPaused = false;
      _tabController.index = 0;
    });
  }

  void _copyAnswer() {
    if (_answerController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing to copy!')));
      return;
    }
    Clipboard.setData(ClipboardData(text: _answerController.text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Answer copied to clipboard')));
  }

  void _handleShare() {
    final String deepLink =
        'https://theeduverse.co.in/app/feed/${widget.item.id}';
    final String shareText =
        'Practice Answer Writing on EduVerse:\n\n'
        'Question: ${widget.item.title}\n\n'
        'Start writing here: $deepLink';

    SharePlus.instance.share(ShareParams(text: shareText));
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
    if (_isSubmitted) {
      return _buildResultView();
    }
    return _buildWritingView();
  }

  Widget _buildWritingView() {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final question = item.answerWritingContent?.question ?? item.description;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Answer Writing'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _handleShare),
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
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.5),
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
                        icon: Icon(
                          _timerPaused ? Icons.play_arrow : Icons.pause,
                        ),
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
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.6),
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
                          color: _wordCount > _wordLimit
                              ? Colors.red
                              : colorScheme.primary,
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
                          onPressed: () => _submitAnswer(autoSubmit: false),
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

  Widget _buildResultView() {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final question = item.answerWritingContent?.question ?? item.description;
    final modelAnswer =
        item.answerWritingContent?.modelAnswer ??
        'No model answer available for this question.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Comparison'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Your Answer'),
            Tab(text: 'Model Answer'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerLowest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Words', '$_wordCount / $_wordLimit'),
                _buildStatItem(
                  'Time',
                  _formatTime((_timeLimit * 60) - _remainingSeconds),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Question Header (collapsible/short)
          ExpansionTile(
            title: Text(
              'Question',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(question)),
            ],
          ),
          const Divider(height: 1),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // User Answer Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _answerController.text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
                // Model Answer Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: MarkdownUtils.normalizeMarkdown(modelAnswer),
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.6),
                        ),
                      ),
                      if (item.answerWritingContent?.keyPoints.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Key Points:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...item.answerWritingContent!.keyPoints.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(child: Text(point)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back to Feed'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _resetAll,
                    child: const Text('Practice Again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
