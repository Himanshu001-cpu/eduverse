import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/services/firebase_admin_service.dart';
import '../../admin/widgets/quiz_library_dialog.dart';

class BatchQuizEditorScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final AdminQuiz? quiz;

  const BatchQuizEditorScreen({
    super.key,
    required this.courseId,
    required this.batchId,
    this.quiz,
  });

  @override
  State<BatchQuizEditorScreen> createState() => _BatchQuizEditorScreenState();
}

class _BatchQuizEditorScreenState extends State<BatchQuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  String? _currentQuizId;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;
  Duration _quizTimeLimit = Duration.zero;
  late TextEditingController _marksPerQuestionController;
  late TextEditingController _negativeMarkingController;

  List<QuizQuestion> _questions = [];
  List<String> _subjects = [];
  bool _isLoading = false;
  bool _saveToLibrary = false;

  @override
  void initState() {
    super.initState();
    _currentQuizId = widget.quiz?.id;
    _titleController = TextEditingController(text: widget.quiz?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.quiz?.description ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.quiz?.instructions ?? '',
    );
    _marksPerQuestionController = TextEditingController(
      text: widget.quiz?.marksPerQuestion?.toString() ?? '',
    );
    _negativeMarkingController = TextEditingController(
      text: widget.quiz?.negativeMarking?.toString() ?? '',
    );
    // Load from seconds if available, fallback to minutes for backward compatibility
    if (widget.quiz?.timeLimitSeconds != null &&
        widget.quiz!.timeLimitSeconds! > 0) {
      _quizTimeLimit = Duration(seconds: widget.quiz!.timeLimitSeconds!);
    } else if (widget.quiz?.timeLimitMinutes != null &&
        widget.quiz!.timeLimitMinutes! > 0) {
      _quizTimeLimit = Duration(minutes: widget.quiz!.timeLimitMinutes!);
    }
    _questions = List.from(widget.quiz?.questions ?? []);
    _loadSubjects();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) => _autoSave());
  }

  /// Shows the [QuizLibraryDialog] and clones the selected quiz into the
  /// local editor state. A brand-new ID is generated so that any subsequent
  /// save writes to the batch path, not the library document.
  Future<void> _importFromLibrary() async {
    final adminService = Provider.of<FirebaseAdminService>(
      context,
      listen: false,
    );
    final selected = await showDialog<AdminQuiz>(
      context: context,
      builder: (_) => QuizLibraryDialog(adminService: adminService),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _titleController.text = selected.title;
      _descriptionController.text = selected.description;
      _instructionsController.text = selected.instructions;
      _marksPerQuestionController.text =
          selected.marksPerQuestion?.toString() ?? '';
      _negativeMarkingController.text =
          selected.negativeMarking?.toString() ?? '';

      // Restore time limit
      if (selected.timeLimitSeconds != null &&
          selected.timeLimitSeconds! > 0) {
        _quizTimeLimit = Duration(seconds: selected.timeLimitSeconds!);
      } else if (selected.timeLimitMinutes != null &&
          selected.timeLimitMinutes! > 0) {
        _quizTimeLimit = Duration(minutes: selected.timeLimitMinutes!);
      } else {
        _quizTimeLimit = Duration.zero;
      }

      // Deep-copy questions (keep their IDs — they are internal to the editor)
      _questions = List<QuizQuestion>.from(selected.questions);
      _hasUnsavedChanges = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported "${selected.title}" — modify & save to apply.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final adminService = Provider.of<FirebaseAdminService>(
        context,
        listen: false,
      );
      adminService.getSubjects().listen((subjects) {
        if (mounted) {
          setState(() {
            _subjects = subjects;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  Future<void> _addNewSubject(String name) async {
    try {
      final adminService = Provider.of<FirebaseAdminService>(
        context,
        listen: false,
      );
      await adminService.addSubject(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding subject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddSubjectDialog(int questionIndex) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Subject Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _addNewSubject(result);
      _updateQuestion(
        questionIndex,
        _questions[questionIndex].copyWith(subject: result),
      );
      if (mounted) setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _marksPerQuestionController.dispose();
    _negativeMarkingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _hasUnsavedChanges = true;
      _questions.add(
        QuizQuestion(
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
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _hasUnsavedChanges = true;
      _questions.removeAt(index);
    });
  }

  void _updateQuestion(int index, QuizQuestion updated) {
    setState(() {
      _hasUnsavedChanges = true;
      _questions[index] = updated;
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      _hasUnsavedChanges = true;
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }


  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges || _isAutoSaving || !mounted) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isAutoSaving = true);
    try {
      final quizId = _currentQuizId ?? const Uuid().v4();
      final timeLimitSeconds = _quizTimeLimit.inSeconds > 0 ? _quizTimeLimit.inSeconds : null;
      final timeLimitMinutes = _quizTimeLimit.inMinutes > 0 ? _quizTimeLimit.inMinutes : null;
      final marksPerQuestion = double.tryParse(_marksPerQuestionController.text);
      final negativeMarking = double.tryParse(_negativeMarkingController.text);

      final quiz = AdminQuiz(
        id: quizId,
        title: _titleController.text,
        description: _descriptionController.text,
        instructions: _instructionsController.text,
        timeLimitMinutes: timeLimitMinutes,
        timeLimitSeconds: timeLimitSeconds,
        marksPerQuestion: marksPerQuestion,
        negativeMarking: negativeMarking,
        questions: _questions,
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
      );

      final adminService = Provider.of<FirebaseAdminService>(context, listen: false);
      await adminService.saveBatchQuiz(
        widget.courseId,
        widget.batchId,
        quiz,
        isNew: _currentQuizId == null,
      );

      _currentQuizId = quizId;

      if (_saveToLibrary) {
        await adminService.saveToQuizPool(quiz);
      }

      if (mounted) setState(() => _hasUnsavedChanges = false);
    } catch (e) {
      debugPrint('Auto-save error: $e');
    } finally {
      if (mounted) setState(() => _isAutoSaving = false);
    }
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
      final quizId = _currentQuizId ?? const Uuid().v4();
      // Save in seconds for precision, also keep minutes for backward compatibility
      final timeLimitSeconds = _quizTimeLimit.inSeconds > 0
          ? _quizTimeLimit.inSeconds
          : null;
      final timeLimitMinutes = _quizTimeLimit.inMinutes > 0
          ? _quizTimeLimit.inMinutes
          : null;
      final marksPerQuestion = double.tryParse(
        _marksPerQuestionController.text,
      );
      final negativeMarking = double.tryParse(_negativeMarkingController.text);

      final quiz = AdminQuiz(
        id: quizId,
        title: _titleController.text,
        description: _descriptionController.text,
        instructions: _instructionsController.text,
        timeLimitMinutes: timeLimitMinutes,
        timeLimitSeconds: timeLimitSeconds,
        marksPerQuestion: marksPerQuestion,
        negativeMarking: negativeMarking,
        questions: _questions,
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
      );

      final adminService = Provider.of<FirebaseAdminService>(
        context,
        listen: false,
      );
      await adminService.saveBatchQuiz(
        widget.courseId,
        widget.batchId,
        quiz,
        isNew: _currentQuizId == null,
      );
      
      _currentQuizId = quizId;

      // Optionally publish to the global quiz library
      if (_saveToLibrary) {
        await adminService.saveToQuizPool(quiz);
      }

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz == null ? 'Create Batch Quiz' : 'Edit Batch Quiz',
        ),
        actions: [
          if (_isAutoSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text('Saving...',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          IconButton(
            icon: const Icon(Icons.library_books_rounded),
            tooltip: 'Import from Library',
            onPressed: _isLoading ? null : _importFromLibrary,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() => _hasUnsavedChanges = true),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Quiz Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.quiz),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'Enter quiz instructions for students...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Settings
              const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _marksPerQuestionController,
                      decoration: const InputDecoration(
                        labelText: 'Marks Per Question',
                        hintText: 'e.g., 2.0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star_outline),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _negativeMarkingController,
                      decoration: const InputDecoration(
                        labelText: 'Negative Marking (Penalty)',
                        hintText: 'e.g., 0.25',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.remove_circle_outline),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time Limit Picker
              Text('Time Limit', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _buildDurationPicker(),
              const SizedBox(height: 16),

              // Save to Global Library toggle
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _saveToLibrary
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
                  ),
                ),
                color: _saveToLibrary
                    ? Theme.of(context).colorScheme.primaryContainer
                        .withValues(alpha: 0.35)
                    : null,
                child: SwitchListTile(
                  title: const Text(
                    'Save to Global Library',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Makes this quiz available for import in other Batches & Test Series.',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: Icon(
                    Icons.library_books_rounded,
                    color: _saveToLibrary
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  value: _saveToLibrary,
                  onChanged: (v) => setState(() {
                    _saveToLibrary = v;
                    _hasUnsavedChanges = true;
                  }),
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions (${_questions.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_questions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No questions added.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: _reorderQuestions,
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      key: ValueKey(_questions[index].id),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(Icons.drag_indicator),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Question ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Question Type Dropdown
                                DropdownButton<AnswerType>(
                                  value: _questions[index].answerType,
                                  items: const [
                                    DropdownMenuItem(
                                      value: AnswerType.multipleChoice,
                                      child: Text("Multiple Choice"),
                                    ),
                                    DropdownMenuItem(
                                      value: AnswerType.trueFalse,
                                      child: Text("True / False"),
                                    ),
                                  ],
                                  onChanged: (AnswerType? newValue) {
                                    if (newValue != null) {
                                      _updateQuestion(
                                        index,
                                        _questions[index].copyWith(
                                          answerType: newValue,
                                        ),
                                      );
                                    }
                                  },
                                  underline:
                                      Container(), // Remove default underline
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.blue,
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeQuestion(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Score and Subject Row
                            Row(
                              children: [
                                const Text(
                                  'Score: ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    initialValue: _questions[index].score
                                        .toString(),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => _updateQuestion(
                                      index,
                                      _questions[index].copyWith(
                                        score: int.tryParse(v) ?? 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Subject: ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                DropdownButton<String>(
                                  value:
                                      _questions[index].subject != null &&
                                          _subjects.contains(
                                            _questions[index].subject,
                                          )
                                      ? _questions[index].subject
                                      : null,
                                  hint: const Text(
                                    'None',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'None',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    ..._subjects.map(
                                      (sub) => DropdownMenuItem(
                                        value: sub,
                                        child: Text(
                                          sub,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    const DropdownMenuItem<String>(
                                      value: '__ADD_NEW__',
                                      child: Text(
                                        '+ Add New',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val == '__ADD_NEW__') {
                                      _showAddSubjectDialog(index);
                                    } else {
                                      _updateQuestion(
                                        index,
                                        _questions[index].copyWith(
                                          subject: val,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Question Text
                            TextFormField(
                              initialValue: _questions[index].questionText,
                              decoration: const InputDecoration(
                                labelText: 'Question Text',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.help_outline),
                              ),
                              maxLines: 2,
                              minLines: 1,
                              onChanged: (v) => _updateQuestion(
                                index,
                                _questions[index].copyWith(questionText: v),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Answer Section based on Type
                            if (_questions[index].answerType ==
                                AnswerType.trueFalse) ...[
                              const Text(
                                'Correct Answer:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              RadioGroup<bool>(
                                groupValue:
                                    _questions[index].correctBooleanAnswer ??
                                    true,
                                onChanged: (v) {
                                  _updateQuestion(
                                    index,
                                    _questions[index].copyWith(
                                      correctBooleanAnswer: v,
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: const Text('True'),
                                        value: true,
                                        activeColor: Colors.green,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: const Text('False'),
                                        value: false,
                                        activeColor: Colors.red,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_questions[index].answerType ==
                                AnswerType.multipleChoice) ...[
                              const Text(
                                'Options (Check correct answer):',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(4, (optIndex) {
                                final options = _questions[index].options;
                                // Fix bounds if options are missing/corrupted
                                if (options.length <= optIndex)
                                  return const SizedBox();

                                final option = options[optIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: option.isCorrect,
                                        onChanged: (v) {
                                          if (v == true) {
                                            final newOptions = options
                                                .asMap()
                                                .entries
                                                .map((e) {
                                                  return e.value.copyWith(
                                                    isCorrect:
                                                        e.key == optIndex,
                                                  );
                                                })
                                                .toList();
                                            _updateQuestion(
                                              index,
                                              _questions[index].copyWith(
                                                options: newOptions,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: option.text,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Option ${String.fromCharCode(65 + optIndex)}',
                                            border: const OutlineInputBorder(),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                          ),
                                          onChanged: (v) {
                                            final newOptions =
                                                List<AnswerOption>.from(
                                                  options,
                                                );
                                            newOptions[optIndex] =
                                                newOptions[optIndex].copyWith(
                                                  text: v,
                                                );
                                            _updateQuestion(
                                              index,
                                              _questions[index].copyWith(
                                                options: newOptions,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],

                            const SizedBox(height: 16),

                            // Explanation Field
                            TextFormField(
                              initialValue: _questions[index].explanation,
                              decoration: const InputDecoration(
                                labelText: 'Explanation (Optional)',
                                hintText:
                                    'Explain why the answer is correct...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lightbulb_outline),
                              ),
                              maxLines: 3,
                              minLines: 1,
                              onChanged: (v) => _updateQuestion(
                                index,
                                _questions[index].copyWith(explanation: v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationPicker() {
    final hours = _quizTimeLimit.inHours;
    final minutes = _quizTimeLimit.inMinutes % 60;
    final seconds = _quizTimeLimit.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          // Hours
          _buildDurationField('Hours', hours, (val) {
            setState(() {
              _hasUnsavedChanges = true;
              _quizTimeLimit = Duration(
                hours: val,
                minutes: minutes,
                seconds: seconds,
              );
            });
          }),
          const SizedBox(width: 8),
          Text(
            ':',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          // Minutes
          _buildDurationField('Minutes', minutes, (val) {
            setState(() {
              _hasUnsavedChanges = true;
              _quizTimeLimit = Duration(
                hours: hours,
                minutes: val,
                seconds: seconds,
              );
            });
          }),
          const SizedBox(width: 8),
          Text(
            ':',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          // Seconds
          _buildDurationField('Seconds', seconds, (val) {
            setState(() {
              _hasUnsavedChanges = true;
              _quizTimeLimit = Duration(
                hours: hours,
                minutes: minutes,
                seconds: val,
              );
            });
          }),
          const Spacer(),
          if (_quizTimeLimit > Duration.zero)
            TextButton(
              onPressed: () => setState(() {
                _hasUnsavedChanges = true;
                _quizTimeLimit = Duration.zero;
              }),
              child: Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationField(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
        SizedBox(
          width: 50,
          child: TextFormField(
            initialValue: value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v) ?? 0;
              onChanged(parsed.clamp(0, label == 'Hours' ? 99 : 59));
            },
          ),
        ),
      ],
    );
  }
}
