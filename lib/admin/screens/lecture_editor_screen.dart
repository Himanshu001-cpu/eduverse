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
          
          return ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              // Implement reorder logic update in Firestore
            },
            children: [
              for (final lecture in lectures)
                ListTile(
                  key: ValueKey(lecture.id),
                  title: Text(lecture.title),
                  leading: const Icon(Icons.drag_handle),
                  subtitle: Text(lecture.type),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, service, lecture),
                  ),
                ),
            ],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lecture == null ? 'New Lecture' : 'Edit Lecture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            MediaUploader(
              path: 'courses/$courseId/batches/$batchId/lectures',
              onUploadComplete: (url) {
                // Update state with url
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {}, child: const Text('Save')),
        ],
      ),
    );
  }
}
