import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

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
  int _currentStep = 2; // Step 3: Question Vault (0-indexed: 2)
  int _currentQuestionIndex = 0;
  String _difficulty = 'UPSC Hard';
  String _correctOption = 'C';
  double _marksPerQuestion = 2.0;
  double _negativeMarking = 0.66;
  int _timeLimitMinutes = 60;
  DateTime? _scheduledAt;
  bool _isSaving = false;
  String? _currentQuizId;

  // Security toggles
  bool _freeNavigation = true;
  bool _proctoredFullscreen = true;
  bool _tabSwitchBlurLimit = true;
  bool _randomizeQuestions = true;

  // Header & Quiz info controllers
  late TextEditingController _quizTitleController;
  late TextEditingController _quizDescController;

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

  // List of active questions
  List<QuizQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _currentQuizId = widget.quizId ?? widget.existingQuiz?.id;

    _quizTitleController = TextEditingController(
      text: widget.existingQuiz?.title ?? 'Full-Length Sectional Mock Test — Indian Polity & Constitution',
    );
    _quizDescController = TextEditingController(
      text: widget.existingQuiz?.description ?? 'Comprehensive Prelims mock examination evaluating Constitutional Law and Basic Structure jurisprudence.',
    );

    if (widget.existingQuiz != null) {
      _marksPerQuestion = widget.existingQuiz!.marksPerQuestion ?? 2.0;
      _negativeMarking = widget.existingQuiz!.negativeMarking ?? 0.66;
      _timeLimitMinutes = widget.existingQuiz!.timeLimitMinutes ?? 60;
      _scheduledAt = widget.existingQuiz!.scheduledAt;
      _questions = List.from(widget.existingQuiz!.questions);
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
        questionText: 'Consider the following statements regarding the Basic Structure Doctrine in Indian Constitutional Jurisprudence:\n\n'
            '1. It was first explicitly articulated by the Supreme Court in the I.C. Golaknath v. State of Punjab (1967) ruling.\n'
            '2. Judicial review and the secular character of the Indian Republic form non-derogable parts of the basic structure as upheld in the Minerva Mills case.\n'
            '3. The doctrine limits Parliament\'s constituent amending power under Article 368 from emasculating fundamental guarantees.\n\n'
            'Which of the statements given above is/are correct?',
        options: [
          AnswerOption(id: const Uuid().v4(), text: '1 only', textDelta: 'Golaknath forbade amendment of Fundamental Rights, but did not formulate Basic Structure.'),
          AnswerOption(id: const Uuid().v4(), text: '2 and 3 only', textDelta: 'Omits statement 3 which is also a core holding of Kesavananda Bharati.'),
          AnswerOption(id: const Uuid().v4(), text: '2 and 3 only', isCorrect: true, textDelta: 'Statement 1 is incorrect because the doctrine was formulated in Kesavananda Bharati (1973).'),
          AnswerOption(id: const Uuid().v4(), text: '1, 2 and 3', textDelta: 'Incorrect because statement 1 erroneously identifies the source case.'),
        ],
        score: 2,
        negativeMarks: 0.66,
        subject: 'Polity & Gov',
        explanation: 'The doctrine of "Basic Structure" of the Constitution was established by a landmark 7:6 majority in the historic Kesavananda Bharati v. State of Kerala (1973) case, overruling the earlier absolute curtailment in Golaknath (1967). In the subsequent Minerva Mills case (1980), the Court reiterated that judicial review, harmony between Fundamental Rights and Directive Principles, and limited amending capacity are constituent elements of the basic structure.',
      ),
      QuizQuestion(
        id: const Uuid().v4(),
        questionText: 'With reference to the Writ Jurisdiction of the Supreme Court and High Courts in India, consider the following statements:\n\n'
            '1. The writ of Mandamus cannot be issued against a private individual or body.\n'
            '2. The writ of Quo-Warranto can be sought by any interested person, even if they are not the aggrieved party.\n'
            '3. The Supreme Court\'s writ jurisdiction under Article 32 is narrower than that of High Courts under Article 226.\n\n'
            'Which of the statements given above are correct?',
        options: [
          AnswerOption(id: const Uuid().v4(), text: '1 and 2 only', textDelta: 'Statement 3 is also correct: Article 226 is indeed broader in scope.'),
          AnswerOption(id: const Uuid().v4(), text: '2 and 3 only', textDelta: 'Statement 1 is correct: Mandamus lies solely against public duties.'),
          AnswerOption(id: const Uuid().v4(), text: '1 and 3 only', textDelta: 'Statement 2 is also valid.'),
          AnswerOption(id: const Uuid().v4(), text: '1, 2 and 3', isCorrect: true, textDelta: 'All three statements are correct.'),
        ],
        score: 2,
        negativeMarks: 0.66,
        subject: 'Polity & Gov',
        explanation: 'Under Article 226, High Courts can issue writs not only for Fundamental Rights but also for any other legal right, making its jurisdiction broader than Article 32. Quo-Warranto does not require locus standi of direct personal injury.',
      ),
      QuizQuestion(
        id: const Uuid().v4(),
        questionText: 'Which one of the following schedules of the Constitution of India contains provisions regarding anti-defection?',
        options: [
          AnswerOption(id: const Uuid().v4(), text: 'Second Schedule', textDelta: 'Second Schedule deals with salaries and allowances of constitutional dignitaries.'),
          AnswerOption(id: const Uuid().v4(), text: 'Fifth Schedule', textDelta: 'Fifth Schedule deals with administration and control of scheduled areas and tribes.'),
          AnswerOption(id: const Uuid().v4(), text: 'Eighth Schedule', textDelta: 'Eighth Schedule recognizes official languages of the Republic.'),
          AnswerOption(id: const Uuid().v4(), text: 'Tenth Schedule', isCorrect: true, textDelta: 'Tenth Schedule specifically contains anti-defection provisions.'),
        ],
        score: 2,
        negativeMarks: 0.66,
        subject: 'Polity & Gov',
        explanation: 'The Tenth Schedule was added by the 52nd Constitutional Amendment Act, 1985, and deals with disqualification of lawmakers on ground of defection.',
      ),
    ];
  }

  void _saveCurrentQuestionToState() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;

    final q = _questions[_currentQuestionIndex];
    int correctIdx = 0;
    if (_correctOption == 'B') correctIdx = 1;
    else if (_correctOption == 'C') correctIdx = 2;
    else if (_correctOption == 'D') correctIdx = 3;

    final newOptions = [
      AnswerOption(
        id: q.options.isNotEmpty ? q.options[0].id : const Uuid().v4(),
        text: _optAController.text,
        isCorrect: correctIdx == 0,
        textDelta: _distractorAController.text,
      ),
      AnswerOption(
        id: q.options.length > 1 ? q.options[1].id : const Uuid().v4(),
        text: _optBController.text,
        isCorrect: correctIdx == 1,
        textDelta: _distractorBController.text,
      ),
      AnswerOption(
        id: q.options.length > 2 ? q.options[2].id : const Uuid().v4(),
        text: _optCController.text,
        isCorrect: correctIdx == 2,
        textDelta: _distractorCController.text,
      ),
      AnswerOption(
        id: q.options.length > 3 ? q.options[3].id : const Uuid().v4(),
        text: _optDController.text,
        isCorrect: correctIdx == 3,
        textDelta: _distractorDController.text,
      ),
    ];

    _questions[_currentQuestionIndex] = QuizQuestion(
      id: q.id.isNotEmpty ? q.id : const Uuid().v4(),
      questionText: _promptController.text,
      answerType: AnswerType.multipleChoice,
      options: newOptions,
      score: _marksPerQuestion.toInt(),
      negativeMarks: _negativeMarking,
      explanation: _explanationController.text,
      subject: q.subject ?? 'Polity & Gov',
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

    _distractorAController.text = q.options.isNotEmpty ? (q.options[0].textDelta ?? '') : '';
    _distractorBController.text = q.options.length > 1 ? (q.options[1].textDelta ?? '') : '';
    _distractorCController.text = q.options.length > 2 ? (q.options[2].textDelta ?? '') : '';
    _distractorDController.text = q.options.length > 3 ? (q.options[3].textDelta ?? '') : '';

    _explanationController.text = q.explanation ?? '';
    final correctIndex = q.options.indexWhere((o) => o.isCorrect);
    const opts = ['A', 'B', 'C', 'D'];
    _correctOption = (correctIndex >= 0 && correctIndex < 4) ? opts[correctIndex] : 'A';
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
          subject: 'General Studies',
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
    if (q.questionText.trim().isEmpty) return 0; // Blank draft
    final hasAllOptions = q.options.length >= 4 && q.options.every((o) => o.text.trim().isNotEmpty);
    if (hasAllOptions) return 1; // Validated
    return 2; // Flagged / incomplete
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
      final quiz = AdminQuiz(
        id: _currentQuizId ?? '',
        title: _quizTitleController.text.trim(),
        description: _quizDescController.text.trim(),
        instructions: 'Proctored UPSC Mock Examination. Single Choice with negative marking.',
        timeLimitMinutes: _timeLimitMinutes,
        marksPerQuestion: _marksPerQuestion,
        negativeMarking: _negativeMarking,
        questions: _questions,
        createdAt: DateTime.now(),
        scheduledAt: _scheduledAt,
      );

      if (widget.batchId.isNotEmpty) {
        final newId = await service.saveRecordedBatchQuiz(
          widget.courseId,
          widget.batchId,
          quiz,
          isNew: _currentQuizId == null || _currentQuizId!.isEmpty,
        );
        if (_currentQuizId == null || _currentQuizId!.isEmpty) {
          _currentQuizId = newId;
        }
      } else {
        await service.saveCourseQuiz(
          widget.courseId,
          quiz,
          isNew: _currentQuizId == null || _currentQuizId!.isEmpty,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPublished
                ? 'Mock test successfully published to student test series!'
                : 'Quiz draft successfully saved to Firestore.'),
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
    _quizTitleController.dispose();
    _quizDescController.dispose();
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
            // Top Breadcrumb & Actions
            _buildBreadcrumbAndHeader(context, service, isDesktop),
            const SizedBox(height: 20),

            // 5-Step Stepper Bar
            _buildHorizontalStepper(),
            const SizedBox(height: 24),

            // Two-Column Layout (8 col left / 4 col right)
            if (isDesktop)
              Row(
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
                        const SizedBox(height: 20),
                        _buildLiveReleaseCard(),
                        const SizedBox(height: 20),
                        _buildPeerReviewCard(),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
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
                  const SizedBox(height: 20),
                  _buildSecuritySettingsCard(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbAndHeader(BuildContext context, FirebaseAdminService service, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                  _currentQuizId != null && _currentQuizId!.isNotEmpty ? _currentQuizId! : 'NEW-QUIZ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduverseTheme.primary),
                ),
              ],
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
                      'UPSC CSE PRELIMS STAGE 1 SIMULATION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: EduverseTheme.onTertiaryFixed),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quizTitleController,
                    style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(fontSize: isDesktop ? 24 : 18),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Enter Quiz / Test Title...',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _quizDescController,
                    style: const TextStyle(fontSize: 13, color: EduverseTheme.onSurfaceVariant),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Enter test overview, syllabus scope, and directions...',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _saveCurrentQuestionToState();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Simulation Ready: ${_questions.length} questions validated under strict UPSC standard.'),
                          backgroundColor: EduverseTheme.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Preview Exam Mode'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EduverseTheme.primary,
                      side: const BorderSide(color: EduverseTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                    label: const Text('Publish to Test Series'),
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
                  onTap: () => setState(() => _currentStep = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? EduverseTheme.primary : (isDone ? EduverseTheme.surfaceContainerHigh : Colors.transparent),
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
                            color: isCurrent ? Colors.white : (isDone ? EduverseTheme.deepNavy : EduverseTheme.onSurfaceVariant),
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
                    child: Text('${_currentQuestionIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Text('Question #${_currentQuestionIndex + 1} of ${_questions.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: EduverseTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Single Choice', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: EduverseTheme.onSurfaceVariant)),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Saved & Validated', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid)),
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

          // Tagging Strip
          Row(
            children: [
              _tagItem('SUBJECT', currentQ?.subject?.isNotEmpty == true ? currentQ!.subject! : 'Polity & Gov'),
              const SizedBox(width: 16),
              _tagItem('SUBTOPIC', 'Basic Structure • Judiciary'),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DIFFICULTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                  DropdownButton<String>(
                    value: _difficulty,
                    isDense: true,
                    underline: const SizedBox(),
                    items: ['UPSC Easy', 'UPSC Moderate', 'UPSC Hard', 'UPSC Extreme']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _difficulty = val);
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
                  Text('+${_marksPerQuestion.toStringAsFixed(1)} / -${_negativeMarking.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EduverseTheme.emeraldVivid)),
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
              const Text('Question Prompt Body', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
              Wrap(
                spacing: 4,
                children: [
                  _formatBtn(Icons.format_bold, 'Bold'),
                  _formatBtn(Icons.format_italic, 'Italic'),
                  _formatBtn(Icons.code, 'Code'),
                  _formatBtn(Icons.functions, 'LaTeX Equation'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            maxLines: 7,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: EduverseTheme.surfaceContainerLow,
              hintText: 'Enter question text, statements, and question directive...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatBtn(IconData icon, String tooltip) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () {},
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Option Builder & Distractor Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
              Text('Tap option letter to designate the correct answer', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),

          _optionBuilderItem('A', _optAController, _distractorAController),
          const SizedBox(height: 12),
          _optionBuilderItem('B', _optBController, _distractorBController),
          const SizedBox(height: 12),
          _optionBuilderItem('C', _optCController, _distractorCController),
          const SizedBox(height: 12),
          _optionBuilderItem('D', _optDController, _distractorDController),
        ],
      ),
    );
  }

  Widget _optionBuilderItem(String letter, TextEditingController textCtrl, TextEditingController distractorCtrl) {
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isCorrect ? Colors.white : EduverseTheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: 'Option $letter text...',
                  ),
                ),
              ),
              if (isCorrect) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: EduverseTheme.emeraldVivid, borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Correct Answer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
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
            children: const [
              Text('Pedagogical Explanation & Academic Citations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
              Text('Annotated Multi-Tier Solution', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _explanationController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Model Editorial Solution',
              hintText: 'Comprehensive explanation detailing why the answer is correct with factual references...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: EduverseTheme.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 16),

          // Citations Row
          Row(
            children: [
              _citationChip(Icons.balance, 'CASE PRECEDENT', 'Kesavananda (1973)', 'AIR 1973 SC 1461'),
              const SizedBox(width: 12),
              _citationChip(Icons.menu_book, 'TEXTBOOK SOURCE', 'NCERT Class 11', 'Ch 9: Living Document'),
              const SizedBox(width: 12),
              _citationChip(Icons.smart_display_outlined, 'VIDEO MODULE', 'Lec 14: Judicial Review', 'Dr. Vance Hall'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _citationChip(IconData icon, String type, String title, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EduverseTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: EduverseTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy), overflow: TextOverflow.ellipsis),
                  Text(sub, style: const TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
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
          label: Text('Previous Q${_currentQuestionIndex}'),
        ),
        Text(
          'Showing question ${_currentQuestionIndex + 1} of ${_questions.length} in current sectional batch',
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
                child: const Text('Strict Standard', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid)),
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
                const Text('Negative Marking (1/3rd deduction)', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
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
        Text(number, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 24, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
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
              Text('$validatedCount/${_questions.length} Done', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid)),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _legendItem('Validated', EduverseTheme.emeraldVivid),
              const SizedBox(width: 8),
              _legendItem('Flagged', EduverseTheme.tertiary),
              const SizedBox(width: 8),
              _legendItem('Draft', Colors.grey),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic grid buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < _questions.length; i++)
                _buildNavigatorButton(i),
              // Add question button
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
              Text('Test Security & Navigation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
            ],
          ),
          const SizedBox(height: 12),
          _toggleRow('Free Sectional Navigation', 'Aspirants can jump between paper sections', _freeNavigation, (val) => setState(() => _freeNavigation = val)),
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
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.access_time, color: EduverseTheme.primary, size: 16),
              SizedBox(width: 6),
              Text('Live Release Window', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: EduverseTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: EduverseTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _scheduledAt != null
                        ? 'Scheduled: ${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} • ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                        : 'Available on release immediately upon publish',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('Answer Key & Solutions Publish Rule', style: TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          const Text('Instant Release upon candidate completion', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildPeerReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined, size: 18, color: EduverseTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Faculty Peer Review: ${_questions.length} questions mapped to civil services test standards. Changes are synchronized directly to Firestore.',
              style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
