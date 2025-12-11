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
        onPressed: () => _showAddDialog(context, service),
      ),
      body: StreamBuilder<List<AdminNote>>(
        stream: service.getBatchNotes(courseId, batchId),
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
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                  title: Text(note.title),
                  subtitle: Text(note.subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => service.deleteBatchNote(courseId, batchId, note.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, FirebaseAdminService service) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String? pdfUrl;

    showDialog(
      context: context,
      builder: (context) => Provider.value(
        value: service,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add PDF Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              const SizedBox(height: 16),
              if (pdfUrl != null) ...[
                const Text('PDF Uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              MediaUploader(
                path: 'courses/$courseId/batches/$batchId/notes',
                onUploadComplete: (url) {
                  setState(() => pdfUrl = url);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: pdfUrl == null ? null : () async {
                if (titleController.text.isEmpty) return;
                
                final note = AdminNote(
                  id: '',
                  title: titleController.text,
                  subtitle: subtitleController.text,
                  pdfUrl: pdfUrl!,
                  createdAt: DateTime.now(),
                );
                
                await service.saveBatchNote(courseId, batchId, note, isNew: true);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ));
  }
}
