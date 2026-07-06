import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/admin/widgets/thumbnail_upload_widget.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  String _uploadedIconUrl = '';

  String? _editingExamId;
  List<String> _selectedCourseIds = [];
  String? _errorMsg;

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _iconController.clear();
      _uploadedIconUrl = '';
      _editingExamId = null;
      _selectedCourseIds = [];
      _errorMsg = null;
    });
  }

  Future<void> _saveExam(BuildContext context, StudyController controller) async {
    setState(() {
      _errorMsg = null;
    });

    final name = _nameController.text.trim();
    final iconUrl = _iconController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMsg = 'Name is required';
      });
      return;
    }

    if (iconUrl.isEmpty) {
      setState(() {
        _errorMsg = 'Icon URL/image is required';
      });
      return;
    }

    if (!iconUrl.startsWith('http://') && !iconUrl.startsWith('https://')) {
      setState(() {
        _errorMsg = 'Must be a valid HTTP/HTTPS URL';
      });
      return;
    }

    final id = _editingExamId ?? FirebaseFirestore.instance.collection('exams').doc().id;
    
    // Find current order
    int orderIndex = controller.exams.length;
    if (_editingExamId != null) {
      try {
        final existing = controller.exams.firstWhere((e) => e['id'] == _editingExamId);
        orderIndex = existing['orderIndex'] as int? ?? 0;
      } catch (_) {}
    }

    final examData = {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'orderIndex': orderIndex,
      'assignedCourses': _selectedCourseIds,
    };

    try {
      await FirebaseFirestore.instance.collection('exams').doc(id).set(examData);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam saved successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    }
  }

  Future<void> _deleteExam(BuildContext context, String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('admin_delete_dialog'),
        title: const Text('Delete Exam'),
        content: const Text('Are you sure you want to delete this exam?'),
        actions: [
          TextButton(
            key: const Key('admin_delete_cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('admin_delete_confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('exams').doc(examId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting exam: $e')),
        );
      }
    }
  }

  Future<void> _reorderExams(List<Map<String, dynamic>> examsList, int oldIndex, int newIndex) async {
    final item = examsList.removeAt(oldIndex);
    examsList.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < examsList.length; i++) {
      final exam = examsList[i];
      final ref = FirebaseFirestore.instance.collection('exams').doc(exam['id']);
      batch.update(ref, {'orderIndex': i});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);

    // List of active individual batches enrolled (not combo packs)
    final courses = controller.enrolledBatches.where((b) => !b.isCombo).toList();

    // Sort exams by display order
    final sortedExams = List<Map<String, dynamic>>.from(controller.exams)
      ..sort((a, b) => (a['orderIndex'] as int? ?? 0).compareTo(b['orderIndex'] as int? ?? 0));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('admin_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Admin: Exam Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingExamId == null ? 'Create New Exam' : 'Edit Exam',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('admin_exam_name_field'),
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Exam Name',
                        hintText: 'e.g. UPSC CSE, JEE Main',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    TextFormField(
                      key: const Key('admin_exam_icon_field'),
                      controller: _iconController,
                      decoration: InputDecoration(
                        labelText: 'Icon URL',
                        hintText: 'https://example.com/icon.png',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _uploadedIconUrl = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'OR Upload Icon Directly:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ThumbnailUploadWidget(
                      key: const Key('admin_exam_icon_uploader'),
                      currentUrl: _uploadedIconUrl.isNotEmpty ? _uploadedIconUrl : null,
                      storagePath: 'exams/icons',
                      onUploaded: (url) {
                        setState(() {
                          _uploadedIconUrl = url;
                          _iconController.text = url;
                        });
                      },
                      height: 120,
                    ),
                    const Text(
                      'Assign Batches / Courses',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...courses.map((course) {
                      final isAssigned = _selectedCourseIds.contains(course.id);
                      return CheckboxListTile(
                        key: Key('admin_course_checkbox_${course.id}'),
                        title: Text(course.name),
                        subtitle: Text(course.courseName),
                        value: isAssigned,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedCourseIds.add(course.id);
                            } else {
                              _selectedCourseIds.remove(course.id);
                            }
                          });
                        },
                      );
                    }),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMsg!,
                        key: const Key('admin_error_message'),
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            key: const Key('admin_save_exam_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _saveExam(context, controller),
                            child: const Text('Save Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (_editingExamId != null) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            key: const Key('admin_cancel_edit_button'),
                            onPressed: _clearForm,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Existing Exams (Drag to Reorder)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Reorderable List
            if (sortedExams.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Text('No exams created yet.', style: TextStyle(color: Colors.grey.shade600)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                height: 350,
                child: ReorderableListView.builder(
                  key: const Key('admin_exam_reorder_list'),
                  itemCount: sortedExams.length,
                  onReorderItem: (oldIndex, newIndex) => _reorderExams(sortedExams, oldIndex, newIndex),
                  itemBuilder: (ctx, index) {
                    final exam = sortedExams[index];
                    final examId = exam['id'] as String;
                    final assignedCount = (exam['assignedCourses'] as List?)?.length ?? 0;

                    return ListTile(
                      key: Key('admin_exam_tile_$examId'),
                      title: Text(exam['name'] ?? ''),
                      subtitle: Text('$assignedCount batches assigned'),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: exam['iconUrl'] != null && (exam['iconUrl'] as String).startsWith('http')
                            ? NetworkImage(exam['iconUrl'])
                            : null,
                        child: exam['iconUrl'] == null || !(exam['iconUrl'] as String).startsWith('http')
                            ? const Icon(Icons.school)
                            : null,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('admin_edit_exam_$examId'),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                _editingExamId = examId;
                                _nameController.text = exam['name'] ?? '';
                                _iconController.text = exam['iconUrl'] ?? '';
                                _uploadedIconUrl = exam['iconUrl'] ?? '';
                                _selectedCourseIds = List<String>.from(exam['assignedCourses'] ?? []);
                                _errorMsg = null;
                              });
                            },
                          ),
                          IconButton(
                            key: Key('admin_delete_exam_$examId'),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteExam(context, examId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
