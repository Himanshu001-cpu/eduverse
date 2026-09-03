import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/thumbnail_upload_widget.dart';
import '../utils/validators.dart';

class CourseEditorScreen extends StatefulWidget {
  final AdminCourse? course;
  const CourseEditorScreen({super.key, this.course});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _subtitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _emojiController;
  late TextEditingController _realPriceController;
  late TextEditingController _finalPriceController;
  late TextEditingController _seatsTotalController;
  late TextEditingController _seatsLeftController;
  DateTime? _startDate;
  DateTime? _endDate;

  String _visibility = 'draft';
  String _level = 'beginner';
  String _language = 'en';

  Color _gradientStart = Colors.blue;
  Color _gradientEnd = Colors.blueAccent;
  String _thumbnailUrl = '';
  bool _isCourseBatch = false;

  bool _isLoading = false;

  // For teacher assignment
  List<CourseTeacher> _assignedTeachers = [];
  List<AdminUser> _teachersList = [];
  StreamSubscription? _teachersSub;
  StreamSubscription? _courseDocSub;
  final TextEditingController _subjectEditorController = TextEditingController();
  String? _selectedTeacherUid;
  bool _isSavingTeacher = false;

  // For subject logos
  Map<String, String> _subjectLogos = {};
  final TextEditingController _newSubjectLogoNameController = TextEditingController();
  final Map<String, bool> _uploadingLogos = {};

  final List<String> _visibilityOptions = ['draft', 'published', 'archived'];
  final List<String> _levelOptions = ['beginner', 'intermediate', 'advanced'];
  final List<String> _languageOptions = ['en', 'hi', 'bn', 'ta', 'te', 'mr'];

  // Predefined color options for gradient
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    final course = widget.course;

    _titleController = TextEditingController(text: course?.title ?? '');
    _slugController = TextEditingController(text: course?.slug ?? '');
    _subtitleController = TextEditingController(text: course?.subtitle ?? '');
    _descriptionController = TextEditingController(
      text: course?.description ?? '',
    );
    _emojiController = TextEditingController(text: course?.emoji ?? '📚');
    _realPriceController = TextEditingController(
      text: course?.realPrice?.toString() ?? course?.priceDefault.toString() ?? '0',
    );
    _finalPriceController = TextEditingController(
      text: course?.finalPrice?.toString() ?? course?.priceDefault.toString() ?? '0',
    );
    _seatsTotalController = TextEditingController(
      text: course?.seatsTotal?.toString() ?? '',
    );
    _seatsLeftController = TextEditingController(
      text: course?.seatsLeft?.toString() ?? '',
    );
    _startDate = course?.startDate;
    _endDate = course?.endDate;

    _visibility = course?.visibility ?? 'draft';
    _level = course?.level ?? 'beginner';
    _language = course?.language ?? 'en';

    if (course != null && course.gradientColors.length >= 2) {
      _gradientStart = Color(course.gradientColors[0]);
      _gradientEnd = Color(course.gradientColors[1]);
    }

    _thumbnailUrl = course?.thumbnailUrl ?? '';
    _isCourseBatch = course?.isCourseBatch ?? false;
    _assignedTeachers = course?.teachers != null ? List.from(course!.teachers) : [];
    _selectedTestSeriesIds = course?.linkedTestSeries != null ? List.from(course!.linkedTestSeries) : [];
    _selectedEbookIds = course?.linkedEbooks != null ? List.from(course!.linkedEbooks) : [];
    _subjectLogos = course?.subjectLogos != null ? Map.from(course!.subjectLogos) : {};
    _loadTeachers();
    _loadTestSeriesAndEbooks();
    _listenToCourseDoc();
  }

  List<Map<String, dynamic>> _allTestSeries = [];
  List<Map<String, dynamic>> _allEbooks = [];
  List<String> _selectedTestSeriesIds = [];
  List<String> _selectedEbookIds = [];

  Future<void> _loadTestSeriesAndEbooks() async {
    try {
      final tsSnap = await FirebaseFirestore.instance.collection('test_series').get();
      final ebSnap = await FirebaseFirestore.instance.collection('ebooks').get();
      if (mounted) {
        setState(() {
          _allTestSeries = tsSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _allEbooks = ebSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading test series/ebooks for course editor: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _emojiController.dispose();
    _realPriceController.dispose();
    _finalPriceController.dispose();
    _seatsTotalController.dispose();
    _seatsLeftController.dispose();
    _subjectEditorController.dispose();
    _newSubjectLogoNameController.dispose();
    _teachersSub?.cancel();
    _courseDocSub?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newCourse = AdminCourse(
        id: widget.course?.id ?? '',
        title: _titleController.text.trim(),
        slug: _slugController.text.trim().isEmpty
            ? _titleController.text.trim().toLowerCase().replaceAll(' ', '-')
            : _slugController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _emojiController.text.trim().isEmpty
            ? '📚'
            : _emojiController.text.trim(),
        tags: [],
        language: _language,
        level: _level,
        thumbnailUrl: _thumbnailUrl,
        gradientColors: [_gradientStart.toARGB32(), _gradientEnd.toARGB32()],
        priceDefault: double.tryParse(_finalPriceController.text) ?? 0.0,
        realPrice: double.tryParse(_realPriceController.text) ?? 0.0,
        finalPrice: double.tryParse(_finalPriceController.text) ?? 0.0,
        seatsTotal: int.tryParse(_seatsTotalController.text),
        seatsLeft: int.tryParse(_seatsLeftController.text),
        startDate: _startDate,
        endDate: _endDate,
        visibility: _visibility,
        teachers: _assignedTeachers,
        createdAt: widget.course?.createdAt ?? DateTime.now(),
        isCourseBatch: _isCourseBatch,
        linkedTestSeries: _selectedTestSeriesIds,
        linkedEbooks: _selectedEbookIds,
        subjectLogos: _subjectLogos,
      );

      await context.read<FirebaseAdminService>().saveCourse(
        newCourse,
        isNew: widget.course == null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Course ${widget.course == null ? 'created' : 'updated'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.course == null ? 'New Course' : 'Edit Course',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Card
                    _buildPreviewCard(),
                    const SizedBox(height: 24),

                    // Basic Info Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course Title *',
                        hintText: 'e.g., UPSC Prelims 2025',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.required,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle *',
                        hintText: 'e.g., Complete preparation guide',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.required,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _slugController,
                      decoration: const InputDecoration(
                        labelText: 'Slug (URL-friendly ID)',
                        hintText: 'Auto-generated from title if empty',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Detailed course description...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // Appearance Section
                    _buildSectionHeader('Appearance'),
                    const SizedBox(height: 12),

                    // Thumbnail Upload
                    ThumbnailUploadWidget(
                      currentUrl: _thumbnailUrl,
                      storagePath: 'courses/thumbnails',
                      onUploaded: (url) => setState(() => _thumbnailUrl = url),
                    ),
                    const SizedBox(height: 20),

                    // Emoji field and quick picker
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Emoji Field
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _emojiController,
                            decoration: const InputDecoration(
                              labelText: 'Emoji *',
                              hintText: '📚',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        // Quick emoji picker
                        ...[
                          '📚',
                          '✍️',
                          '📊',
                          '⚖️',
                          '🏛️',
                          '🧮',
                          '🌍',
                          '💼',
                        ].map(
                          (e) => InkWell(
                            onTap: () {
                              _emojiController.text = e;
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gradient Colors
                    const Text(
                      'Gradient Colors',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Color',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              _buildColorPicker(
                                _gradientStart,
                                (c) => setState(() => _gradientStart = c),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Color',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              _buildColorPicker(
                                _gradientEnd,
                                (c) => setState(() => _gradientEnd = c),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pricing & Settings Section
                    _buildSectionHeader('Pricing & Settings'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _realPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Original/Real Price (₹) *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: Validators.required,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _finalPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Final/Discounted Price (₹) *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: Validators.required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _seatsTotalController,
                            decoration: const InputDecoration(
                              labelText: 'Total Seats (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _seatsLeftController,
                            decoration: const InputDecoration(
                              labelText: 'Seats Left (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              alignment: Alignment.centerLeft,
                            ),
                            label: Text(_startDate == null ? 'Start Date' : 'Starts: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 90)),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              alignment: Alignment.centerLeft,
                            ),
                            label: Text(_endDate == null ? 'End Date' : 'Ends: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _visibility,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Visibility *',
                              border: OutlineInputBorder(),
                            ),
                            items: _visibilityOptions
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          v == 'published'
                                              ? Icons.public
                                              : v == 'draft'
                                              ? Icons.edit
                                              : Icons.archive,
                                          size: 16,
                                          color: v == 'published'
                                              ? Colors.green
                                              : v == 'draft'
                                              ? Colors.orange
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            v.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _visibility = v!),
                          ),
                        ),
                      ],
                    ),
                           Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _level,
                            decoration: const InputDecoration(
                              labelText: 'Level',
                              border: OutlineInputBorder(),
                            ),
                            items: _levelOptions
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(
                                      l[0].toUpperCase() + l.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _level = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _language,
                            decoration: const InputDecoration(
                              labelText: 'Language',
                              border: OutlineInputBorder(),
                            ),
                            items: _languageOptions.map((l) {
                              final labels = {
                                'en': 'English',
                                'hi': 'Hindi',
                                'bn': 'Bengali',
                                'ta': 'Tamil',
                                'te': 'Telugu',
                                'mr': 'Marathi',
                              };
                              return DropdownMenuItem(
                                value: l,
                                child: Text(labels[l] ?? l),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _language = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SwitchListTile(
                      title: const Text(
                        'Online Course / Batch',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text('Turn on to list as Online. Turn off to list as Offline.'),
                      value: _isCourseBatch,
                      activeThumbColor: Colors.blue.shade700,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          _isCourseBatch = val;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Linked Test Series & E-books Section
                    _buildLinkedContentSection(),
                    const SizedBox(height: 32),

                    // Teachers & Subjects Section
                    _buildTeachersSection(),
                    const SizedBox(height: 32),

                    // Subject Logos Section
                    _buildSubjectLogosSection(),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.course == null
                            ? 'Create Course'
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _gradientStart.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: Thumbnail or Gradient
            _thumbnailUrl.isNotEmpty
                ? Image.network(
                    _thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildGradientPreview(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildGradientPreview(showLoader: true);
                    },
                  )
                : _buildGradientPreview(),
            // Dark overlay for text readability
            if (_thumbnailUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_thumbnailUrl.isEmpty)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _emojiController.text.isEmpty
                              ? '📚'
                              : _emojiController.text,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  if (_thumbnailUrl.isEmpty) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _titleController.text.isEmpty
                              ? 'Course Title'
                              : _titleController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitleController.text.isEmpty
                              ? 'Subtitle goes here'
                              : _subtitleController.text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPreview({bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: showLoader
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            )
          : null,
    );
  }

  Widget _buildColorPicker(Color selected, ValueChanged<Color> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colorOptions.map((color) {
        final isSelected = selected.toARGB32() == color.toARGB32();
        return InkWell(
          onTap: () => onChanged(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : Border.all(color: Colors.grey.shade300),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _loadTeachers() {
    final service = context.read<FirebaseAdminService>();
    _teachersSub = service.getTeachers().listen((list) {
      if (mounted) {
        setState(() => _teachersList = list);
      }
    });
  }

  void _listenToCourseDoc() {
    if (widget.course != null) {
      _courseDocSub = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course!.id)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final course = AdminCourse.fromMap(doc.data()!, doc.id);
          if (mounted) {
            setState(() {
              _assignedTeachers = course.teachers;
              _subjectLogos = course.subjectLogos;
            });
          }
        }
      });
    }
  }

  Widget _buildTeachersSection() {
    if (widget.course == null) {
      return const SizedBox.shrink(); // Don't show for new courses
    }

    final service = context.read<FirebaseAdminService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Teachers & Subjects'),
        const SizedBox(height: 12),
        Card(
          child: _assignedTeachers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No teachers assigned to this course yet.',
                    style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _assignedTeachers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final teacher = _assignedTeachers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: Colors.teal),
                      ),
                      title: Text(teacher.name),
                      subtitle: Text('Subject: ${teacher.subject}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Teacher'),
                              content: Text(
                                'Are you sure you want to remove ${teacher.name} from teaching ${teacher.subject}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await service.removeTeacherFromCourse(
                                widget.course!.id,
                                teacher.uid,
                                teacher.subject,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Teacher removed successfully')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error removing teacher: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        // Add Teacher Form
        Card(
          color: Colors.teal.withValues(alpha: 0.02),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.teal.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign a Teacher',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTeacherUid,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Teacher',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _teachersList.map((t) {
                    return DropdownMenuItem(
                      value: t.uid,
                      child: Text('${t.name} (${t.email})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedTeacherUid = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectEditorController,
                  decoration: const InputDecoration(
                    labelText: 'Subject (e.g. Mathematics)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedTeacherUid != null && !_isSavingTeacher
                        ? () async {
                            final subject = _subjectEditorController.text.trim();
                            if (subject.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a subject name'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            setState(() => _isSavingTeacher = true);
                            try {
                              final teacherUser = _teachersList.firstWhere(
                                (t) => t.uid == _selectedTeacherUid,
                              );
                              await service.assignTeacherToCourse(
                                widget.course!.id,
                                teacherUser.uid,
                                teacherUser.name,
                                subject,
                              );
                              _subjectEditorController.clear();
                              setState(() {
                                _selectedTeacherUid = null;
                                _isSavingTeacher = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Teacher assigned successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => _isSavingTeacher = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error assigning teacher: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Assign Teacher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Merge Test Series & E-books with Course'),
        const SizedBox(height: 4),
        Text(
          'Students who purchase this course will automatically receive access to the linked test series and e-books.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        // Linked Test Series
        Card(
          elevation: 0,
          color: Colors.purple.shade50.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.purple.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('📝', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Linked Test Series',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_allTestSeries.isEmpty)
                  const Text('No test series available to link.', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allTestSeries.map((ts) {
                      final id = ts['id'] as String;
                      final title = ts['title'] as String? ?? 'Test Series';
                      final isSelected = _selectedTestSeriesIds.contains(id);
                      return FilterChip(
                        label: Text(title),
                        selected: isSelected,
                        selectedColor: Colors.purple.shade100,
                        checkmarkColor: Colors.purple.shade800,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTestSeriesIds.add(id);
                            } else {
                              _selectedTestSeriesIds.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Linked E-books
        Card(
          elevation: 0,
          color: Colors.indigo.shade50.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.indigo.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('📚', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Linked E-books',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_allEbooks.isEmpty)
                  const Text('No e-books available to link.', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allEbooks.map((eb) {
                      final id = eb['id'] as String;
                      final title = eb['title'] as String? ?? 'E-book';
                      final isSelected = _selectedEbookIds.contains(id);
                      return FilterChip(
                        label: Text(title),
                        selected: isSelected,
                        selectedColor: Colors.indigo.shade100,
                        checkmarkColor: Colors.indigo.shade800,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEbookIds.add(id);
                            } else {
                              _selectedEbookIds.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectLogosSection() {
    if (widget.course == null) {
      return Card(
        color: Colors.amber.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please save the course first to manage subject logos.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final service = context.read<FirebaseAdminService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Subject Logos'),
        const SizedBox(height: 4),
        Text(
          'Upload custom logos for each subject in this course.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<String>>(
          stream: service.getSubjectsForCourse(widget.course!.id),
          builder: (context, snapshot) {
            final courseSubjects = snapshot.data ?? [];
            final allSubjectsSet = <String>{...courseSubjects, ..._subjectLogos.keys};
            final allSubjects = allSubjectsSet.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allSubjects.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No subjects added to this course yet. Add lectures/notes or add a subject below.',
                        style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allSubjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final subjectName = allSubjects[index];
                      final logoUrl = _subjectLogos[subjectName];
                      final isUploading = _uploadingLogos[subjectName] ?? false;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.indigo.shade100),
                                ),
                                child: isUploading
                                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                    : (logoUrl != null && logoUrl.isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              logoUrl,
                                              fit: BoxFit.cover,
                                              width: 50,
                                              height: 50,
                                              errorBuilder: (_, __, ___) => Image.asset('assets/icon.png', fit: BoxFit.cover),
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                                          ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subjectName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      logoUrl != null && logoUrl.isNotEmpty ? 'Logo uploaded' : 'No custom logo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: logoUrl != null && logoUrl.isNotEmpty ? Colors.green : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: isUploading ? null : () => _pickAndUploadSubjectLogo(subjectName),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: Text(logoUrl != null && logoUrl.isNotEmpty ? 'Change' : 'Upload'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.indigo,
                                ),
                              ),
                              if (logoUrl != null && logoUrl.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: 'Remove logo',
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          try {
                                            await service.removeCourseSubjectLogo(widget.course!.id, subjectName);
                                            setState(() {
                                              _subjectLogos.remove(subjectName);
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Removed logo for $subjectName')),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error removing logo: $e'), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSubjectLogoNameController,
                        decoration: const InputDecoration(
                          hintText: 'Add custom subject name (e.g. History)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final name = _newSubjectLogoNameController.text.trim();
                        if (name.isEmpty) return;
                        _newSubjectLogoNameController.clear();
                        _pickAndUploadSubjectLogo(name);
                      },
                      icon: const Icon(Icons.add_a_photo, size: 18),
                      label: const Text('Add Logo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickAndUploadSubjectLogo(String subjectName) async {
    if (widget.course == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read image file bytes'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final mimeType = lookupMimeType(file.name) ?? 'image/jpeg';
    final service = context.read<FirebaseAdminService>();

    setState(() {
      _uploadingLogos[subjectName] = true;
    });

    try {
      final logoUrl = await service.uploadSubjectLogo(
        widget.course!.id,
        subjectName,
        bytes,
        mimeType,
      );
      await service.updateCourseSubjectLogo(widget.course!.id, subjectName, logoUrl);

      if (mounted) {
        setState(() {
          _subjectLogos[subjectName] = logoUrl;
          _uploadingLogos[subjectName] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subject logo updated for $subjectName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingLogos[subjectName] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading subject logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
