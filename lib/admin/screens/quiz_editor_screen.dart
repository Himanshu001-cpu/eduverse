import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:uuid/uuid.dart';

/// Admin screen for creating and editing Quiz content
class QuizEditorScreen extends StatefulWidget {
  final FeedItem? feedItem; // If editing existing quiz

  const QuizEditorScreen({super.key, this.feedItem});

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Quiz details
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  // Questions
  List<QuizQuestion> _questions = [];
  
  // Feed items for left panel
  List<FeedItem> _feedItems = [];
  FeedItem? _selectedFeedItem;
  
  bool _isLoading = false;
  bool _isLoadingFeed = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    
    if (widget.feedItem != null) {
      _loadExistingQuiz();
    }
    _loadFeedItems();
  }

  void _loadExistingQuiz() {
    final item = widget.feedItem!;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _questions = List.from(item.quizQuestions ?? []);
    _selectedFeedItem = item;
  }

  Future<void> _loadFeedItems() async {
    try {
      final items = await FeedRepository().getFeedItems().first;
      if (mounted) {
        setState(() {
          _feedItems = items;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFeed = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestion(
        id: const Uuid().v4(),
        questionText: '',
        answerType: AnswerType.multipleChoice,
        options: [
          AnswerOption(id: const Uuid().v4(), text: '', isCorrect: true),
          AnswerOption(id: const Uuid().v4(), text: ''),
          AnswerOption(id: const Uuid().v4(), text: ''),
          AnswerOption(id: const Uuid().v4(), text: ''),
        ],
        score: 1,
      ));
    });
    
    // Scroll to bottom after adding
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _updateQuestion(int index, QuizQuestion updated) {
    setState(() {
      _questions[index] = updated;
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = widget.feedItem?.id ?? const Uuid().v4();
      
      final newItem = FeedItem(
        id: id,
        type: ContentType.quizzes,
        title: _titleController.text,
        description: _descriptionController.text,
        categoryLabel: 'QUIZ',
        emoji: '❓',
        color: Colors.purple,
        isPublic: true,
        quizQuestions: _questions,
      );

      await FeedRepository().addFeedItem(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectFeedItem(FeedItem item) {
    setState(() {
      _selectedFeedItem = item;
      if (item.type == ContentType.quizzes) {
        _titleController.text = item.title;
        _descriptionController.text = item.description;
        _questions = List.from(item.quizQuestions ?? []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use responsive layout - show sidebar only on wider screens
          final isWideScreen = constraints.maxWidth > 800;
          
          if (isWideScreen) {
            return Row(
              children: [
                // Left Sidebar - Feed Items List
                _buildFeedItemsList(),
                
                // Divider
                const VerticalDivider(width: 1),
                
                // Right Panel - Quiz Form
                Expanded(
                  child: _buildQuizForm(),
                ),
              ],
            );
          } else {
            // Single column layout for narrow screens
            return _buildQuizForm();
          }
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildFeedItemsList() {
    return SizedBox(
      width: 280, // Fixed width instead of percentage
      child: Container(
        color: Colors.grey.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Feed Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingFeed
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _feedItems.length,
                      itemBuilder: (context, index) {
                        final item = _feedItems[index];
                        final isSelected = _selectedFeedItem?.id == item.id;
                        return _FeedItemCard(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => _selectFeedItem(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz Details Section
                  _buildSectionHeader('Quiz Details'),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quiz Title',
                      hintText: 'Enter quiz title…',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.quiz),
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description…',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  // Questions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Questions (${_questions.length})'),
                      FilledButton.tonalIcon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Questions List
                  if (_questions.isEmpty)
                    Card(
                      color: Colors.grey.shade100,
                      child: const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No questions yet',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Click "Add Question" to start building your quiz',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: _reorderQuestions,
                      itemCount: _questions.length,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        return _QuestionCard(
                          key: ValueKey(_questions[index].id),
                          index: index,
                          question: _questions[index],
                          onUpdate: (q) => _updateQuestion(index, q),
                          onDelete: () => _removeQuestion(index),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Preview functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preview coming soon!')),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Preview Quiz'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: const Icon(Icons.publish),
            label: const Text('Publish'),
          ),
        ],
      ),
    );
  }
}

/// Feed Item Card for the left sidebar
class _FeedItemCard extends StatelessWidget {
  final FeedItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _typeIcon {
    switch (item.type) {
      case ContentType.videos:
        return Icons.play_circle_outline;
      case ContentType.articles:
        return Icons.article_outlined;
      case ContentType.quizzes:
        return Icons.quiz_outlined;
      case ContentType.jobs:
        return Icons.work_outline;
      default:
        return Icons.feed_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_typeIcon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
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
      ),
    );
  }
}

/// Question Card Component
class _QuestionCard extends StatefulWidget {
  final int index;
  final QuizQuestion question;
  final ValueChanged<QuizQuestion> onUpdate;
  final VoidCallback onDelete;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late TextEditingController _questionController;
  late TextEditingController _shortAnswerController;
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.questionText);
    _shortAnswerController = TextEditingController(text: widget.question.correctShortAnswer ?? '');
    _optionControllers = widget.question.options
        .map((o) => TextEditingController(text: o.text))
        .toList();
    
    // Ensure we have 4 option controllers for multiple choice
    while (_optionControllers.length < 4) {
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _shortAnswerController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateAnswerType(AnswerType type) {
    widget.onUpdate(widget.question.copyWith(answerType: type));
  }

  void _updateQuestionText(String text) {
    widget.onUpdate(widget.question.copyWith(questionText: text));
  }

  void _updateOption(int index, String text) {
    final options = List<AnswerOption>.from(widget.question.options);
    while (options.length <= index) {
      options.add(AnswerOption(id: const Uuid().v4(), text: ''));
    }
    options[index] = options[index].copyWith(text: text);
    widget.onUpdate(widget.question.copyWith(options: options));
  }

  void _setCorrectOption(int index) {
    final options = widget.question.options.asMap().entries.map((e) {
      return e.value.copyWith(isCorrect: e.key == index);
    }).toList();
    widget.onUpdate(widget.question.copyWith(options: options));
  }

  void _setCorrectBoolean(bool value) {
    widget.onUpdate(widget.question.copyWith(correctBooleanAnswer: value));
  }

  void _updateShortAnswer(String text) {
    widget.onUpdate(widget.question.copyWith(correctShortAnswer: text));
  }

  void _updateScore(int score) {
    widget.onUpdate(widget.question.copyWith(score: score));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Drag Handle and Question Number
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: const Icon(Icons.drag_indicator, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Question ${widget.index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                // Score
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Score: ', style: TextStyle(fontSize: 12)),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: widget.question.score.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _updateScore(int.tryParse(v) ?? 1),
                      ),
                    ),
                  ],
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Question',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Question Text Field
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'Enter your question...',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontWeight: FontWeight.w500),
              onChanged: _updateQuestionText,
            ),
            const SizedBox(height: 16),
            
            // Answer Type Toggle
            _buildAnswerTypeToggle(),
            const SizedBox(height: 16),
            
            // Answer Fields based on type
            _buildAnswerFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerTypeToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<AnswerType>(
        segments: const [
          ButtonSegment(
            value: AnswerType.multipleChoice,
            label: Text('Multiple Choice'),
            icon: Icon(Icons.check_box_outlined),
          ),
          ButtonSegment(
            value: AnswerType.trueFalse,
            label: Text('True/False'),
            icon: Icon(Icons.toggle_on_outlined),
          ),
          ButtonSegment(
            value: AnswerType.shortAnswer,
            label: Text('Short Answer'),
            icon: Icon(Icons.short_text),
          ),
        ],
        selected: {widget.question.answerType},
        onSelectionChanged: (selected) => _updateAnswerType(selected.first),
      ),
    );
  }

  Widget _buildAnswerFields() {
    switch (widget.question.answerType) {
      case AnswerType.multipleChoice:
        return _buildMultipleChoiceFields();
      case AnswerType.trueFalse:
        return _buildTrueFalseFields();
      case AnswerType.shortAnswer:
        return _buildShortAnswerField();
    }
  }

  Widget _buildMultipleChoiceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options (check the correct answer):',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ...List.generate(4, (index) {
          final isCorrect = index < widget.question.options.length 
              ? widget.question.options[index].isCorrect 
              : false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: isCorrect,
                  onChanged: (v) {
                    if (v == true) _setCorrectOption(index);
                  },
                  activeColor: Colors.green,
                ),
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Option ${String.fromCharCode(65 + index)}',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      fillColor: isCorrect ? Colors.green.shade50 : null,
                      filled: isCorrect,
                    ),
                    onChanged: (v) => _updateOption(index, v),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseFields() {
    final correctAnswer = widget.question.correctBooleanAnswer ?? true;
    return Row(
      children: [
        const Text('Correct Answer: '),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('True'),
          selected: correctAnswer == true,
          onSelected: (_) => _setCorrectBoolean(true),
          selectedColor: Colors.green.shade200,
          avatar: correctAnswer == true 
              ? const Icon(Icons.check, size: 18, color: Colors.green) 
              : null,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('False'),
          selected: correctAnswer == false,
          onSelected: (_) => _setCorrectBoolean(false),
          selectedColor: Colors.red.shade200,
          avatar: correctAnswer == false 
              ? const Icon(Icons.check, size: 18, color: Colors.red) 
              : null,
        ),
      ],
    );
  }

  Widget _buildShortAnswerField() {
    return TextFormField(
      controller: _shortAnswerController,
      decoration: const InputDecoration(
        labelText: 'Correct Answer',
        hintText: 'Enter the correct answer...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.check_circle_outline, color: Colors.green),
      ),
      onChanged: _updateShortAnswer,
    );
  }
}
