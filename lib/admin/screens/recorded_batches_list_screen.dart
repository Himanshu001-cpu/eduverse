import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';

class RecordedBatchesListScreen extends StatefulWidget {
  final String courseId;

  const RecordedBatchesListScreen({super.key, required this.courseId});

  @override
  State<RecordedBatchesListScreen> createState() => _RecordedBatchesListScreenState();
}

class _RecordedBatchesListScreenState extends State<RecordedBatchesListScreen> {
  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();

    return AdminScaffold(
      title: 'Recorded Batches',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBatchDialog(context, service),
        icon: const Icon(Icons.add),
        label: const Text('Add Recorded Batch'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AdminRecordedBatch>>(
        stream: service.getRecordedBatches(widget.courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final batches = snapshot.data ?? [];

          if (batches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No recorded batches created yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Add Recorded Batch" to create a recorded-only batch for this course.',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              return _buildBatchCard(context, service, batch);
            },
          );
        },
      ),
    );
  }

  Widget _buildBatchCard(BuildContext context, FirebaseAdminService service, AdminRecordedBatch batch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Open lecture editor scoped to this recorded batch
          Navigator.pushNamed(
            context,
            '/lecture_editor',
            arguments: {
              'courseId': widget.courseId,
              'batchId': batch.id,
              'isRecordedBatch': true,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_library, color: Colors.teal, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                batch.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: batch.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                batch.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: batch.isActive ? Colors.green.shade700 : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (batch.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            batch.description,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: batch.isFreeForEnrolled ? Colors.blue.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      batch.isFreeForEnrolled ? 'Free for Enrolled Students' : 'Standalone (₹${batch.finalPrice})',
                      style: TextStyle(
                        fontSize: 12,
                        color: batch.isFreeForEnrolled ? Colors.blue.shade800 : Colors.purple.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.folder_open, color: Colors.teal),
                    tooltip: 'Manage Content',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/lecture_editor',
                        arguments: {
                          'courseId': widget.courseId,
                          'batchId': batch.id,
                          'isRecordedBatch': true,
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.indigo),
                    tooltip: 'Edit Batch Details',
                    onPressed: () => _showBatchDialog(context, service, batch: batch),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Batch',
                    onPressed: () => _showDeleteConfirmation(context, service, batch),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBatchDialog(BuildContext context, FirebaseAdminService service, {AdminRecordedBatch? batch}) {
    final isEditing = batch != null;
    final titleController = TextEditingController(text: batch?.title ?? '');
    final descriptionController = TextEditingController(text: batch?.description ?? '');
    final thumbnailController = TextEditingController(text: batch?.thumbnailUrl ?? '');
    final realPriceController = TextEditingController(text: (batch?.realPrice ?? 0.0).toString());
    final finalPriceController = TextEditingController(text: (batch?.finalPrice ?? 0.0).toString());
    bool isFreeForEnrolled = batch?.isFreeForEnrolled ?? true;
    bool isActive = batch?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Recorded Batch' : 'Create Recorded Batch'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g. Complete Recorded Batch 2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief summary of what this recorded batch covers...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: thumbnailController,
                        decoration: const InputDecoration(
                          labelText: 'Thumbnail Image URL',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Free for Enrolled Students'),
                        subtitle: const Text('Students enrolled in parent course get free access'),
                        value: isFreeForEnrolled,
                        onChanged: (val) => setStateDialog(() => isFreeForEnrolled = val),
                        activeThumbColor: Colors.teal,
                      ),
                      if (!isFreeForEnrolled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: realPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Real Price (₹)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: finalPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Final Price (₹)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Visible to students'),
                        value: isActive,
                        onChanged: (val) => setStateDialog(() => isActive = val),
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title is required')),
                      );
                      return;
                    }

                    final updatedBatch = AdminRecordedBatch(
                      id: batch?.id ?? '',
                      courseId: widget.courseId,
                      title: title,
                      description: descriptionController.text.trim(),
                      thumbnailUrl: thumbnailController.text.trim(),
                      realPrice: double.tryParse(realPriceController.text) ?? 0.0,
                      finalPrice: double.tryParse(finalPriceController.text) ?? 0.0,
                      isFreeForEnrolled: isFreeForEnrolled,
                      isActive: isActive,
                      createdAt: batch?.createdAt ?? DateTime.now(),
                    );

                    try {
                      await service.saveRecordedBatch(
                        widget.courseId,
                        updatedBatch,
                        isNew: !isEditing,
                      );
                      if (context.mounted) Navigator.pop(dialogCtx);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving recorded batch: $e')),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, FirebaseAdminService service, AdminRecordedBatch batch) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Recorded Batch'),
        content: Text('Are you sure you want to delete "${batch.title}"? All lessons, notes, DPPs, and quizzes inside this batch will also be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await service.deleteRecordedBatch(widget.courseId, batch.id);
                if (context.mounted) Navigator.pop(dialogCtx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting batch: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
