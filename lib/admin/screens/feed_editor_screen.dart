import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/admin/widgets/thumbnail_upload_widget.dart';
import 'package:eduverse/admin/widgets/admin_scaffold.dart';
import 'package:eduverse/admin/widgets/formatted_text_field.dart';
import 'package:uuid/uuid.dart';

class FeedEditorScreen extends StatefulWidget {
  final FeedItem? feedItem; // If null, creating new

  const FeedEditorScreen({super.key, this.feedItem});

  @override
  State<FeedEditorScreen> createState() => _FeedEditorScreenState();
}

class _FeedEditorScreenState extends State<FeedEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Predefined color options for consistency
  final Map<Color, String> _colorOptions = {
    Colors.blue: 'Blue',
    Colors.red: 'Red',
    Colors.green: 'Green',
    Colors.purple: 'Purple',
    Colors.orange: 'Orange',
    Colors.teal: 'Teal',
  };

  // Find the closest matching color from predefined options
  Color _getMatchingColor(Color color) {
    // Check for exact match first
    if (_colorOptions.containsKey(color)) {
      return color;
    }
    // Find closest match by color value
    for (final option in _colorOptions.keys) {
      if (option.toARGB32() == color.toARGB32()) {
        return option;
      }
    }
    // Default to blue if no match found
    return Colors.blue;
  }

  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  String? _currentFeedItemId;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;

  // Specific fields
  late TextEditingController _bodyController; // Articles

  // Video fields
  late TextEditingController _videoUrlController;
  late TextEditingController _thumbnailUrlController;
  late TextEditingController _durationController;
  late TextEditingController _keyPointsController; // Comma or newline separated

  // Job fields
  late TextEditingController _applyUrlController;
  late TextEditingController _organizationController;
  late TextEditingController _jobLocationController;
  late TextEditingController _salaryRangeController;
  late TextEditingController _eligibilityController;
  late TextEditingController _jobTypeController;
  late TextEditingController _vacanciesController;
  late TextEditingController _howToApplyController;
  late TextEditingController _selectionProcessController; // Newline separated

  DateTime? _jobStartDate;
  DateTime? _jobEndDate;
  DateTime? _jobExamDate;

  // Quiz questions
  List<String> _subjects = [];
  List<QuizQuestion> _quizQuestions = [];
  late TextEditingController _quizInstructionsController;
  late TextEditingController _quizMarksPerQuestionController;
  late TextEditingController _quizNegativeMarkingController;
  Duration _quizTimeLimit = Duration.zero;

  // Current Affairs fields
  late TextEditingController _contextController;
  late TextEditingController _whatController;
  late TextEditingController _whyController;
  late TextEditingController _relevanceController;

  // Answer Writing fields
  late TextEditingController _questionController;
  late TextEditingController _wordLimitController;
  late TextEditingController _timeLimitController;
  late TextEditingController _modelAnswerController;
  late TextEditingController _answerKeyPointsController;

  ContentType _selectedType = ContentType.articles;
  String _emoji = '📝';
  Color _selectedColor = Colors.blue;
  String _thumbnailUrl = '';
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentFeedItemId = widget.feedItem?.id;
    _initControllers();
    if (widget.feedItem != null) {
      _loadExistingItem();
    }
    _loadSubjects();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) => _autoSave());
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding subject: $e')));
      }
    }
  }

  void _initControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _categoryController = TextEditingController();
    _bodyController = TextEditingController();

    // Video controllers
    _videoUrlController = TextEditingController();
    _thumbnailUrlController = TextEditingController();
    _durationController = TextEditingController(text: '0');
    _keyPointsController = TextEditingController();

    // Job controllers
    _applyUrlController = TextEditingController();
    _organizationController = TextEditingController();
    _jobLocationController = TextEditingController(text: 'Remote/Hybrid');
    _salaryRangeController = TextEditingController();
    _eligibilityController = TextEditingController();
    _jobTypeController = TextEditingController(text: 'Full-time');
    _vacanciesController = TextEditingController();
    _howToApplyController = TextEditingController();
    _selectionProcessController = TextEditingController();

    // Current Affairs controllers
    _contextController = TextEditingController();
    _whatController = TextEditingController();
    _whyController = TextEditingController();
    _relevanceController = TextEditingController();

    // Answer Writing controllers
    _questionController = TextEditingController();
    _wordLimitController = TextEditingController(text: '250');
    _timeLimitController = TextEditingController(text: '7');
    _modelAnswerController = TextEditingController();
    _answerKeyPointsController = TextEditingController();

    // Quiz controllers
    _quizInstructionsController = TextEditingController();
    _quizMarksPerQuestionController = TextEditingController();
    _quizNegativeMarkingController = TextEditingController();
  }

  void _loadExistingItem() {
    final item = widget.feedItem!;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _categoryController.text = item.categoryLabel;
    _selectedType = item.type;
    _emoji = item.emoji;
    _selectedColor = item.color;
    _thumbnailUrl = item.thumbnailUrl;
    _isPublic = item.isPublic;

    // Load specific content
    if (item.articleContent != null) {
      _bodyController.text = item.articleContent!.body;
    }
    if (item.videoContent != null) {
      _videoUrlController.text = item.videoContent!.videoUrl;
      _thumbnailUrlController.text = item.videoContent!.thumbnailUrl ?? '';
      _durationController.text = item.videoContent!.durationMinutes.toString();
      _keyPointsController.text = item.videoContent!.keyPoints.join('\n');
    }
    if (item.jobContent != null) {
      _organizationController.text = item.jobContent!.organization;
      _applyUrlController.text = item.jobContent!.applyUrl ?? '';
      _jobLocationController.text = item.jobContent!.location;
      _salaryRangeController.text = item.jobContent!.salaryRange ?? '';
      _eligibilityController.text = item.jobContent!.eligibility ?? '';
      _jobTypeController.text = item.jobContent!.jobType ?? '';
      _vacanciesController.text = item.jobContent!.vacancies?.toString() ?? '';
      _howToApplyController.text = item.jobContent!.howToApply ?? '';
      _selectionProcessController.text = item.jobContent!.selectionProcess.join(
        '\n',
      );

      _jobStartDate = item.jobContent!.applicationStart;
      _jobEndDate = item.jobContent!.applicationEnd;
      _jobExamDate = item.jobContent!.examDate;
    }
    if (item.currentAffairsContent != null) {
      _contextController.text = item.currentAffairsContent!.context;
      _whatController.text = item.currentAffairsContent!.whatHappened;
      _whyController.text = item.currentAffairsContent!.whyItMatters;
      _relevanceController.text = item.currentAffairsContent!.examRelevance;
    }
    if (item.answerWritingContent != null) {
      _questionController.text = item.answerWritingContent!.question;
      _wordLimitController.text = item.answerWritingContent!.wordLimit
          .toString();
      _timeLimitController.text = item.answerWritingContent!.timeLimitMinutes
          .toString();
      _modelAnswerController.text =
          item.answerWritingContent!.modelAnswer ?? '';
      _answerKeyPointsController.text = item.answerWritingContent!.keyPoints
          .join('\n');
    }
    // Load quiz questions
    if (item.quizQuestions != null) {
      _quizQuestions = List.from(item.quizQuestions!);
    }
    // Load quiz settings
    if (item.quizInstructions != null) {
      _quizInstructionsController.text = item.quizInstructions!;
    }
    if (item.quizMarksPerQuestion != null) {
      _quizMarksPerQuestionController.text = item.quizMarksPerQuestion!
          .toString();
    }
    if (item.quizNegativeMarking != null) {
      _quizNegativeMarkingController.text = item.quizNegativeMarking!
          .toString();
    }
    if (item.quizTimeLimitSeconds != null && item.quizTimeLimitSeconds! > 0) {
      _quizTimeLimit = Duration(seconds: item.quizTimeLimitSeconds!);
    } else if (item.quizTimeLimitMinutes != null &&
        item.quizTimeLimitMinutes! > 0) {
      _quizTimeLimit = Duration(minutes: item.quizTimeLimitMinutes!);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _bodyController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    _durationController.dispose();
    _keyPointsController.dispose();
    _applyUrlController.dispose();
    _organizationController.dispose();
    _jobLocationController.dispose();
    _salaryRangeController.dispose();
    _eligibilityController.dispose();
    _jobTypeController.dispose();
    _vacanciesController.dispose();
    _howToApplyController.dispose();
    _selectionProcessController.dispose();

    // Current Affairs dispose
    _contextController.dispose();
    _whatController.dispose();
    _whyController.dispose();
    _relevanceController.dispose();

    // Answer Writing dispose
    _questionController.dispose();
    _wordLimitController.dispose();
    _timeLimitController.dispose();
    _modelAnswerController.dispose();
    _answerKeyPointsController.dispose();

    // Quiz dispose
    _quizInstructionsController.dispose();
    _quizMarksPerQuestionController.dispose();
    _quizNegativeMarkingController.dispose();

    super.dispose();
  }

  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges || _isAutoSaving || !mounted) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_formKey.currentState!.validate()) return;

    // Validate quiz has at least one question
    if (_selectedType == ContentType.quizzes && _quizQuestions.isEmpty) {
      return;
    }

    setState(() => _isAutoSaving = true);

    try {
      final id = _currentFeedItemId ?? const Uuid().v4();

      // Construct specific content based on type
      ArticleContent? articleContent;
      VideoContent? videoContent;
      JobContent? jobContent;
      CurrentAffairsContent? currentAffairsContent;
      AnswerWritingContent? answerWritingContent;

      if (_selectedType == ContentType.articles) {
        articleContent = ArticleContent(
          id: id,
          title: _titleController.text,
          body: _bodyController.text,
          publishedDate: DateTime.now(),
        );
      } else if (_selectedType == ContentType.videos) {
        // Parse key points from newline-separated text
        final keyPointsList = _keyPointsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        videoContent = VideoContent(
          id: id,
          title: _titleController.text,
          description: _descriptionController.text,
          videoUrl: _videoUrlController.text,
          thumbnailUrl: _thumbnailUrlController.text.isEmpty
              ? null
              : _thumbnailUrlController.text,
          durationMinutes: int.tryParse(_durationController.text) ?? 0,
          keyPoints: keyPointsList,
        );
      } else if (_selectedType == ContentType.jobs) {
        jobContent = JobContent(
          id: id,
          title: _titleController.text,
          organization: _organizationController.text,
          location: _jobLocationController.text,
          salaryRange: _salaryRangeController.text.isEmpty
              ? null
              : _salaryRangeController.text,
          applyUrl: _applyUrlController.text,
          detailsText: _descriptionController.text,
          applicationStart: _jobStartDate,
          applicationEnd: _jobEndDate,
          examDate: _jobExamDate,
          eligibility: _eligibilityController.text.isEmpty
              ? null
              : _eligibilityController.text,
          jobType: _jobTypeController.text.isEmpty
              ? null
              : _jobTypeController.text,
          vacancies: int.tryParse(_vacanciesController.text),
          howToApply: _howToApplyController.text.isEmpty
              ? null
              : _howToApplyController.text,
          selectionProcess: _selectionProcessController.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      } else if (_selectedType == ContentType.currentAffairs) {
        currentAffairsContent = CurrentAffairsContent(
          id: id,
          title: _titleController.text,
          eventDate:
              DateTime.now(), // Default to now, maybe add date picker later
          context: _contextController.text,
          whatHappened: _whatController.text,
          whyItMatters: _whyController.text,
          examRelevance: _relevanceController.text,
        );
      } else if (_selectedType == ContentType.answerWriting) {
        final keyPointsList = _answerKeyPointsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        answerWritingContent = AnswerWritingContent(
          id: id,
          question: _questionController.text,
          wordLimit: int.tryParse(_wordLimitController.text) ?? 250,
          timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 7,
          modelAnswer: _modelAnswerController.text.isEmpty
              ? null
              : _modelAnswerController.text,
          keyPoints: keyPointsList,
        );
      }

      final newItem = FeedItem(
        id: id,
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        categoryLabel: _categoryController.text.isEmpty
            ? _selectedType.name.toUpperCase()
            : _categoryController.text,
        emoji: _emoji,
        color: _selectedColor,
        thumbnailUrl: _thumbnailUrl,
        isPublic: _isPublic,
        articleContent: articleContent,
        videoContent: videoContent,
        jobContent: jobContent,
        currentAffairsContent: currentAffairsContent,
        answerWritingContent: answerWritingContent,
        quizQuestions: _selectedType == ContentType.quizzes
            ? _quizQuestions
            : null,
        quizInstructions:
            _selectedType == ContentType.quizzes &&
                _quizInstructionsController.text.isNotEmpty
            ? _quizInstructionsController.text
            : null,
        quizTimeLimitMinutes:
            _selectedType == ContentType.quizzes && _quizTimeLimit.inMinutes > 0
            ? _quizTimeLimit.inMinutes
            : null,
        quizTimeLimitSeconds:
            _selectedType == ContentType.quizzes && _quizTimeLimit.inSeconds > 0
            ? _quizTimeLimit.inSeconds
            : null,
        quizMarksPerQuestion: _selectedType == ContentType.quizzes
            ? double.tryParse(_quizMarksPerQuestionController.text)
            : null,
        quizNegativeMarking: _selectedType == ContentType.quizzes
            ? double.tryParse(_quizNegativeMarkingController.text)
            : null,
        createdAt:
            widget.feedItem?.createdAt, // Preserve original creation time
        updatedAt: DateTime.now(), // Always update to current time on save
      );

      await FeedRepository().addFeedItem(newItem);
      _currentFeedItemId = id;

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
      }
    } finally {
      if (mounted) setState(() => _isAutoSaving = false);
    }
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate quiz has at least one question
    if (_selectedType == ContentType.quizzes && _quizQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = _currentFeedItemId ?? const Uuid().v4();

      // Construct specific content based on type
      ArticleContent? articleContent;
      VideoContent? videoContent;
      JobContent? jobContent;
      CurrentAffairsContent? currentAffairsContent;
      AnswerWritingContent? answerWritingContent;

      if (_selectedType == ContentType.articles) {
        articleContent = ArticleContent(
          id: id,
          title: _titleController.text,
          body: _bodyController.text,
          publishedDate: DateTime.now(),
        );
      } else if (_selectedType == ContentType.videos) {
        // Parse key points from newline-separated text
        final keyPointsList = _keyPointsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        videoContent = VideoContent(
          id: id,
          title: _titleController.text,
          description: _descriptionController.text,
          videoUrl: _videoUrlController.text,
          thumbnailUrl: _thumbnailUrlController.text.isEmpty
              ? null
              : _thumbnailUrlController.text,
          durationMinutes: int.tryParse(_durationController.text) ?? 0,
          keyPoints: keyPointsList,
        );
      } else if (_selectedType == ContentType.jobs) {
        jobContent = JobContent(
          id: id,
          title: _titleController.text,
          organization: _organizationController.text,
          location: _jobLocationController.text,
          salaryRange: _salaryRangeController.text.isEmpty
              ? null
              : _salaryRangeController.text,
          applyUrl: _applyUrlController.text,
          detailsText: _descriptionController.text,
          applicationStart: _jobStartDate,
          applicationEnd: _jobEndDate,
          examDate: _jobExamDate,
          eligibility: _eligibilityController.text.isEmpty
              ? null
              : _eligibilityController.text,
          jobType: _jobTypeController.text.isEmpty
              ? null
              : _jobTypeController.text,
          vacancies: int.tryParse(_vacanciesController.text),
          howToApply: _howToApplyController.text.isEmpty
              ? null
              : _howToApplyController.text,
          selectionProcess: _selectionProcessController.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      } else if (_selectedType == ContentType.currentAffairs) {
        currentAffairsContent = CurrentAffairsContent(
          id: id,
          title: _titleController.text,
          eventDate:
              DateTime.now(), // Default to now, maybe add date picker later
          context: _contextController.text,
          whatHappened: _whatController.text,
          whyItMatters: _whyController.text,
          examRelevance: _relevanceController.text,
        );
      } else if (_selectedType == ContentType.answerWriting) {
        final keyPointsList = _answerKeyPointsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        answerWritingContent = AnswerWritingContent(
          id: id,
          question: _questionController.text,
          wordLimit: int.tryParse(_wordLimitController.text) ?? 250,
          timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 7,
          modelAnswer: _modelAnswerController.text.isEmpty
              ? null
              : _modelAnswerController.text,
          keyPoints: keyPointsList,
        );
      }

      final newItem = FeedItem(
        id: id,
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        categoryLabel: _categoryController.text.isEmpty
            ? _selectedType.name.toUpperCase()
            : _categoryController.text,
        emoji: _emoji,
        color: _selectedColor,
        thumbnailUrl: _thumbnailUrl,
        isPublic: _isPublic,
        articleContent: articleContent,
        videoContent: videoContent,
        jobContent: jobContent,
        currentAffairsContent: currentAffairsContent,
        answerWritingContent: answerWritingContent,
        quizQuestions: _selectedType == ContentType.quizzes
            ? _quizQuestions
            : null,
        quizInstructions:
            _selectedType == ContentType.quizzes &&
                _quizInstructionsController.text.isNotEmpty
            ? _quizInstructionsController.text
            : null,
        quizTimeLimitMinutes:
            _selectedType == ContentType.quizzes && _quizTimeLimit.inMinutes > 0
            ? _quizTimeLimit.inMinutes
            : null,
        quizTimeLimitSeconds:
            _selectedType == ContentType.quizzes && _quizTimeLimit.inSeconds > 0
            ? _quizTimeLimit.inSeconds
            : null,
        quizMarksPerQuestion: _selectedType == ContentType.quizzes
            ? double.tryParse(_quizMarksPerQuestionController.text)
            : null,
        quizNegativeMarking: _selectedType == ContentType.quizzes
            ? double.tryParse(_quizNegativeMarkingController.text)
            : null,
        createdAt:
            widget.feedItem?.createdAt, // Preserve original creation time
        updatedAt: DateTime.now(), // Always update to current time on save
      );

      await FeedRepository().addFeedItem(newItem);
      _currentFeedItemId = id;

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed Item Saved Successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Quiz question management
  void _addQuestion() {
    setState(() {
      _hasUnsavedChanges = true;
      _quizQuestions.add(
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
  }

  void _removeQuestion(int index) {
    setState(() {
      _hasUnsavedChanges = true;
      _quizQuestions.removeAt(index);
    });
  }

  void _updateQuestion(int index, QuizQuestion updated) {
    setState(() {
      _hasUnsavedChanges = true;
      _quizQuestions[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.feedItem == null ? 'Create Feed Item' : 'Edit Feed Item',
      actions: [
        if (_isAutoSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Text('Saving...',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              onChanged: () => setState(() => _hasUnsavedChanges = true),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralSection(),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Content Details (${_selectedType.name})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildTypeSpecificFields(),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.feedItem == null
                            ? 'Create Feed Item'
                            : 'Save Changes',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Publicly Visible'),
          value: _isPublic,
          onChanged: (val) => setState(() { _isPublic = val; _hasUnsavedChanges = true; }),
        ),
        DropdownButtonFormField<ContentType>(
          initialValue: _selectedType,
          decoration: const InputDecoration(labelText: 'Content Type'),
          items: ContentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.name.toUpperCase()),
            );
          }).toList(),
          onChanged: widget.feedItem == null
              ? (val) => setState(() { _selectedType = val!; _hasUnsavedChanges = true; })
              : null, // Lock type for editing to prevent schema mismatch
        ),
        const SizedBox(height: 16),

        // Thumbnail Upload Section
        const Text(
          'Thumbnail Image',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ThumbnailUploadWidget(
          currentUrl: _thumbnailUrl,
          storagePath: 'feed/thumbnails',
          onUploaded: (url) => setState(() { _thumbnailUrl = url; _hasUnsavedChanges = true; }),
          height: 150,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Short Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: _emoji,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _emoji = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Simple Color Picker (Dropdown for now)
        DropdownButtonFormField<Color>(
          initialValue: _getMatchingColor(_selectedColor),
          decoration: const InputDecoration(labelText: 'Color Theme'),
          isExpanded: true,
          items: _colorOptions.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: e.key,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(e.value),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() { _selectedColor = val!; _hasUnsavedChanges = true; }),
        ),
      ],
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case ContentType.articles:
        return FormattedTextField(
          controller: _bodyController,
          labelText: 'Article Body (Markdown supported)',
          hintText: 'Use **bold** and *italic* for emphasis',
          maxLines: 10,
          validator: (v) => v?.isEmpty == true ? 'Required for Articles' : null,
        );

      case ContentType.videos:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/video.mp4',
              ),
              validator: (v) =>
                  v?.isEmpty == true ? 'Required for Videos' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
                hintText: '45',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _keyPointsController,
              decoration: const InputDecoration(
                labelText: 'Key Points (one per line)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: 'Point 1\nPoint 2\nPoint 3',
              ),
              maxLines: 6,
            ),
          ],
        );

      case ContentType.jobs:
        return _buildJobFields();

      case ContentType.currentAffairs:
        return _buildCurrentAffairsFields();

      case ContentType.answerWriting:
        return _buildAnswerWritingFields();

      case ContentType.quizzes:
        return _buildQuizFields();

      default:
        return const Card(
          color: Colors.amber,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Editor for this content type is not yet fully implemented. Basic details will be saved.',
            ),
          ),
        );
    }
  }

  Widget _buildCurrentAffairsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _contextController,
          decoration: const InputDecoration(
            labelText: 'Context (e.g., National, International)',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormattedTextField(
          controller: _whatController,
          labelText: 'What Happened?',
          hintText: 'Use **bold** and *italic* for emphasis',
          maxLines: 4,
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormattedTextField(
          controller: _whyController,
          labelText: 'Why It Matters?',
          hintText: 'Use **bold** and *italic* for emphasis',
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        FormattedTextField(
          controller: _relevanceController,
          labelText: 'Exam Relevance',
          hintText: 'Use **bold** and *italic* for emphasis',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildAnswerWritingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _questionController,
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _wordLimitController,
                decoration: const InputDecoration(
                  labelText: 'Word Limit',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _timeLimitController,
                decoration: const InputDecoration(
                  labelText: 'Time Limit (mins)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _modelAnswerController,
          decoration: const InputDecoration(
            labelText: 'Model Answer (Markdown supported)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 8,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _answerKeyPointsController,
          decoration: const InputDecoration(
            labelText: 'Key Points / Hints (one per line)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'Key point 1\nKey point 2',
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildJobFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _organizationController,
          decoration: const InputDecoration(
            labelText: 'Organization',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _jobLocationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _jobTypeController,
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _vacanciesController,
                decoration: const InputDecoration(
                  labelText: 'Vacancies',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _salaryRangeController,
                decoration: const InputDecoration(
                  labelText: 'Salary Range',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Important Dates',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildDatePicker(
              'Start Date',
              _jobStartDate,
              (d) => setState(() => _jobStartDate = d),
            ),
            _buildDatePicker(
              'End Date',
              _jobEndDate,
              (d) => setState(() => _jobEndDate = d),
            ),
            _buildDatePicker(
              'Exam Date',
              _jobExamDate,
              (d) => setState(() => _jobExamDate = d),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _eligibilityController,
          decoration: const InputDecoration(
            labelText: 'Eligibility Criteria',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _selectionProcessController,
          decoration: const InputDecoration(
            labelText: 'Selection Process (one per line)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'Preliminary Exam\nMain Exam',
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _howToApplyController,
          decoration: const InputDecoration(
            labelText: 'How to Apply (Markdown)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _applyUrlController,
          decoration: const InputDecoration(
            labelText: 'Application URL',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    ValueChanged<DateTime> onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (date != null) onPicked(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  selectedDate != null
                      ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                      : 'Select Date',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quiz Instructions
        TextFormField(
          controller: _quizInstructionsController,
          decoration: const InputDecoration(
            labelText: 'Quiz Instructions',
            hintText: 'Enter instructions for students...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.info_outline),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),

        // Time Limit Picker
        Text('Time Limit', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildDurationPicker(),
        const SizedBox(height: 24),

        Text('Marking Settings', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quizMarksPerQuestionController,
                decoration: const InputDecoration(
                  labelText: 'Marks Per Question',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _quizNegativeMarkingController,
                decoration: const InputDecoration(
                  labelText: 'Negative Marking (Penalty)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'e.g., 0.25',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Add Question Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${_quizQuestions.length})',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.tonalIcon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Questions List
        if (_quizQuestions.isEmpty)
          Card(
            color: Colors.grey.shade100,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No questions yet. Click "Add Question" to start.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...List.generate(_quizQuestions.length, (index) {
            return _QuizQuestionCard(
              index: index,
              question: _quizQuestions[index],
              subjects: _subjects,
              onAddSubject: _addNewSubject,
              onUpdate: (q) => _updateQuestion(index, q),
              onDelete: () => _removeQuestion(index),
            );
          }),
      ],
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
              onPressed: () => setState(() => _quizTimeLimit = Duration.zero),
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

/// Simplified Quiz Question Card for inline editing
class _QuizQuestionCard extends StatefulWidget {
  final int index;
  final QuizQuestion question;
  final List<String> subjects;
  final Future<void> Function(String) onAddSubject;
  final ValueChanged<QuizQuestion> onUpdate;
  final VoidCallback onDelete;

  const _QuizQuestionCard({
    required this.index,
    required this.question,
    required this.subjects,
    required this.onAddSubject,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<_QuizQuestionCard> {
  late TextEditingController _questionController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.question.questionText,
    );
    _explanationController = TextEditingController(
      text: widget.question.explanation ?? '',
    );
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
    _explanationController.dispose();
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

  void _updateExplanation(String text) {
    widget.onUpdate(widget.question.copyWith(explanation: text));
  }

  void _updateSubject(String? subject) {
    widget.onUpdate(widget.question.copyWith(subject: subject));
  }

  Future<void> _showAddSubjectDialog() async {
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
      await widget.onAddSubject(result);
      _updateSubject(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Q${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Score: ', style: TextStyle(fontSize: 12)),
                SizedBox(
                  width: 50,
                  child: TextFormField(
                    initialValue: widget.question.score.toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => widget.onUpdate(
                      widget.question.copyWith(score: int.tryParse(v) ?? 1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Subject: ', style: TextStyle(fontSize: 12)),
                DropdownButton<String>(
                  value:
                      widget.question.subject != null &&
                          widget.subjects.contains(widget.question.subject)
                      ? widget.question.subject
                      : null,
                  hint: const Text('None', style: TextStyle(fontSize: 12)),
                  isDense: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None', style: TextStyle(fontSize: 12)),
                    ),
                    ...widget.subjects.map(
                      (sub) => DropdownMenuItem(
                        value: sub,
                        child: Text(sub, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const DropdownMenuItem<String>(
                      value: '__ADD_NEW__',
                      child: Text(
                        '+ Add New',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == '__ADD_NEW__') {
                      _showAddSubjectDialog();
                    } else {
                      _updateSubject(val);
                    }
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Question Text
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _updateQuestionText,
            ),
            const SizedBox(height: 12),

            // Answer Type Toggle
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<AnswerType>(
                segments: const [
                  ButtonSegment(
                    value: AnswerType.multipleChoice,
                    label: Text('MCQ'),
                  ),
                  ButtonSegment(
                    value: AnswerType.trueFalse,
                    label: Text('T/F'),
                  ),
                ],
                selected: {widget.question.answerType},
                onSelectionChanged: (s) => _updateAnswerType(s.first),
              ),
            ),
            const SizedBox(height: 12),

            // Answer Fields
            _buildAnswerFields(),
            const SizedBox(height: 12),

            // Explanation Field
            TextFormField(
              controller: _explanationController,
              decoration: const InputDecoration(
                labelText: 'Explanation (shown after answering)',
                hintText: 'Why is this the correct answer?',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              onChanged: _updateExplanation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerFields() {
    switch (widget.question.answerType) {
      case AnswerType.multipleChoice:
        return Column(
          children: List.generate(4, (index) {
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
        );

      case AnswerType.trueFalse:
        final correctAnswer = widget.question.correctBooleanAnswer ?? true;
        return Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('True'),
              selected: correctAnswer == true,
              onSelected: (_) => _setCorrectBoolean(true),
              selectedColor: Colors.green.shade200,
            ),
            ChoiceChip(
              label: const Text('False'),
              selected: correctAnswer == false,
              onSelected: (_) => _setCorrectBoolean(false),
              selectedColor: Colors.red.shade200,
            ),
          ],
        );

      case AnswerType.shortAnswer:
        // Fall through to multipleChoice if somehow selected
        return const SizedBox.shrink();
    }
  }
}
