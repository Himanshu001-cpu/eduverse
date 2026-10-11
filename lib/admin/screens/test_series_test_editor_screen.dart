import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/admin/models/admin_models.dart';
import 'package:eduverse/admin/models/test_quiz_models.dart' show TestSection;
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import 'package:eduverse/admin/services/test_series_service.dart';
import 'package:eduverse/admin/widgets/admin_scaffold.dart';
import 'package:eduverse/admin/widgets/quiz_library_dialog.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/test_paper_header.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/test_stats_strip.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/section_tabs.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/question_editor_card.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/question_palette_rail.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/test_settings_drawer.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

/// Test Paper & Sectional Quiz Editor Screen matching the Stitch Eduverse Design System.
/// Supports test-level sections, single-question detailed authoring, draggable palette,
/// question validation states, distractor rationale, and option shuffling.
class TestSeriesTestEditorScreen extends StatefulWidget {
  final String testSeriesId;
  final String? testId;
  final int order;
  final Map<String, dynamic>? initialData;

  const TestSeriesTestEditorScreen({
    super.key,
    required this.testSeriesId,
    this.testId,
    this.order = 0,
    this.initialData,
  });

  @override
  State<TestSeriesTestEditorScreen> createState() =>
      _TestSeriesTestEditorScreenState();
}

class _TestSeriesTestEditorScreenState
    extends State<TestSeriesTestEditorScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  DateTime? _lastSavedAt;
  Map<String, dynamic>? _lastSavedSnapshot;
  String? _currentTestId;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;
  late TextEditingController _marksPerQuestionController;
  late TextEditingController _negativeMarkingController;
  Duration _timeLimit = Duration.zero;

  List<QuizQuestion> _questions = [];
  List<TestSection> _sections = [];
  String? _activeSectionId; // null = all sections
  int _currentIndex = 0;

  List<String> _subjects = [];
  String _testCategory = 'Full Length';
  String _testSubject = '';
  bool _saveToLibrary = false;
  bool _shuffleOptions = false;
  DateTime? _scheduledAt;

  static const List<String> _testCategories = [
    'General',
    'Prelims',
    'Mains',
    'Topic Wise',
    'Full Length',
    'Sectional',
    'Previous Year',
  ];

  bool get _isEditing => _currentTestId != null;

  @override
  void initState() {
    super.initState();
    _currentTestId = widget.testId;
    _populateFromData(widget.initialData);

    _loadSubjects();
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _autoSave(),
    );

    // If new test with empty title, open settings automatically after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isEditing && _titleController.text.trim().isEmpty) {
        _openSettings();
      }
    });
  }

  void _populateFromData(Map<String, dynamic>? data) {
    _titleController = TextEditingController(text: data?['title'] ?? '');
    _descriptionController = TextEditingController(
      text: data?['description'] ?? '',
    );
    _instructionsController = TextEditingController(
      text: data?['instructions'] ?? '',
    );
    _marksPerQuestionController = TextEditingController(
      text: data?['marksPerQuestion']?.toString() ?? '2.0',
    );
    _negativeMarkingController = TextEditingController(
      text: data?['negativeMarking']?.toString() ?? '0.66',
    );
    _testCategory = data?['category'] as String? ?? 'Full Length';
    _testSubject = data?['subject'] as String? ?? '';
    _shuffleOptions = data?['shuffleOptions'] as bool? ?? false;

    if (data?['scheduledAt'] != null) {
      if (data!['scheduledAt'] is Timestamp) {
        _scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
      } else if (data['scheduledAt'] is DateTime) {
        _scheduledAt = data['scheduledAt'] as DateTime;
      }
    }

    if (data?['timeLimitSeconds'] != null && data!['timeLimitSeconds'] > 0) {
      _timeLimit = Duration(seconds: data['timeLimitSeconds']);
    } else if (data?['durationMinutes'] != null &&
        data!['durationMinutes'] > 0) {
      _timeLimit = Duration(minutes: data['durationMinutes']);
    }

    if (data?['sections'] != null) {
      final rawSecs = data!['sections'] as List<dynamic>;
      _sections = rawSecs
          .map((s) => TestSection.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    }

    if (data?['questions'] != null) {
      final rawQs = data!['questions'] as List<dynamic>;
      _questions = rawQs.map((q) {
        final map = q as Map<String, dynamic>;
        return QuizQuestion.fromJson(map);
      }).toList();
    }

    if (_questions.isEmpty) {
      _questions.add(_createDefaultQuestion());
    }

    _lastSavedSnapshot = _buildTestData();
    _lastSavedAt = DateTime.now();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _marksPerQuestionController.dispose();
    _negativeMarkingController.dispose();
    super.dispose();
  }

  QuizQuestion _createDefaultQuestion([String? sectionId]) {
    final defaultScore = int.tryParse(_marksPerQuestionController.text.split('.').first) ?? 2;
    return QuizQuestion(
      id: const Uuid().v4(),
      questionText: '',
      answerType: AnswerType.multipleChoice,
      sectionId: sectionId ?? _activeSectionId,
      score: defaultScore,
      options: [
        AnswerOption(id: const Uuid().v4(), text: '', isCorrect: true),
        AnswerOption(id: const Uuid().v4(), text: ''),
        AnswerOption(id: const Uuid().v4(), text: ''),
        AnswerOption(id: const Uuid().v4(), text: ''),
      ],
    );
  }

  Future<void> _loadSubjects() async {
    try {
      final adminService = Provider.of<FirebaseAdminService>(
        context,
        listen: false,
      );
      adminService.getSubjects().listen((subjects) {
        if (mounted) {
          setState(() => _subjects = subjects);
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
      if (mounted) {
        setState(() {
          if (!_subjects.contains(name)) _subjects.add(name);
          _testSubject = name;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding subject: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _promptNewSubject() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Subject Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isNotEmpty ? text : null);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      await _addNewSubject(result);
    }
  }

  Map<String, dynamic> _buildTestData() {
    final timeLimitSeconds = _timeLimit.inSeconds > 0 ? _timeLimit.inSeconds : null;
    final durationMinutes = _timeLimit.inMinutes > 0 ? _timeLimit.inMinutes : null;
    final marksPerQuestion = double.tryParse(_marksPerQuestionController.text);
    final negativeMarking = double.tryParse(_negativeMarkingController.text);

    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'instructions': _instructionsController.text.trim(),
      'category': _testCategory,
      'subject': _testSubject,
      'timeLimitSeconds': timeLimitSeconds,
      'durationMinutes': durationMinutes,
      'marksPerQuestion': marksPerQuestion,
      'negativeMarking': negativeMarking,
      'shuffleOptions': _shuffleOptions,
      'sections': _sections.map((s) => s.toJson()).toList(),
      'questions': _questions.map((q) => q.toJson()).toList(),
      'totalQuestions': _questions.length,
      'order': widget.order,
      'scheduledAt': _scheduledAt != null ? Timestamp.fromDate(_scheduledAt!) : null,
    };
  }

  Future<bool> _persist({required bool silent, bool closeAfter = false}) async {
    if (_titleController.text.trim().isEmpty) {
      if (!silent) {
        _openSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify a title for this test paper.')),
        );
      }
      return false;
    }

    if (_questions.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one question.')),
        );
      }
      return false;
    }

    if (silent) {
      setState(() => _isAutoSaving = true);
    }

    try {
      final testData = _buildTestData();
      testData['updatedAt'] = FieldValue.serverTimestamp();

      final ref = FirebaseFirestore.instance
          .collection('test_series')
          .doc(widget.testSeriesId)
          .collection('tests');

      if (_isEditing) {
        await ref.doc(_currentTestId).update(testData);
      } else {
        testData['createdAt'] = FieldValue.serverTimestamp();
        final newDoc = await ref.add(testData);
        _currentTestId = newDoc.id;
      }

      await TestSeriesService().updateTestCount(widget.testSeriesId);

      if (_saveToLibrary && mounted) {
        final adminService = Provider.of<FirebaseAdminService>(context, listen: false);
        final poolQuiz = AdminQuiz(
          id: _currentTestId ?? const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          instructions: _instructionsController.text.trim(),
          timeLimitMinutes: _timeLimit.inMinutes > 0 ? _timeLimit.inMinutes : null,
          timeLimitSeconds: _timeLimit.inSeconds > 0 ? _timeLimit.inSeconds : null,
          marksPerQuestion: double.tryParse(_marksPerQuestionController.text),
          negativeMarking: double.tryParse(_negativeMarkingController.text),
          questions: _questions,
          createdAt: DateTime.now(),
          scheduledAt: _scheduledAt,
        );
        await adminService.saveToQuizPool(poolQuiz);
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _lastSavedAt = DateTime.now();
          _lastSavedSnapshot = _buildTestData();
        });

        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test paper saved successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (closeAfter) {
          Navigator.pop(context);
        }
      }
      return true;
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving test: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
      }
    }
  }

  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges || _isAutoSaving || !mounted) return;
    await _persist(silent: true);
  }

  void _discardChanges() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Unsaved Changes?'),
        content: const Text(
          'Any changes made since the last save will be discarded. Do you wish to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduverseColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (_lastSavedSnapshot != null) {
        setState(() {
          _populateFromData(_lastSavedSnapshot);
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restored last saved state.')),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _openSettings() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // --- Questions management ---

  List<int> get _visibleIndices {
    if (_activeSectionId == null) {
      return List<int>.generate(_questions.length, (i) => i);
    }
    final list = <int>[];
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i].sectionId == _activeSectionId) {
        list.add(i);
      }
    }
    return list;
  }

  void _addQuestion() {
    setState(() {
      _hasUnsavedChanges = true;
      _questions.add(_createDefaultQuestion(_activeSectionId));
      _currentIndex = _questions.length - 1;
    });
  }

  Future<void> _addMultipleQuestions() async {
    final controller = TextEditingController(text: '5');
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Multiple Questions'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of questions',
            hintText: 'e.g. 5',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, (n != null && n > 0) ? n : null);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (count == null || count <= 0) return;

    setState(() {
      _hasUnsavedChanges = true;
      for (int i = 0; i < count; i++) {
        _questions.add(_createDefaultQuestion(_activeSectionId));
      }
      _currentIndex = _questions.length - 1;
    });
  }

  void _duplicateQuestion(int index) {
    final source = _questions[index];
    final cloned = source.copyWith(
      id: const Uuid().v4(),
      options: source.options.map((o) => o.copyWith(id: const Uuid().v4())).toList(),
    );

    setState(() {
      _hasUnsavedChanges = true;
      _questions.insert(index + 1, cloned);
      _currentIndex = index + 1;
    });
  }

  Future<void> _deleteQuestion(int index) async {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test must have at least one question.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Question ${index + 1}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduverseColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _hasUnsavedChanges = true;
        _questions.removeAt(index);
        if (_currentIndex >= _questions.length) {
          _currentIndex = _questions.length - 1;
        }
      });
    }
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      _hasUnsavedChanges = true;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
      if (_currentIndex == oldIndex) {
        _currentIndex = newIndex;
      } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
        _currentIndex--;
      } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
        _currentIndex++;
      }
    });
  }

  Future<void> _importFromLibrary() async {
    final adminService = Provider.of<FirebaseAdminService>(context, listen: false);
    final selected = await showDialog<AdminQuiz>(
      context: context,
      builder: (_) => QuizLibraryDialog(adminService: adminService),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _hasUnsavedChanges = true;
      _questions.addAll(selected.questions.map((q) => q.copyWith(id: const Uuid().v4())));
      _currentIndex = _questions.length - 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported ${selected.questions.length} questions from "${selected.title}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Section management ---

  Future<void> _promptAddSection() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Section Name',
            hintText: 'e.g. Section A: Macro & Budget',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create Section'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final newSec = TestSection(id: const Uuid().v4(), name: name);
    setState(() {
      _hasUnsavedChanges = true;
      _sections.add(newSec);
      _activeSectionId = newSec.id;
    });
  }

  Future<void> _promptRenameSection(TestSection sec) async {
    final controller = TextEditingController(text: sec.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Section Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    setState(() {
      _hasUnsavedChanges = true;
      final idx = _sections.indexWhere((s) => s.id == sec.id);
      if (idx >= 0) {
        _sections[idx] = sec.copyWith(name: name);
      }
    });
  }

  Future<void> _deleteSection(TestSection sec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${sec.name}"?'),
        content: const Text(
          'Questions currently assigned to this section will remain in the test and become unassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduverseColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Section'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _hasUnsavedChanges = true;
        _sections.removeWhere((s) => s.id == sec.id);
        if (_activeSectionId == sec.id) {
          _activeSectionId = null;
        }
        for (int i = 0; i < _questions.length; i++) {
          if (_questions[i].sectionId == sec.id) {
            _questions[i] = _questions[i].copyWith(clearSectionId: true);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQIndex = _currentIndex.clamp(0, (_questions.length - 1).clamp(0, 99999));
    final currentQuestion = _questions.isNotEmpty
        ? _questions[currentQIndex]
        : _createDefaultQuestion();

    final marksVal = double.tryParse(_marksPerQuestionController.text) ?? 2.0;
    final negVal = double.tryParse(_negativeMarkingController.text) ?? 0.66;
    final totalMarks = _questions.fold<double>(
      0.0,
      (acc, q) => acc + (q.score > 0 ? q.score.toDouble() : marksVal),
    );

    final counts = <String?, int>{null: _questions.length};
    for (final sec in _sections) {
      counts[sec.id] = _questions.where((q) => q.sectionId == sec.id).length;
    }

    final visibleIndices = _visibleIndices;
    final visiblePos = visibleIndices.indexOf(currentQIndex);
    final hasPrev = visiblePos > 0;
    final isLastInVisible = visiblePos == visibleIndices.length - 1 || visibleIndices.isEmpty;

    final autosaveFormatted = _lastSavedAt != null
        ? 'Autosaved at ${DateFormat('hh:mm a').format(_lastSavedAt!)}'
        : null;

    final bodyWidget = Scaffold(
      key: _scaffoldKey,
      backgroundColor: EduverseColors.surface,
      endDrawer: TestSettingsDrawer(
        titleController: _titleController,
        descriptionController: _descriptionController,
        instructionsController: _instructionsController,
        marksPerQuestionController: _marksPerQuestionController,
        negativeMarkingController: _negativeMarkingController,
        testCategory: _testCategory,
        testSubject: _testSubject,
        categories: _testCategories,
        subjects: _subjects,
        timeLimit: _timeLimit,
        scheduledAt: _scheduledAt,
        saveToLibrary: _saveToLibrary,
        shuffleOptions: _shuffleOptions,
        onCategoryChanged: (cat) => setState(() {
          _testCategory = cat;
          _hasUnsavedChanges = true;
        }),
        onSubjectChanged: (sub) => setState(() {
          _testSubject = sub;
          _hasUnsavedChanges = true;
        }),
        onPromptNewSubject: _promptNewSubject,
        onDurationChanged: (dur) => setState(() {
          _timeLimit = dur;
          _hasUnsavedChanges = true;
        }),
        onScheduleChanged: (dt) => setState(() {
          _scheduledAt = dt;
          _hasUnsavedChanges = true;
        }),
        onSaveToLibraryChanged: (v) => setState(() {
          _saveToLibrary = v;
          _hasUnsavedChanges = true;
        }),
        onShuffleOptionsChanged: (v) => setState(() {
          _shuffleOptions = v;
          _hasUnsavedChanges = true;
        }),
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() => _hasUnsavedChanges = true),
        child: Column(
          children: [
            // Top Stitch Header
            TestPaperHeader(
              title: _titleController.text,
              category: _testCategory,
              testCode: _currentTestId != null
                  ? (_currentTestId!.length > 8 ? _currentTestId!.substring(0, 8) : _currentTestId)
                  : null,
              autosaveText: autosaveFormatted,
              isAutoSaving: _isAutoSaving,
              hasUnsavedChanges: _hasUnsavedChanges,
              onOpenSettings: _openSettings,
              onDiscard: _discardChanges,
              onSave: () => _persist(silent: false),
              onSaveAndClose: () => _persist(silent: false, closeAfter: true),
            ),

            // 5-Card Stats Strip
            TestStatsStrip(
              totalQuestions: _questions.length,
              totalMarks: totalMarks,
              marksPerQuestion: marksVal,
              negativeMarks: negVal,
              timeLimit: _timeLimit,
              sectionsCount: _sections.length,
              scheduledAt: _scheduledAt,
              onTapCard: _openSettings,
            ),

            // Section Tabs Filter
            SectionTabs(
              sections: _sections,
              activeSectionId: _activeSectionId,
              questionCounts: counts,
              onSelectSection: (id) => setState(() {
                _activeSectionId = id;
                final visible = _visibleIndices;
                if (!visible.contains(_currentIndex) && visible.isNotEmpty) {
                  _currentIndex = visible.first;
                }
              }),
              onAddSection: _promptAddSection,
              onRenameSection: _promptRenameSection,
              onDeleteSection: _deleteSection,
            ),
            const Divider(height: 1),

            // Main Editor & Question Matrix (Responsive layout)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1100;

                  final editorWidget = SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: QuestionEditorCard(
                      question: currentQuestion,
                      questionIndex: currentQIndex,
                      totalQuestions: _questions.length,
                      sections: _sections,
                      subjects: _subjects,
                      onUpdateQuestion: (updated) => setState(() {
                        _questions[currentQIndex] = updated;
                        _hasUnsavedChanges = true;
                      }),
                      onDuplicateQuestion: () => _duplicateQuestion(currentQIndex),
                      onDeleteQuestion: () => _deleteQuestion(currentQIndex),
                      onPreviousQuestion: hasPrev
                          ? () => setState(() => _currentIndex = visibleIndices[visiblePos - 1])
                          : null,
                      onNextOrAddQuestion: () {
                        if (isLastInVisible) {
                          _addQuestion();
                        } else {
                          setState(() => _currentIndex = visibleIndices[visiblePos + 1]);
                        }
                      },
                      isLastQuestion: isLastInVisible,
                      onPromptNewSubject: _promptNewSubject,
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: editorWidget),
                        QuestionPaletteRail(
                          questions: _questions,
                          currentIndex: currentQIndex,
                          onSelectQuestion: (i) => setState(() => _currentIndex = i),
                          onReorderQuestions: _reorderQuestions,
                          onAddQuestion: _addQuestion,
                          onAddMultiple: _addMultipleQuestions,
                          onImportFromLibrary: _importFromLibrary,
                        ),
                      ],
                    );
                  }

                  // Narrow screens: Editor with bottom floating sheet button
                  return Stack(
                    children: [
                      editorWidget,
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.extended(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (ctx) => SizedBox(
                                height: MediaQuery.of(ctx).size.height * 0.75,
                                child: QuestionPaletteRail(
                                  questions: _questions,
                                  currentIndex: currentQIndex,
                                  onSelectQuestion: (i) {
                                    Navigator.pop(ctx);
                                    setState(() => _currentIndex = i);
                                  },
                                  onReorderQuestions: _reorderQuestions,
                                  onAddQuestion: () {
                                    Navigator.pop(ctx);
                                    _addQuestion();
                                  },
                                  onAddMultiple: () {
                                    Navigator.pop(ctx);
                                    _addMultipleQuestions();
                                  },
                                  onImportFromLibrary: () {
                                    Navigator.pop(ctx);
                                    _importFromLibrary();
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.grid_view_rounded),
                          label: Text('${_questions.length} Qs Matrix'),
                          backgroundColor: EduverseColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    return AdminScaffold(
      title: 'Test Paper Studio',
      body: bodyWidget,
    );
  }
}
