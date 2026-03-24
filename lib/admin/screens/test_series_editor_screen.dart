import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/test_series_service.dart';
import '../services/firebase_admin_service.dart';
import '../models/test_series_models.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/thumbnail_upload_widget.dart';

class TestSeriesEditorScreen extends StatefulWidget {
  final AdminTestSeries? testSeries;

  const TestSeriesEditorScreen({super.key, this.testSeries});

  @override
  State<TestSeriesEditorScreen> createState() => _TestSeriesEditorScreenState();
}

class _TestSeriesEditorScreenState extends State<TestSeriesEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TestSeriesService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _emojiController;

  String _category = 'General';
  String _visibility = 'draft';
  String _selectedSubject = '';
  String _thumbnailUrl = '';
  List<String> _subjects = [];
  List<LinkedBatch> _linkedBatches = [];
  bool _isSaving = false;

  bool get _isEditing => widget.testSeries != null;

  static const List<String> _categories = [
    'General',
    'Prelims',
    'Mains',
    'Topic Wise',
    'Full Length',
    'Sectional',
    'Previous Year',
  ];

  @override
  void initState() {
    super.initState();
    final ts = widget.testSeries;
    _titleController = TextEditingController(text: ts?.title ?? '');
    _descriptionController = TextEditingController(text: ts?.description ?? '');
    _priceController = TextEditingController(text: ts?.price.toString() ?? '0');
    _durationController = TextEditingController(
      text: ts?.durationMinutes.toString() ?? '0',
    );
    _emojiController = TextEditingController(text: ts?.emoji ?? '📝');
    _selectedSubject = ts?.subject ?? '';
    _thumbnailUrl = ts?.thumbnailUrl ?? '';
    _category = ts?.category ?? 'General';
    _visibility = ts?.visibility ?? 'draft';
    _linkedBatches = List.from(ts?.linkedBatches ?? []);
    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _emojiController.dispose();
    super.dispose();
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
      if (mounted) {
        setState(() => _selectedSubject = name);
      }
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

  Future<void> _showAddSubjectDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter subject name',
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final ts = AdminTestSeries(
        id: widget.testSeries?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _selectedSubject,
        category: _category,
        emoji: _emojiController.text.trim(),
        thumbnailUrl: _thumbnailUrl,
        price: double.tryParse(_priceController.text) ?? 0,
        durationMinutes: int.tryParse(_durationController.text) ?? 0,
        visibility: _visibility,
        gradientColors:
            widget.testSeries?.gradientColors ?? [0xFF4CAF50, 0xFF2E7D32],
        totalTests: widget.testSeries?.totalTests ?? 0,
        linkedBatches: _linkedBatches,
        createdAt: widget.testSeries?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _service.updateTestSeries(ts);
      } else {
        await _service.createTestSeries(ts);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Test series updated!' : 'Test series created!',
            ),
          ),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showLinkBatchDialog() async {
    final firestore = FirebaseFirestore.instance;

    // Fetch all courses
    final coursesSnapshot = await firestore.collection('courses').get();
    final courses = coursesSnapshot.docs
        .map((doc) => AdminCourse.fromMap(doc.data(), doc.id))
        .toList();

    if (!mounted) return;

    String? selectedCourseId;
    String? selectedCourseName;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Link to Batch'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select Course
                  const Text(
                    'Select Course:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourseId,
                    isExpanded: true,
                    hint: const Text('Choose a course'),
                    items: courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCourseId = val;
                        selectedCourseName = courses
                            .firstWhere((c) => c.id == val)
                            .title;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Step 2: Select Batch (shown after course selection)
                  if (selectedCourseId != null) ...[
                    const Text(
                      'Select Batch:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('courses')
                          .doc(selectedCourseId)
                          .collection('batches')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final batches = snapshot.data!.docs;
                        if (batches.isEmpty) {
                          return const Text(
                            'No batches found',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return Column(
                          children: batches.map((batchDoc) {
                            final batchData =
                                batchDoc.data() as Map<String, dynamic>;
                            final batchName = batchData['name'] ?? 'Unnamed';
                            final isAlreadyLinked = _linkedBatches.any(
                              (lb) =>
                                  lb.courseId == selectedCourseId &&
                                  lb.batchId == batchDoc.id,
                            );

                            return ListTile(
                              title: Text(batchName),
                              trailing: isAlreadyLinked
                                  ? const Chip(
                                      label: Text(
                                        'Linked',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.green,
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        final linked = LinkedBatch(
                                          courseId: selectedCourseId!,
                                          batchId: batchDoc.id,
                                          courseName: selectedCourseName ?? '',
                                          batchName: batchName,
                                        );
                                        setState(() {
                                          _linkedBatches.add(linked);
                                        });
                                        setDialogState(() {});
                                      },
                                      child: const Text('Link'),
                                    ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _isEditing ? 'Edit Test Series' : 'New Test Series',
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
      ],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              ThumbnailUploadWidget(
                currentUrl: _thumbnailUrl.isNotEmpty ? _thumbnailUrl : null,
                storagePath: 'test_series/thumbnails',
                onUploaded: (url) {
                  setState(() => _thumbnailUrl = url);
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              controller: _emojiController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28),
                              decoration: const InputDecoration(
                                labelText: 'Emoji',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Exam Name *',
                                hintText: 'e.g., SSC CGL 2024',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v?.trim().isEmpty == true
                                  ? 'Exam name is required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSubject.isNotEmpty &&
                                      (_subjects.contains(_selectedSubject))
                                  ? _selectedSubject
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(),
                              ),
                              isExpanded: true,
                              hint: const Text('Select a subject'),
                              items: [
                                ..._subjects.map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                ),
                                const DropdownMenuItem(
                                  value: '__add_new__',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, size: 18),
                                      SizedBox(width: 8),
                                      Text('Add New Subject...'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == '__add_new__') {
                                  _showAddSubjectDialog();
                                } else if (val != null) {
                                  setState(() => _selectedSubject = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _category = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price (₹)',
                                border: OutlineInputBorder(),
                                hintText: '0 = Free',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _visibility,
                        decoration: const InputDecoration(
                          labelText: 'Visibility',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('Published'),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text('Archived'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _visibility = val!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Linked Batches Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Linked Batches',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showLinkBatchDialog,
                            icon: const Icon(Icons.link, size: 18),
                            label: const Text('Link to Batch'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_linkedBatches.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No batches linked yet.\nLink this test series to course batches so enrolled students can access it.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _linkedBatches.map((lb) {
                            return Chip(
                              avatar: const Icon(Icons.school, size: 16),
                              label: Text('${lb.courseName} → ${lb.batchName}'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _linkedBatches.removeWhere(
                                    (b) =>
                                        b.courseId == lb.courseId &&
                                        b.batchId == lb.batchId,
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tests Card (only show when editing, since we need an ID)
              if (_isEditing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tests',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                // Count existing tests to set order
                                final snapshot = await FirebaseFirestore
                                    .instance
                                    .collection('test_series')
                                    .doc(widget.testSeries!.id)
                                    .collection('tests')
                                    .get();
                                if (!mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  '/test_series_test_editor',
                                  arguments: {
                                    'testSeriesId': widget.testSeries!.id,
                                    'testId': null,
                                    'order': snapshot.docs.length,
                                    'initialData': null,
                                  },
                                );
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Test'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('test_series')
                              .doc(widget.testSeries!.id)
                              .collection('tests')
                              .orderBy('order')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final tests = snapshot.data!.docs;
                            if (tests.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No tests added yet.\nAdd tests so students can attempt them.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: tests.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final testDoc = entry.value;
                                final testData =
                                    testDoc.data() as Map<String, dynamic>;
                                final title =
                                    testData['title'] ?? 'Test ${idx + 1}';
                                final totalQs = testData['totalQuestions'] ?? 0;
                                final duration =
                                    testData['durationMinutes'] ?? 0;
                                final testSubject =
                                    testData['subject'] as String? ?? '';
                                final testCategory =
                                    testData['category'] as String? ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.withValues(
                                        alpha: 0.1,
                                      ),
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$totalQs questions • $duration min',
                                        ),
                                        if (testSubject.isNotEmpty ||
                                            testCategory.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Wrap(
                                              spacing: 6,
                                              children: [
                                                if (testCategory.isNotEmpty)
                                                  Chip(
                                                    label: Text(
                                                      testCategory,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    padding:
                                                        EdgeInsets.zero,
                                                  ),
                                                if (testSubject.isNotEmpty)
                                                  Chip(
                                                    label: Text(
                                                      testSubject,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    padding:
                                                        EdgeInsets.zero,
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/test_series_test_editor',
                                              arguments: {
                                                'testSeriesId':
                                                    widget.testSeries!.id,
                                                'testId': testDoc.id,
                                                'order':
                                                    testData['order'] ?? idx,
                                                'initialData': testData,
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Delete Test',
                                                ),
                                                content: Text(
                                                  'Delete "$title"? This cannot be undone.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    style:
                                                        FilledButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await testDoc.reference.delete();
                                              await _service.updateTestCount(
                                                widget.testSeries!.id,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isEditing ? 'Update Test Series' : 'Create Test Series',
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
