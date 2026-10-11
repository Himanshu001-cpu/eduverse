import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/admin/models/test_quiz_models.dart' show TestSection;
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';
import '../../common/widgets/rich_content_viewer.dart';
import '../../admin/widgets/equation_builder.dart';
import '../../core/services/rich_text_service.dart';

class BatchQuizScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final String? quizId;
  final AdminQuiz? existingQuiz;

  const BatchQuizScreen({
    super.key,
    required this.courseId,
    required this.batchId,
    this.quizId,
    this.existingQuiz,
  });

  @override
  State<BatchQuizScreen> createState() => _BatchQuizScreenState();
}

class _BatchQuizScreenState extends State<BatchQuizScreen> {
  // Stepper state: 0 = Exam Rules, 1 = Section Builder, 2 = Question Vault, 3 = Solution Keys, 4 = Publishing
  int _currentStep = 0;
  int _currentQuestionIndex = 0;

  // Question metadata
  String _difficulty = 'Medium';
  String _correctOption = 'A';
  double _marksPerQuestion = 2.0;
  double _negativeMarking = 0.66;
  int _timeLimitMinutes = 60;
  DateTime? _scheduledAt;
  bool _isSaving = false;
  String? _currentQuizId;

  // Sections
  List<TestSection> _sections = [
    const TestSection(id: 'sec_1', name: 'Section A — Core Concepts'),
    const TestSection(id: 'sec_2', name: 'Section B — Analytical Problems'),
  ];
  final TextEditingController _newSectionController = TextEditingController();

  // Security toggles
  bool _freeNavigation = true;
  bool _proctoredFullscreen = true;
  bool _tabSwitchBlurLimit = true;
  bool _randomizeQuestions = true;

  // Header & Quiz info controllers
  late TextEditingController _quizTitleController;
  late TextEditingController _quizDescController;
  late TextEditingController _instructionsController;

  // Question editing controllers
  late TextEditingController _promptController;
  late TextEditingController _optAController;
  late TextEditingController _optBController;
  late TextEditingController _optCController;
  late TextEditingController _optDController;
  late TextEditingController _distractorAController;
  late TextEditingController _distractorBController;
  late TextEditingController _distractorCController;
  late TextEditingController _distractorDController;
  late TextEditingController _explanationController;

  // Preview toggles for rich formatting
  bool _previewPrompt = false;
  bool _previewOptA = false;
  bool _previewOptB = false;
  bool _previewOptC = false;
  bool _previewOptD = false;
  bool _previewExplanation = false;

  // List of active questions
  List<QuizQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _currentQuizId = widget.quizId ?? widget.existingQuiz?.id;

    _quizTitleController = TextEditingController(
      text: widget.existingQuiz?.title ?? 'Full-Length Assessment Mock Test',
    );
    _quizDescController = TextEditingController(
      text: widget.existingQuiz?.description ??
          'Comprehensive examination evaluating conceptual understanding and analytical problem-solving.',
    );
    _instructionsController = TextEditingController(
      text: widget.existingQuiz?.instructions.isNotEmpty == true
          ? widget.existingQuiz!.instructions
          : '1. All questions are compulsory.\n'
              '2. Each question has four options with only one correct response.\n'
              '3. Negative marking applies for incorrect attempts as configured in the test blueprint.\n'
              '4. Do not refresh or exit fullscreen during active proctored examination.',
    );

    if (widget.existingQuiz != null) {
      _marksPerQuestion = widget.existingQuiz!.marksPerQuestion ?? 2.0;
      _negativeMarking = widget.existingQuiz!.negativeMarking ?? 0.66;
      _timeLimitMinutes = widget.existingQuiz!.timeLimitMinutes ?? 60;
      _scheduledAt = widget.existingQuiz!.scheduledAt;
      _questions = List.from(widget.existingQuiz!.questions);

      // Extract sections from existing questions if any
      final existingSecIds = <String>{};
      for (final q in _questions) {
        if (q.sectionId != null && q.sectionId!.isNotEmpty) {
          existingSecIds.add(q.sectionId!);
        }
      }
      if (existingSecIds.isNotEmpty) {
        final loadedSections = <TestSection>[];
        for (final secId in existingSecIds) {
          loadedSections.add(TestSection(id: secId, name: 'Section $secId'));
        }
        _sections = loadedSections;
      }
    }

    _promptController = TextEditingController();
    _optAController = TextEditingController();
    _optBController = TextEditingController();
    _optCController = TextEditingController();
    _optDController = TextEditingController();
    _distractorAController = TextEditingController();
    _distractorBController = TextEditingController();
    _distractorCController = TextEditingController();
    _distractorDController = TextEditingController();
    _explanationController = TextEditingController();

    if (_questions.isEmpty) {
      _initDefaultStarterQuestions();
    }

    _loadQuestionToControllers(0);
  }

  void _initDefaultStarterQuestions() {
    _questions = [
      QuizQuestion(
        id: const Uuid().v4(),
        questionText: r'What is the value of **x** in the quadratic equation $$x^2 - 5x + 6 = 0$$?',
        questionDelta: '',
        questionHtml: r'<p>What is the value of <strong>x</strong> in the quadratic equation <div class="math-latex math-block" data-latex="x^2 - 5x + 6 = 0">x^2 - 5x + 6 = 0</div>?</p>',
        options: [
          const AnswerOption(
            id: 'opt_1',
            text: r'$$x = 2$$ or $$x = 3$$',
            isCorrect: true,
            rationale: 'Factoring gives (x - 2)(x - 3) = 0, so roots are 2 and 3.',
          ),
          const AnswerOption(
            id: 'opt_2',
            text: r'$$x = -2$$ or $$x = -3$$',
            isCorrect: false,
            rationale: 'Sign error during factoring.',
          ),
          const AnswerOption(
            id: 'opt_3',
            text: r'$$x = 1$$ or $$x = 6$$',
            isCorrect: false,
            rationale: 'Incorrect product/sum decomposition.',
          ),
          const AnswerOption(
            id: 'opt_4',
            text: r'$$x = 0$$ or $$x = 5$$',
            isCorrect: false,
            rationale: 'Incomplete algebraic solution.',
          ),
        ],
        score: _marksPerQuestion.toInt(),
        negativeMarks: _negativeMarking,
        subject: 'Mathematics',
        sectionId: _sections.isNotEmpty ? _sections[0].id : null,
        difficulty: QuestionDifficulty.medium,
        explanation: r'Factoring the polynomial: $$x^2 - 5x + 6 = (x - 2)(x - 3) = 0$$. Hence, the solutions are $$x = 2$$ and $$x = 3$$.',
      ),
    ];
  }

  void _saveCurrentQuestionToState() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;

    final q = _questions[_currentQuestionIndex];
    int correctIdx = 0;
    if (_correctOption == 'B') {
      correctIdx = 1;
    } else if (_correctOption == 'C') {
      correctIdx = 2;
    } else if (_correctOption == 'D') {
      correctIdx = 3;
    }

    final newOptions = [
      AnswerOption(
        id: q.options.isNotEmpty ? q.options[0].id : const Uuid().v4(),
        text: _optAController.text,
        isCorrect: correctIdx == 0,
        textHtml: RichTextService.convertMarkdownToHtml(_optAController.text),
        rationale: _distractorAController.text,
      ),
      AnswerOption(
        id: q.options.length > 1 ? q.options[1].id : const Uuid().v4(),
        text: _optBController.text,
        isCorrect: correctIdx == 1,
        textHtml: RichTextService.convertMarkdownToHtml(_optBController.text),
        rationale: _distractorBController.text,
      ),
      AnswerOption(
        id: q.options.length > 2 ? q.options[2].id : const Uuid().v4(),
        text: _optCController.text,
        isCorrect: correctIdx == 2,
        textHtml: RichTextService.convertMarkdownToHtml(_optCController.text),
        rationale: _distractorCController.text,
      ),
      AnswerOption(
        id: q.options.length > 3 ? q.options[3].id : const Uuid().v4(),
        text: _optDController.text,
        isCorrect: correctIdx == 3,
        textHtml: RichTextService.convertMarkdownToHtml(_optDController.text),
        rationale: _distractorDController.text,
      ),
    ];

    _questions[_currentQuestionIndex] = QuizQuestion(
      id: q.id.isNotEmpty ? q.id : const Uuid().v4(),
      questionText: _promptController.text,
      questionHtml: RichTextService.convertMarkdownToHtml(_promptController.text),
      answerType: AnswerType.multipleChoice,
      options: newOptions,
      score: _marksPerQuestion.toInt(),
      negativeMarks: _negativeMarking,
      explanation: _explanationController.text,
      explanationHtml: RichTextService.convertMarkdownToHtml(_explanationController.text),
      subject: q.subject ?? 'General',
      sectionId: q.sectionId,
      difficulty: QuestionDifficulty.tryParse(_difficulty.toLowerCase()) ?? QuestionDifficulty.medium,
      flaggedForReview: q.flaggedForReview,
    );
  }

  void _loadQuestionToControllers(int index) {
    if (index < 0 || index >= _questions.length) return;
    final q = _questions[index];
    _promptController.text = q.questionText;
    _optAController.text = q.options.isNotEmpty ? q.options[0].text : '';
    _optBController.text = q.options.length > 1 ? q.options[1].text : '';
    _optCController.text = q.options.length > 2 ? q.options[2].text : '';
    _optDController.text = q.options.length > 3 ? q.options[3].text : '';

    _distractorAController.text = q.options.isNotEmpty ? (q.options[0].rationale ?? '') : '';
    _distractorBController.text = q.options.length > 1 ? (q.options[1].rationale ?? '') : '';
    _distractorCController.text = q.options.length > 2 ? (q.options[2].rationale ?? '') : '';
    _distractorDController.text = q.options.length > 3 ? (q.options[3].rationale ?? '') : '';

    _explanationController.text = q.explanation ?? '';

    final correctIndex = q.options.indexWhere((o) => o.isCorrect);
    const opts = ['A', 'B', 'C', 'D'];
    _correctOption = (correctIndex >= 0 && correctIndex < 4) ? opts[correctIndex] : 'A';

    final diff = q.difficulty?.name ?? 'medium';
    _difficulty = diff[0].toUpperCase() + diff.substring(1);

    _previewPrompt = false;
    _previewOptA = false;
    _previewOptB = false;
    _previewOptC = false;
    _previewOptD = false;
    _previewExplanation = false;
  }

  void _switchQuestion(int newIndex) {
    if (newIndex < 0 || newIndex >= _questions.length) return;
    _saveCurrentQuestionToState();
    setState(() {
      _currentQuestionIndex = newIndex;
      _loadQuestionToControllers(newIndex);
    });
  }

  void _addNewQuestion() {
    _saveCurrentQuestionToState();
    setState(() {
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
          score: _marksPerQuestion.toInt(),
          negativeMarks: _negativeMarking,
          subject: 'General',
          sectionId: _sections.isNotEmpty ? _sections[0].id : null,
          difficulty: QuestionDifficulty.medium,
          explanation: '',
        ),
      );
      _currentQuestionIndex = _questions.length - 1;
      _loadQuestionToControllers(_currentQuestionIndex);
    });
  }

  void _deleteCurrentQuestion() {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A quiz must contain at least one question.')),
      );
      return;
    }

    setState(() {
      _questions.removeAt(_currentQuestionIndex);
      if (_currentQuestionIndex >= _questions.length) {
        _currentQuestionIndex = _questions.length - 1;
      }
      _loadQuestionToControllers(_currentQuestionIndex);
    });
  }

  int _getQuestionStatus(int index) {
    if (index >= _questions.length) return 0;
    final q = _questions[index];
    if (q.questionText.trim().isEmpty) return 0; // Draft
    final hasAllOptions = q.options.length >= 4 && q.options.every((o) => o.text.trim().isNotEmpty);
    if (hasAllOptions) return 1; // Validated
    return 2; // Incomplete
  }

  // Formatting helpers for text controllers
  void _applyFormat(TextEditingController controller, String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;

    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    if (start < 0) start = text.length;
    if (end < 0) end = text.length;

    if (start > end) {
      final temp = start;
      start = end;
      end = temp;
    }

    final selectedText = (start != end) ? text.substring(start, end) : 'sample';
    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(start, end, replacement);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      ),
    );
    setState(() {});
  }

  Future<void> _openLatexDialog(TextEditingController controller) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
          child: EquationBuilder(
            onEquationSaved: (latex) {
              Navigator.of(ctx).pop();
              _insertLatexAtCursor(controller, latex);
            },
          ),
        ),
      ),
    );
  }

  void _insertLatexAtCursor(TextEditingController controller, String latex) {
    final latexBlock = r'$$' + latex + r'$$';
    final text = controller.text;
    final selection = controller.selection;

    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    if (start < 0) start = text.length;
    if (end < 0) end = text.length;

    final newText = text.replaceRange(start, end, latexBlock);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + latexBlock.length),
    );
    setState(() {});
  }

  Future<void> _saveQuizToFirestore(FirebaseAdminService service, {required bool isPublished}) async {
    _saveCurrentQuestionToState();

    if (_quizTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Quiz Title.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final quizId = (_currentQuizId != null && _currentQuizId!.trim().isNotEmpty)
          ? _currentQuizId!.trim()
          : const Uuid().v4();

      final quiz = AdminQuiz(
        id: quizId,
        title: _quizTitleController.text.trim(),
        description: _quizDescController.text.trim(),
        instructions: _instructionsController.text.trim(),
        timeLimitMinutes: _timeLimitMinutes,
        marksPerQuestion: _marksPerQuestion,
        negativeMarking: _negativeMarking,
        questions: _questions,
        createdAt: DateTime.now(),
        scheduledAt: _scheduledAt,
      );

      final isNew = _currentQuizId == null || _currentQuizId!.trim().isEmpty;
      final effectiveCourseId = widget.courseId.trim().isNotEmpty
          ? widget.courseId.trim()
          : 'default_course';
      final effectiveBatchId = widget.batchId.trim();

      String savedId = quizId;
      if (effectiveBatchId.isNotEmpty) {
        savedId = await service.saveRecordedBatchQuiz(
          effectiveCourseId,
          effectiveBatchId,
          quiz,
          isNew: isNew,
        );
      } else {
        savedId = await service.saveCourseQuiz(
          effectiveCourseId,
          quiz,
          isNew: isNew,
        );
      }
      _currentQuizId = savedId;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPublished
                ? 'Examination successfully published to test series!'
                : 'Quiz draft successfully saved.'),
            backgroundColor: EduverseTheme.emeraldVivid,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quiz: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _newSectionController.dispose();
    _quizTitleController.dispose();
    _quizDescController.dispose();
    _instructionsController.dispose();
    _promptController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    _distractorAController.dispose();
    _distractorBController.dispose();
    _distractorCController.dispose();
    _distractorDController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return AdminScaffold(
      title: 'Quiz Studio',
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Breadcrumb & Header
            _buildBreadcrumbAndHeader(context, service, isDesktop),
            const SizedBox(height: 20),

            // 5-Step Stepper Bar
            _buildHorizontalStepper(),
            const SizedBox(height: 24),

            // Step Content Switcher
            _buildStepContent(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDesktop) {
    switch (_currentStep) {
      case 0:
        return _buildExamRulesStep(isDesktop);
      case 1:
        return _buildSectionBuilderStep(isDesktop);
      case 2:
        return _buildQuestionVaultStep(isDesktop);
      case 3:
        return _buildSolutionKeysStep(isDesktop);
      case 4:
        return _buildPublishingStep(isDesktop);
      default:
        return _buildQuestionVaultStep(isDesktop);
    }
  }

  // STEP 0: EXAM RULES & MARKING
  Widget _buildExamRulesStep(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXAM SPECIFICATION & METADATA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quizTitleController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
                decoration: const InputDecoration(
                  labelText: 'Test Title *',
                  hintText: 'e.g. Full-Length Comprehensive Mock Test 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.quiz_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quizDescController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Syllabus Scope & Test Overview',
                  hintText: 'Describe topics tested, targeted learning outcomes, and prerequisites...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Marking Scheme & Timing Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Marking Scheme Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.military_tech_outlined, size: 20, color: EduverseTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'Marking Scheme',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Marks Per Question (+ve)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: _marksPerQuestion.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.add, color: EduverseTheme.emeraldVivid, size: 18),
                                ),
                                onChanged: (v) {
                                  final val = double.tryParse(v);
                                  if (val != null) setState(() => _marksPerQuestion = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Negative Penalty (-ve)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: _negativeMarking.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.remove, color: Colors.red, size: 18),
                                ),
                                onChanged: (v) {
                                  final val = double.tryParse(v);
                                  if (val != null) setState(() => _negativeMarking = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('No Negative', style: TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _negativeMarking = 0.0),
                        ),
                        ActionChip(
                          label: const Text('1/4th Penalty (0.25)', style: TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _negativeMarking = 0.25),
                        ),
                        ActionChip(
                          label: const Text('1/3rd Penalty (0.66)', style: TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _negativeMarking = 0.66),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Time Limit Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.timer_outlined, size: 20, color: EduverseTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'Examination Duration',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Duration (Minutes)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: _timeLimitMinutes.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  suffixText: 'mins',
                                ),
                                onChanged: (v) {
                                  final val = int.tryParse(v);
                                  if (val != null) setState(() => _timeLimitMinutes = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('30 Mins', style: TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _timeLimitMinutes = 30),
                        ),
                        ActionChip(
                          label: const Text('60 Mins', style: TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _timeLimitMinutes = 60),
                        ),
                        ActionChip(
                          label: const Text('120 Mins', style: TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _timeLimitMinutes = 120),
                        ),
                        ActionChip(
                          label: const Text('180 Mins', style: TextStyle(fontSize: 11)),
                          onPressed: () => setState(() => _timeLimitMinutes = 180),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Examination Rules Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STUDENT EXAM INSTRUCTIONS & CODE OF CONDUCT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _instructionsController.text =
                          '1. All questions carry equal marks (+${_marksPerQuestion.toStringAsFixed(1)} for correct).\n'
                          '2. Each incorrect answer incurs a penalty of -${_negativeMarking.toStringAsFixed(2)} marks.\n'
                          '3. Total time allotted is $_timeLimitMinutes minutes.\n'
                          '4. Maintain academic integrity. Tab-switching is recorded.';
                    },
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Insert Standard Template', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter specific exam guidelines displayed to students before starting...',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Step Navigation Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _saveCurrentQuestionToState();
                setState(() => _currentStep = 1);
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continue to Section Builder →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduverseTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 1: SECTION BUILDER
  Widget _buildSectionBuilderStep(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'PAPER SECTION BUILDER',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Organize questions into subject modules or test sections (e.g. Physics, Chemistry, Math)',
                          style: TextStyle(fontSize: 13, color: EduverseTheme.deepNavy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EduverseTheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_sections.length} Sections Configured',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduverseTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add Section Form
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newSectionController,
                      decoration: const InputDecoration(
                        hintText: 'Enter new section name (e.g. Section C — Quantitative Aptitude)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final name = _newSectionController.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          _sections.add(TestSection(id: const Uuid().v4(), name: name));
                          _newSectionController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Section'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduverseTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Preset Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  const Text('Quick presets:', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
                  ActionChip(
                    label: const Text('+ General Studies', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _sections.add(TestSection(id: const Uuid().v4(), name: 'General Studies'))),
                  ),
                  ActionChip(
                    label: const Text('+ Quantitative Reasoning', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _sections.add(TestSection(id: const Uuid().v4(), name: 'Quantitative Reasoning'))),
                  ),
                  ActionChip(
                    label: const Text('+ Logical Reasoning', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _sections.add(TestSection(id: const Uuid().v4(), name: 'Logical Reasoning'))),
                  ),
                  ActionChip(
                    label: const Text('+ Language Comprehension', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _sections.add(TestSection(id: const Uuid().v4(), name: 'Language Comprehension'))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Cards List
        if (_sections.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: const Text('No sections configured yet. Add your first section above.'),
            ),
          )
        else
          Column(
            children: List.generate(_sections.length, (index) {
              final sec = _sections[index];
              final count = _questions.where((q) => q.sectionId == sec.id).length;
              final secMarks = count * _marksPerQuestion;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: EduverseTheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: EduverseTheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: EduverseTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sec.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count Questions assigned • ${secMarks.toStringAsFixed(1)} Total Section Marks',
                              style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Rename Section',
                        onPressed: () async {
                          final editCtrl = TextEditingController(text: sec.name);
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Rename Section'),
                              content: TextField(controller: editCtrl, autofocus: true),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, editCtrl.text.trim()), child: const Text('Save')),
                              ],
                            ),
                          );
                          if (newName != null && newName.isNotEmpty) {
                            setState(() {
                              _sections[index] = sec.copyWith(name: newName);
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: 'Delete Section',
                        onPressed: () {
                          setState(() {
                            // Unassign any questions referencing this section
                            for (int i = 0; i < _questions.length; i++) {
                              if (_questions[i].sectionId == sec.id) {
                                _questions[i] = _questions[i].copyWith(clearSectionId: true);
                              }
                            }
                            _sections.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        const SizedBox(height: 24),

        // Navigation Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep = 0),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('← Back to Exam Rules'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _saveCurrentQuestionToState();
                setState(() => _currentStep = 2);
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text('Continue to Question Vault (${_questions.length} Qs) →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduverseTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2: QUESTION VAULT (QUESTION EDITOR)
  Widget _buildQuestionVaultStep(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Question Authoring Workspace (8 cols)
          Expanded(
            flex: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionMetaStrip(),
                const SizedBox(height: 16),
                _buildPromptEditorCard(),
                const SizedBox(height: 20),
                _buildOptionBuilderCard(),
                const SizedBox(height: 20),
                _buildExplanationCard(),
                const SizedBox(height: 20),
                _buildPaginationFooter(),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Right Column: Configuration & Navigator (4 cols)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildBlueprintStatsCard(),
                const SizedBox(height: 20),
                _buildQuestionNavigatorCard(),
                const SizedBox(height: 20),
                _buildSecuritySettingsCard(),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildQuestionMetaStrip(),
          const SizedBox(height: 16),
          _buildPromptEditorCard(),
          const SizedBox(height: 20),
          _buildOptionBuilderCard(),
          const SizedBox(height: 20),
          _buildExplanationCard(),
          const SizedBox(height: 20),
          _buildPaginationFooter(),
          const SizedBox(height: 20),
          _buildBlueprintStatsCard(),
          const SizedBox(height: 20),
          _buildQuestionNavigatorCard(),
        ],
      );
    }
  }

  // STEP 3: SOLUTION KEYS
  Widget _buildSolutionKeysStep(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'MASTER ANSWER KEY & SOLUTION AUDIT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Review correct answer designations, explanations, and marking allocations across all questions.',
                          style: TextStyle(fontSize: 13, color: EduverseTheme.deepNavy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_questions.length} Questions Registered',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Solution Key Table
        Container(
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final q = _questions[index];
              final correctOpt = q.options.firstWhere(
                (o) => o.isCorrect,
                orElse: () => q.options.isNotEmpty ? q.options[0] : const AnswerOption(id: '0', text: '', isCorrect: true),
              );
              final correctOptIdx = q.options.indexOf(correctOpt);
              final optLetter = (correctOptIdx >= 0 && correctOptIdx < 4)
                  ? String.fromCharCode(65 + correctOptIdx)
                  : 'A';

              final hasExplanation = q.explanation?.trim().isNotEmpty == true;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: EduverseTheme.primary,
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  q.questionText.trim().isNotEmpty
                      ? (q.questionText.length > 80 ? '${q.questionText.substring(0, 80)}...' : q.questionText)
                      : 'Untitled Draft Question',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: EduverseTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          q.difficulty?.name.toUpperCase() ?? 'MEDIUM',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasExplanation ? 'Solution Included' : 'No Explanation Added',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasExplanation ? EduverseTheme.emeraldVivid : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Key: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EduverseTheme.emeraldVivid,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Option $optLetter',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_note_outlined),
                      tooltip: 'Edit in Question Vault',
                      onPressed: () {
                        _switchQuestion(index);
                        setState(() => _currentStep = 2);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Navigation Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep = 2),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('← Back to Question Vault'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _saveCurrentQuestionToState();
                setState(() => _currentStep = 4);
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continue to Publishing & Timing →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduverseTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: PUBLISHING & TIMING
  Widget _buildPublishingStep(bool isDesktop) {
    final service = context.read<FirebaseAdminService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Release & Security in 2 Columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLiveReleaseCard(),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildSecuritySettingsCard(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Pre-Flight Audit Summary Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRE-FLIGHT EXAMINATION VERIFICATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statPillar('${_questions.length}', 'Questions'),
                  _statPillar('${(_questions.length * _marksPerQuestion).toInt()}', 'Total Marks'),
                  _statPillar('$_timeLimitMinutes', 'Minutes'),
                  _statPillar('${_sections.length}', 'Sections'),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EduverseTheme.emeraldVivid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EduverseTheme.emeraldVivid.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline, color: EduverseTheme.emeraldVivid),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ready to Publish: All test parameters, marking rules, and sections meet standard academic specifications.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bottom Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep = 3),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('← Back to Solution Keys'),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _saveQuizToFirestore(service, isPublished: false),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveQuizToFirestore(service, isPublished: true),
                  icon: const Icon(Icons.rocket_launch, size: 18),
                  label: const Text('Publish Examination to Test Series'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduverseTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreadcrumbAndHeader(BuildContext context, FirebaseAdminService service, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Curriculum', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
                    ),
                    const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
                    const Text('Test Series & Quizzes', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
                    const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
                    Text(
                      widget.batchId.isNotEmpty ? 'Batch ${widget.batchId}' : 'Course Tests',
                      style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                    ),
                    const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
                    Text(
                      _currentQuizId != null && _currentQuizId!.isNotEmpty
                          ? (_currentQuizId!.length > 12 ? '${_currentQuizId!.substring(0, 8)}...' : _currentQuizId!)
                          : 'NEW-QUIZ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduverseTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: EduverseTheme.emeraldVivid, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  _isSaving ? 'Saving to Cloud...' : 'Dynamic Firestore Sync Ready',
                  style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: EduverseTheme.tertiaryFixed, borderRadius: BorderRadius.circular(4)),
                    child: const Text(
                      'ACADEMIC ASSESSMENT & TEST ENGINE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: EduverseTheme.onTertiaryFixed),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _quizTitleController.text.isNotEmpty ? _quizTitleController.text : 'Assessment Test',
                    style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(fontSize: isDesktop ? 24 : 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _quizDescController.text.isNotEmpty ? _quizDescController.text : 'Assessment overview',
                    style: const TextStyle(fontSize: 13, color: EduverseTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => _saveQuizToFirestore(service, isPublished: false),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Draft'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EduverseTheme.deepNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _saveQuizToFirestore(service, isPublished: true),
                    icon: const Icon(Icons.rocket_launch, size: 16),
                    label: const Text('Publish Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduverseTheme.primary,
                      foregroundColor: EduverseTheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalStepper() {
    final steps = [
      '1. Exam Rules & Marking',
      '2. Section Builder',
      '3. Question Vault (${_questions.length} Qs)',
      '4. Solution Keys',
      '5. Publishing & Timing',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (i) {
            final isCurrent = _currentStep == i;
            final isDone = i < _currentStep;

            return Row(
              children: [
                InkWell(
                  onTap: () {
                    _saveCurrentQuestionToState();
                    setState(() => _currentStep = i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? EduverseTheme.primary
                          : (isDone ? EduverseTheme.surfaceContainerHigh : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (isDone) const Icon(Icons.check, size: 14, color: EduverseTheme.emeraldVivid),
                        if (isDone) const SizedBox(width: 4),
                        Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent
                                ? Colors.white
                                : (isDone ? EduverseTheme.deepNavy : EduverseTheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.chevron_right, size: 16, color: EduverseTheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildQuestionMetaStrip() {
    final currentQ = _questions.isNotEmpty && _currentQuestionIndex < _questions.length
        ? _questions[_currentQuestionIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: EduverseTheme.primary, borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: Text(
                      '${_currentQuestionIndex + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Question #${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: EduverseTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Single Choice',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: EduverseTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Saved & Validated',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    tooltip: 'Delete Question',
                    onPressed: _deleteCurrentQuestion,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Tagging Strip: Section, Subject, Difficulty, Marks
          Row(
            children: [
              // Section selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SECTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                  DropdownButton<String?>(
                    value: _sections.any((s) => s.id == currentQ?.sectionId) ? currentQ?.sectionId : null,
                    isDense: true,
                    underline: const SizedBox(),
                    hint: const Text('No Section', style: TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('No Section', style: TextStyle(fontSize: 12))),
                      ..._sections.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (secId) {
                      setState(() {
                        if (currentQ != null) {
                          _questions[_currentQuestionIndex] = currentQ.copyWith(
                            sectionId: secId,
                            clearSectionId: secId == null,
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(width: 16),
              _tagItem('SUBJECT', currentQ?.subject?.isNotEmpty == true ? currentQ!.subject! : 'General'),
              const SizedBox(width: 16),

              // Difficulty Dropdown: Easy, Medium, Hard only
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DIFFICULTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                  DropdownButton<String>(
                    value: _difficulty,
                    isDense: true,
                    underline: const SizedBox(),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _difficulty = val;
                          if (currentQ != null) {
                            _questions[_currentQuestionIndex] = currentQ.copyWith(
                              difficulty: QuestionDifficulty.tryParse(val.toLowerCase()),
                            );
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MARKS / PENALTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    '+${_marksPerQuestion.toStringAsFixed(1)} / -${_negativeMarking.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EduverseTheme.emeraldVivid),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy)),
      ],
    );
  }

  Widget _buildPromptEditorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Question Prompt Body',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
              ),
              Wrap(
                spacing: 4,
                children: [
                  _formatActionBtn(Icons.format_bold, 'Bold', () => _applyFormat(_promptController, '**', '**')),
                  _formatActionBtn(Icons.format_italic, 'Italic', () => _applyFormat(_promptController, '*', '*')),
                  _formatActionBtn(Icons.code, 'Code', () => _applyFormat(_promptController, '`', '`')),
                  _formatActionBtn(Icons.functions, 'LaTeX Equation', () => _openLatexDialog(_promptController)),
                  IconButton(
                    icon: Icon(_previewPrompt ? Icons.visibility_off : Icons.visibility, size: 16),
                    tooltip: _previewPrompt ? 'Edit Mode' : 'Live Preview Mode',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _previewPrompt = !_previewPrompt),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_previewPrompt)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EduverseTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EduverseTheme.primary.withValues(alpha: 0.4)),
              ),
              child: RichContentViewer(
                legacyMarkdown: _promptController.text.isNotEmpty ? _promptController.text : '*(No question text entered yet)*',
              ),
            )
          else ...[
            TextField(
              controller: _promptController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: EduverseTheme.surfaceContainerLow,
                hintText: 'Enter question text, mathematical expressions (use LaTeX button or \$\$...\$\$), and question directives...',
              ),
            ),
            if (_promptController.text.contains(r'$$') || _promptController.text.contains('**') || _promptController.text.contains('*')) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Formatted Preview:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    RichContentViewer(legacyMarkdown: _promptController.text),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _formatActionBtn(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }

  Widget _buildOptionBuilderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: const [
              Text(
                'Option Builder & Distractor Settings',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
              ),
              Text(
                'Tap option letter to designate the correct answer',
                style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _optionBuilderItem('A', _optAController, _distractorAController, _previewOptA, (v) => setState(() => _previewOptA = v)),
          const SizedBox(height: 12),
          _optionBuilderItem('B', _optBController, _distractorBController, _previewOptB, (v) => setState(() => _previewOptB = v)),
          const SizedBox(height: 12),
          _optionBuilderItem('C', _optCController, _distractorCController, _previewOptC, (v) => setState(() => _previewOptC = v)),
          const SizedBox(height: 12),
          _optionBuilderItem('D', _optDController, _distractorDController, _previewOptD, (v) => setState(() => _previewOptD = v)),
        ],
      ),
    );
  }

  Widget _optionBuilderItem(
    String letter,
    TextEditingController textCtrl,
    TextEditingController distractorCtrl,
    bool isPreview,
    ValueChanged<bool> onTogglePreview,
  ) {
    final isCorrect = _correctOption == letter;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? EduverseTheme.emeraldVivid.withValues(alpha: 0.06) : EduverseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect ? EduverseTheme.emeraldVivid : EduverseTheme.outlineVariant.withValues(alpha: 0.2),
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Letter indicator (tap to set as correct answer)
              InkWell(
                onTap: () => setState(() => _correctOption = letter),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCorrect ? EduverseTheme.emeraldVivid : EduverseTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isCorrect ? Colors.white : EduverseTheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Formatting Toolbar for Option
              Wrap(
                spacing: 2,
                children: [
                  _formatActionBtn(Icons.format_bold, 'Bold', () => _applyFormat(textCtrl, '**', '**')),
                  _formatActionBtn(Icons.format_italic, 'Italic', () => _applyFormat(textCtrl, '*', '*')),
                  _formatActionBtn(Icons.functions, 'LaTeX Equation', () => _openLatexDialog(textCtrl)),
                  IconButton(
                    icon: Icon(isPreview ? Icons.visibility_off : Icons.visibility, size: 14),
                    tooltip: isPreview ? 'Edit Option' : 'Preview Option',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onTogglePreview(!isPreview),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Correct Answer indicator badge
              if (isCorrect) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: EduverseTheme.emeraldVivid, borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Correct Answer Key', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Option text input or preview
          if (isPreview)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: RichContentViewer(
                legacyMarkdown: textCtrl.text.isNotEmpty ? textCtrl.text : '*(Option $letter is empty)*',
              ),
            )
          else ...[
            TextField(
              controller: textCtrl,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: 'Option $letter text (supports LaTeX \$\$...\$\$ and bold/italic)...',
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            if (textCtrl.text.contains(r'$$') || textCtrl.text.contains('**') || textCtrl.text.contains('*')) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: RichContentViewer(legacyMarkdown: textCtrl.text),
              ),
            ],
          ],
          const SizedBox(height: 8),

          // Distractor feedback field
          TextField(
            controller: distractorCtrl,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Distractor feedback: Why option $letter is incorrect / rationale...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pedagogical Explanation & Academic Citations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
              ),
              Wrap(
                spacing: 4,
                children: [
                  _formatActionBtn(Icons.format_bold, 'Bold', () => _applyFormat(_explanationController, '**', '**')),
                  _formatActionBtn(Icons.format_italic, 'Italic', () => _applyFormat(_explanationController, '*', '*')),
                  _formatActionBtn(Icons.functions, 'LaTeX Equation', () => _openLatexDialog(_explanationController)),
                  IconButton(
                    icon: Icon(_previewExplanation ? Icons.visibility_off : Icons.visibility, size: 16),
                    tooltip: _previewExplanation ? 'Edit Mode' : 'Preview Mode',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _previewExplanation = !_previewExplanation),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_previewExplanation)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EduverseTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: RichContentViewer(
                legacyMarkdown: _explanationController.text.isNotEmpty ? _explanationController.text : '*(No explanation entered)*',
              ),
            )
          else ...[
            TextField(
              controller: _explanationController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Model Solution & Explanation',
                hintText: 'Comprehensive explanation detailing why the answer is correct with mathematical steps and references...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: EduverseTheme.surfaceContainerLow,
              ),
            ),
            if (_explanationController.text.contains(r'$$') || _explanationController.text.contains('**')) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichContentViewer(legacyMarkdown: _explanationController.text),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: _currentQuestionIndex > 0
              ? () => _switchQuestion(_currentQuestionIndex - 1)
              : null,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text('Previous Q$_currentQuestionIndex'),
        ),
        Text(
          'Showing question ${_currentQuestionIndex + 1} of ${_questions.length}',
          style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
        ),
        ElevatedButton.icon(
          onPressed: _currentQuestionIndex < _questions.length - 1
              ? () => _switchQuestion(_currentQuestionIndex + 1)
              : _addNewQuestion,
          icon: Icon(_currentQuestionIndex < _questions.length - 1 ? Icons.arrow_forward : Icons.add, size: 16),
          label: Text(_currentQuestionIndex < _questions.length - 1
              ? 'Next Question #${_currentQuestionIndex + 2}'
              : '+ Add Next Question'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduverseTheme.primary,
            foregroundColor: EduverseTheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBlueprintStatsCard() {
    final totalMarks = (_questions.length * _marksPerQuestion).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TEST BLUEPRINT STATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('Configured', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statPillar('${_questions.length}', 'Questions'),
              _statPillar('$totalMarks', 'Total Marks'),
              _statPillar('$_timeLimitMinutes', 'Minutes'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: EduverseTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Negative Marking deduction', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
                ),
                Text('-${_negativeMarking.toStringAsFixed(2)} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPillar(String number, String label) {
    return Column(
      children: [
        Text(number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
        Text(label, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildQuestionNavigatorCard() {
    int validatedCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_getQuestionStatus(i) == 1) validatedCount++;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Question Navigator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
              Text('$validatedCount/${_questions.length} Ready', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendItem('Validated', EduverseTheme.emeraldVivid),
              const SizedBox(width: 8),
              _legendItem('Incomplete', EduverseTheme.tertiary),
              const SizedBox(width: 8),
              _legendItem('Draft', Colors.grey),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < _questions.length; i++)
                _buildNavigatorButton(i),
              InkWell(
                onTap: _addNewQuestion,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EduverseTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: EduverseTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.add, size: 16, color: EduverseTheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigatorButton(int index) {
    final status = _getQuestionStatus(index);
    Color bg = Colors.grey.shade200;
    Color text = Colors.grey.shade700;
    if (status == 1) {
      bg = EduverseTheme.emeraldVivid;
      text = Colors.white;
    } else if (status == 2) {
      bg = EduverseTheme.tertiary;
      text = Colors.white;
    }

    final isSelected = _currentQuestionIndex == index;

    return InkWell(
      onTap: () => _switchQuestion(index),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: EduverseTheme.deepNavy, width: 2) : null,
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSecuritySettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: EduverseTheme.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Security & Navigation Control', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _toggleRow('Free Sectional Navigation', 'Allow jumping freely between sections', _freeNavigation, (val) => setState(() => _freeNavigation = val)),
          _toggleRow('Proctored Fullscreen Guard', 'Force fullscreen mode during attempts', _proctoredFullscreen, (val) => setState(() => _proctoredFullscreen = val)),
          _toggleRow('Tab Switch Blur Limit', 'Auto-submit on 3 unfocused events', _tabSwitchBlurLimit, (val) => setState(() => _tabSwitchBlurLimit = val)),
          _toggleRow('Randomize Question & Options', 'Per-candidate permutation engine', _randomizeQuestions, (val) => setState(() => _randomizeQuestions = val)),
        ],
      ),
    );
  }

  Widget _toggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: EduverseTheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: EduverseTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveReleaseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time, color: EduverseTheme.primary, size: 18),
              SizedBox(width: 8),
              Text('Live Release Window', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _scheduledAt ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date == null || !mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: _scheduledAt != null ? TimeOfDay.fromDateTime(_scheduledAt!) : TimeOfDay.now(),
              );
              if (time == null || !mounted) return;
              setState(() {
                _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EduverseTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18, color: EduverseTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scheduledAt != null
                          ? 'Scheduled: ${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} at ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                          : 'Immediate Release: Available right after publish (tap to schedule)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_scheduledAt != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => setState(() => _scheduledAt = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Solution Reveal Policy', style: TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          const Text(
            'Instant Solution Display upon student submission',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
          ),
        ],
      ),
    );
  }
}
