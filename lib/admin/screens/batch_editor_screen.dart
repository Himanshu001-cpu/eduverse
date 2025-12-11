import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../services/csv_importer.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/thumbnail_upload_widget.dart';

class BatchEditorScreen extends StatelessWidget {
  final String courseId;
  const BatchEditorScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'Manage Batches',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBatchDialog(context, service, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Batch'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                  onPressed: () async {
                    final batches = await CsvImporter().pickAndParseBatches(courseId);
                    for (var b in batches) {
                      await service.saveBatch(courseId, b, isNew: true);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Imported ${batches.length} batches')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AdminBatch>>(
              stream: service.getBatches(courseId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final batches = snapshot.data!;
                if (batches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No batches yet', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Tap + to add a batch', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: batches.length,
                  itemBuilder: (context, index) {
                    final batch = batches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: batch.isActive ? Colors.green : Colors.grey,
                          child: Icon(
                            batch.isActive ? Icons.check : Icons.pause,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(batch.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${batch.price.toStringAsFixed(0)} • Seats: ${batch.seatsLeft}/${batch.seatsTotal}'),
                            Text(
                              'Starts: ${batch.startDate.day}/${batch.startDate.month}/${batch.startDate.year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showBatchDialog(context, service, batch),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, service, batch),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/batch_detail',
                          arguments: {'courseId': courseId, 'batch': batch},
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
    );
  }

  void _showBatchDialog(BuildContext context, FirebaseAdminService service, AdminBatch? batch) {
    final isNew = batch == null;
    final nameController = TextEditingController(text: batch?.name ?? '');
    final priceController = TextEditingController(text: batch?.price.toString() ?? '0');
    final seatsController = TextEditingController(text: batch?.seatsTotal.toString() ?? '50');
    DateTime startDate = batch?.startDate ?? DateTime.now().add(const Duration(days: 7));
    DateTime endDate = batch?.endDate ?? DateTime.now().add(const Duration(days: 90));
    bool isActive = batch?.isActive ?? true;
    String thumbnailUrl = batch?.thumbnailUrl ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isNew ? 'Add New Batch' : 'Edit Batch'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail Upload
                  ThumbnailUploadWidget(
                    currentUrl: thumbnailUrl,
                    storagePath: 'batches/thumbnails',
                    onUploaded: (url) => setState(() => thumbnailUrl = url),
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name *',
                    hintText: 'e.g., Morning Batch A',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: seatsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Seats *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date'),
                  subtitle: Text('${endDate.day}/${endDate.month}/${endDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) setState(() => endDate = date);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Visible for purchase'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
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
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0;
                final seats = int.tryParse(seatsController.text) ?? 0;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch name is required')),
                  );
                  return;
                }

                final seatsLeft = isNew ? seats : batch.seatsLeft;
                final newBatch = AdminBatch(
                  id: batch?.id ?? '',
                  courseId: courseId,
                  name: name,
                  startDate: startDate,
                  endDate: endDate,
                  price: price,
                  seatsTotal: seats,
                  seatsLeft: seatsLeft,
                  isActive: isActive,
                  thumbnailUrl: thumbnailUrl,
                );

                try {
                  await service.saveBatch(courseId, newBatch, isNew: isNew);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isNew ? 'Batch created!' : 'Batch updated!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isNew ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirebaseAdminService service, AdminBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text('Are you sure you want to delete "${batch.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await service.deleteBatch(courseId, batch.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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
}
