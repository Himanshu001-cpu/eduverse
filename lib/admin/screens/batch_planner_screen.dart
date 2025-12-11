import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';

class BatchPlannerScreen extends StatelessWidget {
  final String courseId;
  final String batchId;

  const BatchPlannerScreen({super.key, required this.courseId, required this.batchId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'Batch Planner',
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context, service),
      ),
      body: StreamBuilder<List<AdminPlannerItem>>(
        stream: service.getBatchPlanner(courseId, batchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('No planner items added yet.'));

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.event)),
                  title: Text(item.title),
                  subtitle: Text('${item.subtitle}\nDate: ${item.date.day}/${item.date.month}/${item.date.year}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => service.deleteBatchPlannerItem(courseId, batchId, item.id),
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
    DateTime selectedDate = DateTime.now();
    String? pdfUrl;

    showDialog(
      context: context,
      builder: (context) => Provider.value(
        value: service,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Plan PDF'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title (e.g. Monthly Schedule)')),
                const SizedBox(height: 8),
                TextField(controller: subtitleController, decoration: const InputDecoration(labelText: 'Subtitle (e.g. October 2024)')),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => selectedDate = d);
                  },
                ),
                const SizedBox(height: 16),
                 if (pdfUrl != null) ...[
                  const Text('PDF Uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                ],
                MediaUploader(
                  path: 'courses/$courseId/batches/$batchId/planner',
                  onUploadComplete: (url) {
                     setState(() => pdfUrl = url);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: pdfUrl == null ? null : () async {
                if (titleController.text.isEmpty) return;
                
                final item = AdminPlannerItem(
                  id: '',
                  title: titleController.text,
                  subtitle: subtitleController.text,
                  pdfUrl: pdfUrl!,
                  date: selectedDate,
                );
                
                await service.saveBatchPlannerItem(courseId, batchId, item, isNew: true);
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
