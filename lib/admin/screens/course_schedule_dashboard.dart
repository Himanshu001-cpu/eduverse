import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../models/scheduler_models.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/manage_linked_courses_dialog.dart';

class CourseScheduleDashboard extends StatefulWidget {
  final String courseId;

  const CourseScheduleDashboard({super.key, required this.courseId});

  @override
  State<CourseScheduleDashboard> createState() => _CourseScheduleDashboardState();
}

class _CourseScheduleDashboardState extends State<CourseScheduleDashboard> {
  bool _isGenerating = false;

  bool _checkConflict(AdminLiveClass classA, AdminLiveClass classB) {
    if (classA.id == classB.id) return false;
    // Conflict if same instructor or same course
    if (classA.instructorName != classB.instructorName && 
        (classA.linkedCourses.isEmpty || classB.linkedCourses.isEmpty || 
         classA.linkedCourses.first != classB.linkedCourses.first)) {
      return false;
    }
    
    // Check if the classes are on the same calendar day
    final dateA = DateTime(classA.startTime.year, classA.startTime.month, classA.startTime.day);
    final dateB = DateTime(classB.startTime.year, classB.startTime.month, classB.startTime.day);
    if (dateA != dateB) return false;

    final startA = classA.startTime;
    final endA = classA.startTime.add(Duration(minutes: classA.durationMinutes));
    final startB = classB.startTime;
    final endB = classB.startTime.add(Duration(minutes: classB.durationMinutes));
    return startA.isBefore(endB) && startB.isBefore(endA);
  }

  List<AdminLiveClass> _getConflictedClasses(List<AdminLiveClass> classes) {
    final List<AdminLiveClass> conflicted = [];
    for (final classA in classes) {
      if (classA.status == 'cancelled') continue;
      bool hasConflict = false;
      for (final classB in classes) {
        if (classB.status == 'cancelled') continue;
        if (_checkConflict(classA, classB)) {
          hasConflict = true;
          break;
        }
      }
      if (hasConflict) {
        conflicted.add(classA);
      }
    }
    return conflicted;
  }

  void _showGenerateDialog(BuildContext context) async {
    final service = context.read<FirebaseAdminService>();
    List<RecurringClassRule> rules = [];
    try {
      rules = await service.getRecurringRules(widget.courseId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rules: $e')),
        );
      }
      return;
    }

    if (rules.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('No Rules Found'),
            content: const Text('Please create a recurring class rule first before generating classes.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    RecurringClassRule? selectedRule = rules.first;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 14));

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) => AlertDialog(
          title: const Text('Generate Live Classes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Recurring Rule:'),
              DropdownButton<RecurringClassRule>(
                value: selectedRule,
                isExpanded: true,
                items: rules.map((r) {
                  return DropdownMenuItem<RecurringClassRule>(
                    value: r,
                    child: Text('${r.title} (${r.instructorName})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setStateDialog(() => selectedRule = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date:'),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setStateDialog(() => startDate = picked);
                            }
                          },
                          child: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date:'),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setStateDialog(() => endDate = picked);
                            }
                          },
                          child: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isGenerating = true);
                try {
                  await service.generateLiveClasses(
                    widget.courseId,
                    selectedRule!.id,
                    startDate,
                    endDate,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Classes generated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error generating classes: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isGenerating = false);
                  }
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _rescheduleClass(BuildContext context, AdminLiveClass item) async {
    final service = context.read<FirebaseAdminService>();
    final initialDate = item.startTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    final newStartTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      await service.updateLiveClassInstance(
        widget.courseId,
        item.id,
        newStartTime: newStartTime,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class rescheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reschedule class: $e')),
        );
      }
    }
  }

  void _cancelClass(BuildContext context, AdminLiveClass item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Class Instance'),
        content: Text('Are you sure you want to cancel the class "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = context.read<FirebaseAdminService>();
    try {
      await service.updateLiveClassInstance(
        widget.courseId,
        item.id,
        status: 'cancelled',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel class: $e')),
        );
      }
    }
  }

  void _showGoLiveDialog(BuildContext context, AdminLiveClass item) async {
    final formKey = GlobalKey<FormState>();
    final ytController = TextEditingController(text: item.youtubeUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go Live Now'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the YouTube Live Stream URL to start the class:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: ytController,
                decoration: const InputDecoration(
                  labelText: 'YouTube Live Link',
                  hintText: 'https://youtube.com/watch?v=...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              
              final service = context.read<FirebaseAdminService>();
              try {
                await service.updateLiveClassInstance(
                  widget.courseId,
                  item.id,
                  status: 'live',
                  youtubeUrl: ytController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class is now LIVE!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to go live: $e')),
                  );
                }
              }
            },
            child: const Text('Go Live'),
          ),
        ],
      ),
    );
  }

  void _showCompleteClassDialog(BuildContext context, AdminLiveClass item) async {
    final formKey = GlobalKey<FormState>();
    final ytController = TextEditingController(text: item.youtubeUrl);
    final service = context.read<FirebaseAdminService>();

    String selectedSubject = item.subject;
    String selectedChapter = item.chapter;
    bool showAddSubject = false;
    bool showAddChapter = false;
    final newSubjectController = TextEditingController();
    final newChapterController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) => AlertDialog(
          title: const Text('Complete & Save Live Class'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirm the YouTube recording URL and folder classification:'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ytController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube Recording Link',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Folder/Subject *', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<String>>(
                    stream: widget.courseId.isNotEmpty
                        ? service.getSubjectsForCourse(widget.courseId)
                        : service.getAllCourseSubjects(),
                    builder: (context, snapshot) {
                      final subjects = snapshot.data ?? [];
                      final subjectItems = <DropdownMenuItem<String>>[
                        ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                        const DropdownMenuItem(
                          value: '__add_new__',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Add new subject', style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                      ];
                      return DropdownButtonFormField<String>(
                        initialValue: selectedSubject.isNotEmpty && subjects.contains(selectedSubject)
                            ? selectedSubject
                            : null,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        hint: const Text('Select Subject'),
                        items: subjectItems,
                        onChanged: (val) {
                          if (val == '__add_new__') {
                            setStateDialog(() => showAddSubject = true);
                          } else {
                            setStateDialog(() {
                              selectedSubject = val ?? '';
                              selectedChapter = '';
                              showAddSubject = false;
                            });
                          }
                        },
                        validator: (v) => (v == null || v.isEmpty) && !showAddSubject ? 'Subject is required' : null,
                      );
                    },
                  ),
                  if (showAddSubject) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newSubjectController,
                            decoration: const InputDecoration(
                              hintText: 'Enter new subject name (adds folder)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            autofocus: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () async {
                            final name = newSubjectController.text.trim();
                            if (name.isNotEmpty) {
                              if (widget.courseId.isNotEmpty) {
                                await service.addSubjectFolderToCourse(widget.courseId, name);
                              }
                              setStateDialog(() {
                                selectedSubject = name;
                                selectedChapter = '';
                                showAddSubject = false;
                                newSubjectController.clear();
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => setStateDialog(() {
                            showAddSubject = false;
                            newSubjectController.clear();
                          }),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (selectedSubject.isNotEmpty) ...[
                    const Text('Select Topic / Chapter *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<String>>(
                      stream: widget.courseId.isNotEmpty
                          ? service.getChaptersForCourseSubject(widget.courseId, selectedSubject)
                          : service.getAllCourseChaptersForSubject(selectedSubject),
                      builder: (context, snapshot) {
                        final chapters = snapshot.data ?? [];
                        final chapterItems = <DropdownMenuItem<String>>[
                          ...chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                          const DropdownMenuItem(
                            value: '__add_new__',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Add new topic / chapter', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ),
                        ];
                        return DropdownButtonFormField<String>(
                          initialValue: selectedChapter.isNotEmpty && chapters.contains(selectedChapter)
                              ? selectedChapter
                              : null,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          hint: const Text('Select Topic / Chapter'),
                          items: chapterItems,
                          onChanged: (val) {
                            if (val == '__add_new__') {
                              setStateDialog(() => showAddChapter = true);
                            } else {
                              setStateDialog(() {
                                selectedChapter = val ?? '';
                                showAddChapter = false;
                              });
                            }
                          },
                          validator: (v) => (v == null || v.isEmpty) && !showAddChapter ? 'Chapter is required' : null,
                        );
                      },
                    ),
                    if (showAddChapter) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newChapterController,
                              decoration: const InputDecoration(
                                hintText: 'Enter new topic/chapter name',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              autofocus: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () async {
                              final name = newChapterController.text.trim();
                              if (name.isNotEmpty) {
                                if (widget.courseId.isNotEmpty) {
                                  await service.addTopicFolderToCourse(widget.courseId, selectedSubject, name);
                                }
                                setStateDialog(() {
                                  selectedChapter = name;
                                  showAddChapter = false;
                                  newChapterController.clear();
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => setStateDialog(() {
                              showAddChapter = false;
                              newChapterController.clear();
                            }),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                
                try {
                  await service.updateLiveClassInstance(
                    widget.courseId,
                    item.id,
                    status: 'completed',
                    youtubeUrl: ytController.text.trim(),
                    subject: selectedSubject,
                    chapter: selectedChapter,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Class completed and moved to Lectures!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to complete class: $e')),
                    );
                  }
                }
              },
              child: const Text('Complete & Move'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndSyncLiveClass(BuildContext context, AdminLiveClass item) async {
    final service = context.read<FirebaseAdminService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Live Class to Linked Courses?'),
        content: Text(
          'This will update details for "${item.title}" in all other courses where this live class is shared/linked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final updatedCount = await service.syncLiveClassToLinkedCourses(
        sourceCourseId: widget.courseId,
        liveClass: item,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully synced live class across $updatedCount location(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync live class: $e')),
        );
      }
    }
  }

  void _deleteClass(BuildContext context, AdminLiveClass item) async {
    final service = context.read<FirebaseAdminService>();
    final isLinked = item.linkedFrom != null || item.linkedCourses.isNotEmpty;

    if (!isLinked) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Class Instance'),
          content: Text('Are you sure you want to delete "${item.title}" completely?'),
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

      try {
        await service.deleteCourseLiveClass(widget.courseId, item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete class: $e')),
          );
        }
      }
      return;
    }

    // Class is linked - show choice dialog (Delink vs Delete)
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Linked Live Class Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${item.title}" is linked to other courses.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose what you would like to do:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔗 Delink', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 2),
                  Text(
                    'Removes sync connection. The class stays in this course as an independent copy.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🗑️ Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 2),
                  Text(
                    'Warning: Permanently removes the live class from this course.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.link_off, size: 16),
            label: const Text('Delink'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                if (widget.courseId.isNotEmpty) {
                  await service.delinkLiveClass(widget.courseId, item.id);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live class delinked successfully (now independent)')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error delinking: $e')),
                  );
                }
              }
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                if (widget.courseId.isNotEmpty) {
                  await service.deleteCourseLiveClass(widget.courseId, item.id, deleteAllLinked: false);
                } else {
                  await service.deleteLiveClass(item.id, deleteAllLinked: false);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from this course successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rootContext = context; // Stable context from build method — survives StreamBuilder/ListView rebuilds
    final service = context.watch<FirebaseAdminService>();

    return AdminScaffold(
      title: 'Course Schedule Dashboard',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar
             Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Manage schedules and view conflicts.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                ElevatedButton.icon(
                  key: const Key('manage_rules_button'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Recurring Rules'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/course_schedule_rules',
                      arguments: widget.courseId,
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Class'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Schedule Class button clicked'), duration: Duration(milliseconds: 500)),
                    );
                    Navigator.pushNamed(
                      context,
                      '/live_class_editor',
                      arguments: {
                        'courseId': widget.courseId,
                        'batchId': '',
                      },
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Generate Classes'),
                  onPressed: _isGenerating ? null : () => _showGenerateDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isGenerating)
              const LinearProgressIndicator(),

            // List of generated live classes
            Expanded(
              child: StreamBuilder<List<AdminLiveClass>>(
                stream: service.getCourseLiveClasses(widget.courseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading schedule: ${snapshot.error}'));
                  }

                  final classes = snapshot.data ?? [];
                  if (classes.isEmpty) {
                    return const Center(
                      child: Text(
                        'No classes scheduled',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // Sort chronologically
                  classes.sort((a, b) => a.startTime.compareTo(b.startTime));

                  final conflictedClasses = _getConflictedClasses(classes);

                  return ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final item = classes[index];
                      final isConflicted = conflictedClasses.any((c) => c.id == item.id);

                      final isCancelled = item.status == 'cancelled';
                      final isCompleted = item.status == 'completed';
                      final isLive = item.status == 'live';

                      Color statusColor = Colors.blue;
                      if (isCancelled) statusColor = Colors.grey;
                      if (isCompleted) statusColor = Colors.green;
                      if (isLive) statusColor = Colors.red;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isConflicted
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide(color: Colors.grey.shade300),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.linkedCourses.isNotEmpty || (item.linkedFrom != null && item.linkedFrom!.isNotEmpty)) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.link, color: Colors.teal, size: 11),
                                      SizedBox(width: 4),
                                      Text(
                                        'LINKED',
                                        style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isConflicted) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'CONFLICT',
                                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Instructor: ${item.instructorName}'),
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${DateFormat('yyyy-MM-dd HH:mm').format(item.startTime)} (${item.durationMinutes} min)',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(item.description, style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ],
                          ),
                           trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (BuildContext popupCtx) => <PopupMenuEntry>[
                              PopupMenuItem(
                                onTap: () {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    Navigator.pushNamed(
                                      rootContext,
                                      '/live_class_editor',
                                      arguments: {
                                        'item': item,
                                        'courseId': widget.courseId,
                                        'batchId': '',
                                      },
                                    ).then((_) {
                                      if (mounted) setState(() {});
                                    });
                                  });
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blueGrey),
                                    SizedBox(width: 12),
                                    Text('Edit details'),
                                  ],
                                ),
                              ),
                              if (item.linkedCourses.isNotEmpty)
                                PopupMenuItem(
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      showDialog(
                                        context: rootContext,
                                        builder: (_) => Provider<FirebaseAdminService>.value(
                                          value: service,
                                          child: ManageLinkedCoursesDialog(
                                            liveClass: item,
                                            sourceCourseId: widget.courseId,
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.hub, color: Colors.teal),
                                      SizedBox(width: 12),
                                      Text('Manage Linked Courses'),
                                    ],
                                  ),
                                )
                              else if (item.linkedFrom != null && item.linkedFrom!.isNotEmpty)
                                PopupMenuItem(
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      _confirmAndSyncLiveClass(rootContext, item);
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.sync, color: Colors.teal),
                                      SizedBox(width: 12),
                                      Text('Sync Linked Courses'),
                                    ],
                                  ),
                                ),
                              if (item.status == 'scheduled')
                                PopupMenuItem(
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      _showGoLiveDialog(rootContext, item);
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.live_tv, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text('Go Live Now'),
                                    ],
                                  ),
                                ),
                              if (item.status == 'scheduled' || item.status == 'live')
                                PopupMenuItem(
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      _showCompleteClassDialog(rootContext, item);
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.purple),
                                      SizedBox(width: 12),
                                      Text('Complete Class'),
                                    ],
                                  ),
                                ),
                              if (!isCompleted && !isCancelled)
                                PopupMenuItem(
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      _rescheduleClass(rootContext, item);
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.schedule, color: Colors.blue),
                                      SizedBox(width: 12),
                                      Text('Reschedule'),
                                    ],
                                  ),
                                ),
                              if (!isCompleted && !isCancelled)
                                PopupMenuItem(
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      _cancelClass(rootContext, item);
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.cancel_outlined, color: Colors.orange),
                                      SizedBox(width: 12),
                                      Text('Cancel Class'),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                onTap: () {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    _deleteClass(rootContext, item);
                                  });
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Delete completely'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
