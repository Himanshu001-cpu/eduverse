import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';

class LectureEditorScreen extends StatelessWidget {
  final String courseId;
  final String batchId;
  
  const LectureEditorScreen({Key? key, required this.courseId, required this.batchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'Lectures',
      body: StreamBuilder<List<AdminLecture>>(
        stream: service.getLectures(courseId, batchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lectures = snapshot.data!;
          if (lectures.isEmpty) return const Center(child: Text('No lectures yet. Tap + to add.'));
          
          return ReorderableListView.builder(
            itemCount: lectures.length,
            onReorder: (oldIndex, newIndex) {
              // TODO: Implement reorder logic
            },
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              return ListTile(
                key: ValueKey(lecture.id),
                leading: const Icon(Icons.drag_handle),
                title: Text(lecture.title),
                subtitle: Text(lecture.storagePath, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, service, lecture),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // TODO: Implement delete logic
                      },
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

  void _showEditDialog(BuildContext context, FirebaseAdminService service, AdminLecture? lecture) {
    final titleController = TextEditingController(text: lecture?.title ?? '');
    final urlController = TextEditingController(text: lecture?.storagePath ?? '');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lecture == null ? 'New Lecture' : 'Edit Lecture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube Video URL',
                  hintText: 'https://youtube.com/...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || urlController.text.isEmpty) return;
                
                final newLecture = AdminLecture(
                  id: lecture?.id ?? '', // Service will ignore empty ID on add
                  title: titleController.text,
                  description: '', // Description not requested, using empty
                  orderIndex: lecture?.orderIndex ?? 0,
                  type: 'video', // Fixed to video as they are YT links
                  storagePath: urlController.text, // Storing URL in storagePath
                  isLocked: lecture?.isLocked ?? false,
                );
                
                try {
                  await service.saveLecture(courseId, batchId, newLecture, isNew: lecture == null);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                   // Error handling
                }
              }, 
              child: const Text('Save')
            ),
          ],
        ),
      ),
    );
  }
}
