import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/services/firebase_admin_service.dart';

class BatchQuizEditorScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final AdminQuiz? quiz;

  const BatchQuizEditorScreen({
    Key? key,
    required this.courseId,
    required this.batchId,
    this.quiz,
  }) : super(key: key);

  @override
  State<BatchQuizEditorScreen> createState() => _BatchQuizEditorScreenState();
}

class _BatchQuizEditorScreenState extends State<BatchQuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  List<QuizQuestion> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz?.title ?? '');
    _descriptionController = TextEditingController(text: widget.quiz?.description ?? '');
    _questions = List.from(widget.quiz?.questions ?? []);
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
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one question')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quizId = widget.quiz?.id ?? const Uuid().v4();
      final quiz = AdminQuiz(
        id: quizId,
        title: _titleController.text,
        description: _descriptionController.text,
        questions: _questions,
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
      );

      final adminService = Provider.of<FirebaseAdminService>(context, listen: false);
      await adminService.saveBatchQuiz(widget.courseId, widget.batchId, quiz, isNew: widget.quiz == null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz saved successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz == null ? 'Create Batch Quiz' : 'Edit Batch Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
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
               const SizedBox(height: 24),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('Questions (${_questions.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   FilledButton.tonalIcon(
                     onPressed: _addQuestion,
                     icon: const Icon(Icons.add),
                     label: const Text('Add Question'),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               if (_questions.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No questions added.', style: TextStyle(color: Colors.grey))))
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
                                   ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator)),
                                   const SizedBox(width: 8),
                                   Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                   const SizedBox(width: 16),
                                   // Question Type Dropdown
                                   DropdownButton<AnswerType>(
                                     value: _questions[index].answerType,
                                     items: const [
                                       DropdownMenuItem(value: AnswerType.multipleChoice, child: Text("Multiple Choice")),
                                       DropdownMenuItem(value: AnswerType.trueFalse, child: Text("True / False")),
                                     ],
                                     onChanged: (AnswerType? newValue) {
                                       if (newValue != null) {
                                         _updateQuestion(index, _questions[index].copyWith(answerType: newValue));
                                       }
                                     },
                                     underline: Container(), // Remove default underline
                                     icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                                     style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                   ),
                                   const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeQuestion(index),
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
                                 onChanged: (v) => _updateQuestion(index, _questions[index].copyWith(questionText: v)),
                               ),
                               const SizedBox(height: 16),
                               
                               // Answer Section based on Type
                               if (_questions[index].answerType == AnswerType.trueFalse) ...[
                                 const Text('Correct Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
                                 const SizedBox(height: 8),
                                 Row(
                                   children: [
                                     Expanded(
                                       child: RadioListTile<bool>(
                                         title: const Text('True'),
                                         value: true,
                                         groupValue: _questions[index].correctBooleanAnswer,
                                         onChanged: (v) {
                                           _updateQuestion(index, _questions[index].copyWith(correctBooleanAnswer: v));
                                         },
                                         activeColor: Colors.green,
                                         contentPadding: EdgeInsets.zero,
                                       ),
                                     ),
                                     Expanded(
                                       child: RadioListTile<bool>(
                                         title: const Text('False'),
                                         value: false,
                                         groupValue: _questions[index].correctBooleanAnswer,
                                         onChanged: (v) {
                                           _updateQuestion(index, _questions[index].copyWith(correctBooleanAnswer: v));
                                         },
                                         activeColor: Colors.red,
                                         contentPadding: EdgeInsets.zero,
                                       ),
                                     ),
                                   ],
                                 ),
                               ] 
                               else if (_questions[index].answerType == AnswerType.multipleChoice) ...[
                                 const Text('Options (Check correct answer):', style: TextStyle(fontWeight: FontWeight.bold)),
                                 const SizedBox(height: 8),
                                 ...List.generate(4, (optIndex) {
                                   final options = _questions[index].options;
                                   // Fix bounds if options are missing/corrupted
                                   if (options.length <= optIndex) return const SizedBox(); 
                                   
                                   final option = options[optIndex];
                                   return Padding(
                                     padding: const EdgeInsets.only(bottom: 8),
                                     child: Row(
                                       children: [
                                         Checkbox(
                                           value: option.isCorrect,
                                           onChanged: (v) {
                                              if (v == true) {
                                                final newOptions = options.asMap().entries.map((e) {
                                                  return e.value.copyWith(isCorrect: e.key == optIndex);
                                                }).toList();
                                                _updateQuestion(index, _questions[index].copyWith(options: newOptions));
                                              }
                                           },
                                         ),
                                         Expanded(
                                           child: TextFormField(
                                             initialValue: option.text,
                                             decoration: InputDecoration(
                                               labelText: 'Option ${String.fromCharCode(65 + optIndex)}',
                                               border: const OutlineInputBorder(),
                                               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                             ),
                                             onChanged: (v) {
                                               final newOptions = List<AnswerOption>.from(options);
                                               newOptions[optIndex] = newOptions[optIndex].copyWith(text: v);
                                               _updateQuestion(index, _questions[index].copyWith(options: newOptions));
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
                                   hintText: 'Explain why the answer is correct...',
                                   border: OutlineInputBorder(),
                                   prefixIcon: Icon(Icons.lightbulb_outline),
                                 ),
                                 maxLines: 3,
                                 minLines: 1,
                                 onChanged: (v) => _updateQuestion(index, _questions[index].copyWith(explanation: v)),
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
}
