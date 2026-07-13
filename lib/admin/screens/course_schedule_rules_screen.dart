import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../models/scheduler_models.dart';
import '../widgets/admin_scaffold.dart';

class CourseScheduleRulesScreen extends StatefulWidget {
  final String courseId;

  const CourseScheduleRulesScreen({super.key, required this.courseId});

  @override
  State<CourseScheduleRulesScreen> createState() => _CourseScheduleRulesScreenState();
}

class _CourseScheduleRulesScreenState extends State<CourseScheduleRulesScreen> {
  List<RecurringClassRule> _rules = [];
  AdminCourse? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final service = context.read<FirebaseAdminService>();
    try {
      // 1. Fetch course details to get teachers
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .get();
      if (courseDoc.exists) {
        _course = AdminCourse.fromMap(courseDoc.data()!, courseDoc.id);
      }

      // 2. Fetch recurring rules
      _rules = await service.getRecurringRules(widget.courseId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedule rules: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteRule(RecurringClassRule rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring Rule'),
        content: Text('Are you sure you want to delete the rule "${rule.title}"? Already generated classes will remain in the schedule.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = context.read<FirebaseAdminService>();
    try {
      await service.deleteRecurringRule(widget.courseId, rule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rule deleted successfully')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete rule: $e')),
        );
      }
    }
  }

  void _showRuleEditorDialog(RecurringClassRule? existingRule) {
    final service = context.read<FirebaseAdminService>();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existingRule?.title ?? '');
    final descriptionController = TextEditingController(text: existingRule?.description ?? '');
    final durationController = TextEditingController(text: existingRule?.durationMinutes.toString() ?? '60');
    
    // Teachers list
    final teachers = _course?.teachers ?? [];
    CourseTeacher? selectedTeacher;
    if (existingRule != null) {
      final index = teachers.indexWhere((t) => t.uid == existingRule.instructorId);
      if (index != -1) {
        selectedTeacher = teachers[index];
      }
    }
    if (selectedTeacher == null && teachers.isNotEmpty) {
      selectedTeacher = teachers.first;
    }

    String selectedSubject = existingRule?.subject ?? '';
    String selectedChapter = existingRule?.chapter ?? '';

    // Weekdays
    final List<int> selectedWeekdays = List<int>.from(existingRule?.weekdays ?? [1]); // default Monday

    // Time
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    if (existingRule != null) {
      final parts = existingRule.startTime.split(':');
      if (parts.length == 2) {
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    // Dates
    DateTime startDate = existingRule?.startDate ?? DateTime.now();
    DateTime endDate = existingRule?.endDate ?? DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setStateSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingRule == null ? 'Add Recurring Rule' : 'Edit Recurring Rule',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Teacher dropdown
                  const Text('Select Instructor/Teacher:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (teachers.isEmpty)
                    const Text('No teachers assigned to this course. Go to Course Editor first.', style: TextStyle(color: Colors.red))
                  else
                    DropdownButtonFormField<CourseTeacher>(
                      initialValue: selectedTeacher,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: teachers.map((t) {
                        return DropdownMenuItem<CourseTeacher>(
                          value: t,
                          child: Text('${t.name} (${t.subject})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateSheet(() {
                          selectedTeacher = val;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  // ---- Classification Section ----
                  const Text('Classification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<String>>(
                    stream: widget.courseId.isNotEmpty
                        ? service.getSubjectsForCourse(widget.courseId)
                        : service.getSubjects(),
                    builder: (context, subjectsSnap) {
                      final subjects = subjectsSnap.data ?? [];
                      return DropdownButtonFormField<String>(
                        initialValue: selectedSubject.isNotEmpty && subjects.contains(selectedSubject)
                            ? selectedSubject
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('None', style: TextStyle(color: Colors.grey)),
                          ),
                          ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                        ],
                        onChanged: (val) {
                          setStateSheet(() {
                            selectedSubject = val ?? '';
                            selectedChapter = '';
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedSubject.isNotEmpty)
                    StreamBuilder<List<String>>(
                      stream: service.getChaptersForSubject(selectedSubject),
                      builder: (context, chaptersSnap) {
                        final chapters = chaptersSnap.data ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: selectedChapter.isNotEmpty && chapters.contains(selectedChapter)
                              ? selectedChapter
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Chapter/Folder',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.folder),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('None', style: TextStyle(color: Colors.grey)),
                            ),
                            ...chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                          ],
                          onChanged: (val) {
                            setStateSheet(() {
                              selectedChapter = val ?? '';
                            });
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  // Weekdays chips
                  const Text('Weekdays:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (idx) {
                      final dayNum = idx + 1;
                      final isSelected = selectedWeekdays.contains(dayNum);
                      String dayLabel = '';
                      switch (dayNum) {
                        case 1: dayLabel = 'Mon'; break;
                        case 2: dayLabel = 'Tue'; break;
                        case 3: dayLabel = 'Wed'; break;
                        case 4: dayLabel = 'Thu'; break;
                        case 5: dayLabel = 'Fri'; break;
                        case 6: dayLabel = 'Sat'; break;
                        case 7: dayLabel = 'Sun'; break;
                      }
                      return FilterChip(
                        label: Text(dayLabel),
                        selected: isSelected,
                        onSelected: (selected) {
                          setStateSheet(() {
                            if (selected) {
                              selectedWeekdays.add(dayNum);
                            } else {
                              selectedWeekdays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Time & Duration
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text('Time: ${selectedTime.format(context)}'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setStateSheet(() => selectedTime = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (min) *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            if (int.tryParse(val) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                            OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setStateSheet(() => startDate = picked);
                                }
                              },
                              child: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                            OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setStateSheet(() => endDate = picked);
                                }
                              },
                              child: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedTeacher == null) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Please select an instructor')),
                            );
                            return;
                          }
                          if (selectedWeekdays.isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Please select at least one weekday')),
                            );
                            return;
                          }

                          Navigator.pop(sheetCtx);
                          setState(() => _isLoading = true);

                          final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                          final rule = RecurringClassRule(
                            id: existingRule?.id ?? const Uuid().v4(),
                            courseId: widget.courseId,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            instructorId: selectedTeacher!.uid,
                            instructorName: selectedTeacher!.name,
                            weekdays: selectedWeekdays,
                            startTime: formattedTime,
                            durationMinutes: int.parse(durationController.text.trim()),
                            startDate: startDate,
                            endDate: endDate,
                            subject: selectedSubject,
                            chapter: selectedChapter,
                          );
                          try {
                            await service.saveRecurringRule(widget.courseId, rule);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(existingRule == null ? 'Rule added successfully' : 'Rule updated successfully')),
                              );
                            }
                            _loadData();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save rule: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                        child: const Text('Save Rule'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Course Schedule Rules',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Course: ${_course?.title ?? "Loading..."}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Rule'),
                        onPressed: () => _showRuleEditorDialog(null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Manage recurring schedule rules here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _rules.isEmpty
                        ? const Center(
                            child: Text(
                              'No recurring rules defined for this course yet.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _rules.length,
                            itemBuilder: (context, index) {
                              final rule = _rules[index];
                              final weekdayNames = rule.weekdays.map((w) {
                                switch (w) {
                                  case 1: return 'Mon';
                                  case 2: return 'Tue';
                                  case 3: return 'Wed';
                                  case 4: return 'Thu';
                                  case 5: return 'Fri';
                                  case 6: return 'Sat';
                                  case 7: return 'Sun';
                                  default: return '';
                                }
                              }).join(', ');

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    rule.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text('Instructor: ${rule.instructorName}'),
                                      const SizedBox(height: 4),
                                      Text('Weekdays: $weekdayNames'),
                                      const SizedBox(height: 4),
                                      Text('Time: ${rule.startTime} (${rule.durationMinutes} min)'),
                                      const SizedBox(height: 4),
                                      Text('Active Period: ${DateFormat("yyyy-MM-dd").format(rule.startDate)} to ${DateFormat("yyyy-MM-dd").format(rule.endDate)}'),
                                      if (rule.subject.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Subject: ${rule.subject}'),
                                      ],
                                      if (rule.chapter.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Folder/Chapter: ${rule.chapter}'),
                                      ],
                                      if (rule.description.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(rule.description, style: TextStyle(color: Colors.grey.shade600)),
                                      ],
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showRuleEditorDialog(rule),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteRule(rule),
                                      ),
                                    ],
                                  ),
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
