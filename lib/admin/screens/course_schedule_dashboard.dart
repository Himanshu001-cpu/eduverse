import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../models/scheduler_models.dart';
import '../widgets/admin_scaffold.dart';

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
                    stream: service.getSubjects(),
                    builder: (context, snapshot) {
                      final subjects = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        initialValue: selectedSubject.isNotEmpty && subjects.contains(selectedSubject)
                            ? selectedSubject
                            : null,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        hint: const Text('Select Subject'),
                        items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedSubject = val ?? '';
                            selectedChapter = '';
                          });
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedSubject.isNotEmpty) ...[
                    const Text('Select Chapter *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<String>>(
                      stream: service.getChaptersForSubject(selectedSubject),
                      builder: (context, snapshot) {
                        final chapters = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: selectedChapter.isNotEmpty && chapters.contains(selectedChapter)
                              ? selectedChapter
                              : null,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          hint: const Text('Select Chapter'),
                          items: chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            setStateDialog(() => selectedChapter = val ?? '');
                          },
                          validator: (v) => v == null || v.isEmpty ? 'Chapter is required' : null,
                        );
                      },
                    ),
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

  void _deleteClass(BuildContext context, AdminLiveClass item) async {
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

    final service = context.read<FirebaseAdminService>();
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
