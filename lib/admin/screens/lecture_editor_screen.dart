import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';

class LectureEditorScreen extends StatelessWidget {
  final String courseId;
  final String batchId;

  const LectureEditorScreen({
    super.key,
    required this.courseId,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'Lectures',
      body: StreamBuilder<List<AdminLecture>>(
        stream: service.getLectures(courseId, batchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final lectures = snapshot.data!;
          if (lectures.isEmpty)
            return const Center(child: Text('No lectures yet. Tap + to add.'));

          return ReorderableListView.builder(
            itemCount: lectures.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = lectures.removeAt(oldIndex);
              lectures.insert(newIndex, item);

              for (int i = 0; i < lectures.length; i++) {
                if (lectures[i].orderIndex != i) {
                  final updated = AdminLecture(
                    id: lectures[i].id,
                    title: lectures[i].title,
                    description: lectures[i].description,
                    orderIndex: i,
                    type: lectures[i].type,
                    storagePath: lectures[i].storagePath,
                    isLocked: lectures[i].isLocked,
                    subject: lectures[i].subject,
                    chapter: lectures[i].chapter,
                    lectureNo: lectures[i].lectureNo,
                    linkedNoteIds: lectures[i].linkedNoteIds,
                  );
                  service.saveLecture(courseId, batchId, updated);
                }
              }
            },
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              // Build subtitle parts
              final subtitleParts = <String>[];
              if (lecture.subject.isNotEmpty) subtitleParts.add(lecture.subject);
              if (lecture.chapter.isNotEmpty) subtitleParts.add(lecture.chapter);
              if (lecture.lectureNo != null) subtitleParts.add('Lec ${lecture.lectureNo}');
              final metaLine = subtitleParts.isNotEmpty ? subtitleParts.join(' • ') : '';

              return ListTile(
                key: ValueKey(lecture.id),
                leading: const Icon(Icons.drag_handle),
                title: Text(lecture.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metaLine.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          metaLine,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Text(
                      lecture.storagePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lecture.linkedNoteIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 2),
                            Text(
                              '${lecture.linkedNoteIds.length} note(s) linked',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                              ),
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
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEditDialog(context, service, lecture),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _showDeleteConfirmation(context, service, lecture),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showEditDialog(context, service, null),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FirebaseAdminService service,
    AdminLecture lecture,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lecture'),
        content: Text(
          'Are you sure you want to delete "${lecture.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await service.deleteLecture(courseId, batchId, lecture.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting lecture: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    FirebaseAdminService service,
    AdminLecture? lecture,
  ) {
    final titleController = TextEditingController(text: lecture?.title ?? '');
    final urlController = TextEditingController(
      text: lecture?.storagePath ?? '',
    );
    final lectureNoController = TextEditingController(
      text: lecture?.lectureNo?.toString() ?? '',
    );
    final newSubjectController = TextEditingController();
    final newChapterController = TextEditingController();

    String selectedSubject = lecture?.subject ?? '';
    String selectedChapter = lecture?.chapter ?? '';
    List<String> selectedNoteIds = List<String>.from(lecture?.linkedNoteIds ?? []);
    bool showAddSubject = false;
    bool showAddChapter = false;

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<String>>(
        stream: service.getSubjects(),
        builder: (context, subjectsSnapshot) {
          final subjects = subjectsSnapshot.data ?? [];

          return StreamBuilder<List<AdminNote>>(
            stream: service.getBatchNotes(courseId, batchId),
            builder: (context, notesSnapshot) {
              final allNotes = notesSnapshot.data ?? [];

              return StatefulBuilder(
                builder: (context, setState) {
                  // Build subject items
                  final subjectItems = <DropdownMenuItem<String>>[
                    const DropdownMenuItem(
                      value: '',
                      child: Text('None', style: TextStyle(color: Colors.grey)),
                    ),
                    ...subjects.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
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

                  return AlertDialog(
                    title: Text(lecture == null ? 'New Lecture' : 'Edit Lecture'),
                    content: SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: urlController,
                              decoration: const InputDecoration(
                                labelText: 'YouTube Video URL',
                                hintText: 'https://youtube.com/...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Classification',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),

                            // Subject dropdown
                            DropdownButtonFormField<String>(
                              initialValue: selectedSubject.isNotEmpty && subjects.contains(selectedSubject)
                                  ? selectedSubject
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.subject),
                              ),
                              items: subjectItems,
                              onChanged: (val) {
                                if (val == '__add_new__') {
                                  setState(() => showAddSubject = true);
                                } else {
                                  setState(() {
                                    selectedSubject = val ?? '';
                                    selectedChapter = '';
                                    showAddSubject = false;
                                  });
                                }
                              },
                            ),

                            // Add new subject inline
                            if (showAddSubject) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: newSubjectController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter new subject name',
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
                                        await service.addSubject(name);
                                        setState(() {
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
                                    onPressed: () => setState(() {
                                      showAddSubject = false;
                                      newSubjectController.clear();
                                    }),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Chapter dropdown (depends on selected subject)
                            if (selectedSubject.isNotEmpty)
                              StreamBuilder<List<String>>(
                                stream: service.getChaptersForSubject(selectedSubject),
                                builder: (context, chaptersSnapshot) {
                                  final chapters = chaptersSnapshot.data ?? [];
                                  final chapterItems = <DropdownMenuItem<String>>[
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('None', style: TextStyle(color: Colors.grey)),
                                    ),
                                    ...chapters.map(
                                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                                    ),
                                    const DropdownMenuItem(
                                      value: '__add_new__',
                                      child: Row(
                                        children: [
                                          Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Add new chapter', style: TextStyle(color: Colors.blue)),
                                        ],
                                      ),
                                    ),
                                  ];

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedChapter.isNotEmpty && chapters.contains(selectedChapter)
                                            ? selectedChapter
                                            : null,
                                        decoration: const InputDecoration(
                                          labelText: 'Chapter',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.menu_book),
                                        ),
                                        items: chapterItems,
                                        onChanged: (val) {
                                          if (val == '__add_new__') {
                                            setState(() => showAddChapter = true);
                                          } else {
                                            setState(() {
                                              selectedChapter = val ?? '';
                                              showAddChapter = false;
                                            });
                                          }
                                        },
                                      ),

                                      // Add new chapter inline
                                      if (showAddChapter) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: newChapterController,
                                                decoration: const InputDecoration(
                                                  hintText: 'Enter new chapter name',
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
                                                  await service.addChapterToSubject(selectedSubject, name);
                                                  setState(() {
                                                    selectedChapter = name;
                                                    showAddChapter = false;
                                                    newChapterController.clear();
                                                  });
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.cancel, color: Colors.red),
                                              onPressed: () => setState(() {
                                                showAddChapter = false;
                                                newChapterController.clear();
                                              }),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              )
                            else
                              const Text(
                                'Select a subject to see chapters',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),

                            const SizedBox(height: 12),
                            // Lecture No
                            TextField(
                              controller: lectureNoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Lecture No.',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.format_list_numbered),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Linked Notes
                            const Text(
                              'Linked Notes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            if (allNotes.isEmpty)
                              const Text(
                                'No notes available in this batch.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              )
                            else ...[
                              ...allNotes.map((note) {
                                final isLinked = selectedNoteIds.contains(note.id);
                                return CheckboxListTile(
                                  value: isLinked,
                                  title: Text(note.title, style: const TextStyle(fontSize: 14)),
                                  subtitle: note.subtitle.isNotEmpty
                                      ? Text(note.subtitle, style: const TextStyle(fontSize: 12))
                                      : null,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  secondary: const Icon(Icons.picture_as_pdf, color: Colors.orange, size: 20),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedNoteIds.add(note.id);
                                      } else {
                                        selectedNoteIds.remove(note.id);
                                      }
                                    });
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty || urlController.text.isEmpty)
                            return;

                          final newLecture = AdminLecture(
                            id: lecture?.id ?? '',
                            title: titleController.text,
                            description: '',
                            orderIndex: lecture?.orderIndex ?? 0,
                            type: 'video',
                            storagePath: urlController.text,
                            isLocked: lecture?.isLocked ?? false,
                            subject: selectedSubject,
                            chapter: selectedChapter,
                            lectureNo: int.tryParse(lectureNoController.text),
                            linkedNoteIds: selectedNoteIds,
                          );

                          try {
                            await service.saveLecture(
                              courseId,
                              batchId,
                              newLecture,
                              isNew: lecture == null,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            // Error handling
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
