import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';

class BatchNotesScreen extends StatelessWidget {
  final String courseId;
  final String batchId;

  const BatchNotesScreen({super.key, required this.courseId, required this.batchId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'Batch Notes',
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showNoteDialog(context, service, null),
      ),
      body: StreamBuilder<List<AdminNote>>(
        stream: service.getCourseNotes(courseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final notes = snapshot.data!;
          if (notes.isEmpty) return const Center(child: Text('No notes added yet.'));

          return ListView.builder(
            itemCount: notes.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final note = notes[index];
              // Build metadata line
              final metaParts = <String>[];
              if (note.subject.isNotEmpty) metaParts.add(note.subject);
              if (note.chapter.isNotEmpty) metaParts.add(note.chapter);
              final metaLine = metaParts.isNotEmpty ? metaParts.join(' • ') : '';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                  title: Text(note.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (metaLine.isNotEmpty)
                        Text(
                          metaLine,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (note.subtitle.isNotEmpty)
                        Text(note.subtitle),
                      if (note.lectureId != null)
                        Row(
                          children: [
                            Icon(Icons.link, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Linked to lecture',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showNoteDialog(context, service, note),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, service, note),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirebaseAdminService service, AdminNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteCourseNote(courseId, note.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Shared dialog for both adding and editing a note.
  /// Pass [note] = null for add mode.
  void _showNoteDialog(BuildContext context, FirebaseAdminService service, AdminNote? note) {
    final isEditing = note != null;
    final titleController = TextEditingController(text: note?.title ?? '');
    final subtitleController = TextEditingController(text: note?.subtitle ?? '');
    final newSubjectController = TextEditingController();
    final newChapterController = TextEditingController();
    String? pdfUrl = note?.pdfUrl;
    String selectedSubject = note?.subject ?? '';
    String selectedChapter = note?.chapter ?? '';
    String? selectedLectureId = note?.lectureId;
    bool showAddSubject = false;
    bool showAddChapter = false;

    showDialog(
      context: context,
      builder: (context) => Provider.value(
        value: service,
        child: StreamBuilder<List<String>>(
          stream: service.getSubjects(),
          builder: (context, subjectsSnapshot) {
            final subjects = subjectsSnapshot.data ?? [];

            return StreamBuilder<List<AdminLecture>>(
              stream: service.getLectures(courseId),
              builder: (context, lecturesSnapshot) {
                final lectures = lecturesSnapshot.data ?? [];

                return StatefulBuilder(
                  builder: (context, setState) {
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
                      title: Text(isEditing ? 'Edit Note' : 'Add PDF Note'),
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
                              const SizedBox(height: 8),
                              TextField(
                                controller: subtitleController,
                                decoration: const InputDecoration(
                                  labelText: 'Subtitle',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Classification
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

                              // Optional lecture link
                              DropdownButtonFormField<String>(
                                initialValue: selectedLectureId != null &&
                                        lectures.any((l) => l.id == selectedLectureId)
                                    ? selectedLectureId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Link to Lecture (optional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.link),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('None', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ...lectures.map(
                                    (l) => DropdownMenuItem(
                                      value: l.id,
                                      child: Text(
                                        l.lectureNo != null ? 'Lec ${l.lectureNo}: ${l.title}' : l.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() => selectedLectureId = val),
                              ),

                              const SizedBox(height: 16),

                              // PDF upload section
                              if (pdfUrl != null && pdfUrl!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('PDF uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                    if (isEditing)
                                      TextButton(
                                        onPressed: () => setState(() => pdfUrl = null),
                                        child: const Text('Replace', style: TextStyle(color: Colors.orange)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (pdfUrl == null || pdfUrl!.isEmpty)
                                MediaUploader(
                                  path: 'courses/$courseId/notes',
                                  onUploadComplete: (url) {
                                    setState(() => pdfUrl = url);
                                  },
                                ),
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
                          onPressed: (pdfUrl == null || pdfUrl!.isEmpty) ? null : () async {
                            if (titleController.text.isEmpty) return;

                            final updatedNote = AdminNote(
                              id: note?.id ?? '',
                              title: titleController.text,
                              subtitle: subtitleController.text,
                              pdfUrl: pdfUrl!,
                              createdAt: note?.createdAt ?? DateTime.now(),
                              subject: selectedSubject,
                              chapter: selectedChapter,
                              lectureId: selectedLectureId,
                            );

                            await service.saveCourseNote(
                              courseId,
                              updatedNote,
                              isNew: !isEditing,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(isEditing ? 'Save' : 'Add'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
