import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';

class BatchDppScreen extends StatelessWidget {
  final String courseId;
  final String batchId;

  const BatchDppScreen({super.key, required this.courseId, required this.batchId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'DPP (Daily Practice Problems)',
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showDppDialog(context, service, null),
      ),
      body: StreamBuilder<List<AdminDpp>>(
        stream: service.getBatchDpps(courseId, batchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final dpps = snapshot.data!;
          if (dpps.isEmpty) return const Center(child: Text('No DPPs added yet. Tap + to add.'));

          return ListView.builder(
            itemCount: dpps.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final dpp = dpps[index];
              final metaLine = [dpp.subject, dpp.chapter]
                  .where((s) => s.isNotEmpty)
                  .join(' • ');

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.deepPurple),
                  title: Text(dpp.title),
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
                      Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          const Text('DPP', style: TextStyle(fontSize: 11)),
                          if (dpp.solutionPdfUrl.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            const Text('Solution', style: TextStyle(fontSize: 11)),
                          ],
                        ],
                      ),
                      if (dpp.lectureId != null)
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
                        onPressed: () => _showDppDialog(context, service, dpp),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, service, dpp),
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

  void _confirmDelete(BuildContext context, FirebaseAdminService service, AdminDpp dpp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete DPP'),
        content: Text('Are you sure you want to delete "${dpp.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteBatchDpp(courseId, batchId, dpp.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDppDialog(BuildContext context, FirebaseAdminService service, AdminDpp? dpp) {
    final isEditing = dpp != null;
    final titleController = TextEditingController(text: dpp?.title ?? '');
    final newSubjectController = TextEditingController();
    final newChapterController = TextEditingController();
    String? dppPdfUrl = dpp?.dppPdfUrl;
    String? solutionPdfUrl = dpp?.solutionPdfUrl;
    String selectedSubject = dpp?.subject ?? '';
    String selectedChapter = dpp?.chapter ?? '';
    String? selectedLectureId = dpp?.lectureId;
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
              stream: service.getLectures(courseId, batchId),
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

                    // DPP requires subject — check validity
                    final canSave = titleController.text.isNotEmpty &&
                        selectedSubject.isNotEmpty &&
                        selectedChapter.isNotEmpty &&
                        dppPdfUrl != null &&
                        dppPdfUrl!.isNotEmpty;

                    return AlertDialog(
                      title: Text(isEditing ? 'Edit DPP' : 'Add DPP'),
                      content: SizedBox(
                        width: 450,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title *',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),

                              // Classification (required)
                              const Text(
                                'Classification *',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),

                              // Subject dropdown
                              DropdownButtonFormField<String>(
                                initialValue: selectedSubject.isNotEmpty && subjects.contains(selectedSubject)
                                    ? selectedSubject
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Subject *',
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

                              // Chapter dropdown
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
                                            labelText: 'Chapter *',
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

                              // DPP PDF upload
                              const Text('DPP PDF *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              if (dppPdfUrl != null && dppPdfUrl!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('DPP PDF uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => dppPdfUrl = null),
                                      child: const Text('Replace', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ],
                                ),
                              ] else
                                MediaUploader(
                                  path: 'courses/$courseId/batches/$batchId/dpps',
                                  onUploadComplete: (url) => setState(() => dppPdfUrl = url),
                                ),

                              const SizedBox(height: 16),

                              // Solution PDF upload
                              const Text('Solution PDF (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              if (solutionPdfUrl != null && solutionPdfUrl!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('Solution PDF uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => solutionPdfUrl = null),
                                      child: const Text('Replace', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ],
                                ),
                              ] else
                                MediaUploader(
                                  path: 'courses/$courseId/batches/$batchId/dpps/solutions',
                                  onUploadComplete: (url) => setState(() => solutionPdfUrl = url),
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
                          onPressed: !canSave ? null : () async {
                            final updatedDpp = AdminDpp(
                              id: dpp?.id ?? '',
                              title: titleController.text,
                              subject: selectedSubject,
                              chapter: selectedChapter,
                              dppPdfUrl: dppPdfUrl!,
                              solutionPdfUrl: solutionPdfUrl ?? '',
                              lectureId: selectedLectureId,
                              createdAt: dpp?.createdAt ?? DateTime.now(),
                            );

                            await service.saveBatchDpp(
                              courseId,
                              batchId,
                              updatedDpp,
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
