import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_scaffold.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/link_live_class_dialog.dart';

class LiveClassesScreen extends StatelessWidget {
  final String? courseId;
  final String? batchId;
  
  const LiveClassesScreen({super.key, this.courseId, this.batchId});

  @override
  Widget build(BuildContext context) {
    // Get service reference before any async operations
    final adminService = context.read<FirebaseAdminService>();
    final isBatchScoped = batchId != null && courseId != null;
    
    return AdminScaffold(
      title: isBatchScoped ? 'Batch Schedule' : 'Free Live Classes',
      floatingActionButton: isBatchScoped
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Link existing class button
                FloatingActionButton.small(
                  heroTag: 'link_class',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => LinkLiveClassDialog(
                        targetCourseId: courseId!,
                        targetBatchId: batchId!,
                      ),
                    );
                  },
                  tooltip: 'Link Existing Class',
                  backgroundColor: Colors.deepPurple,
                  child: const Icon(Icons.add_link, size: 20),
                ),
                const SizedBox(height: 12),
                // Create new class button
                FloatingActionButton(
                  heroTag: 'add_class',
                  onPressed: () => Navigator.pushNamed(
                    context, 
                    '/live_class_editor', 
                    arguments: {
                      'courseId': courseId,
                      'batchId': batchId,
                    }
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : FloatingActionButton(
              onPressed: () => Navigator.pushNamed(
                context, 
                '/live_class_editor', 
                arguments: {
                  'courseId': courseId,
                  'batchId': batchId,
                }
              ),
              child: const Icon(Icons.add),
            ),
      body: StreamBuilder<List<AdminLiveClass>>(
        stream: isBatchScoped
            ? adminService.getBatchLiveClasses(courseId!, batchId!)
            : adminService.getLiveClasses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data!;

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_camera_front_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No classes scheduled'),
                  if (isBatchScoped) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => LinkLiveClassDialog(
                            targetCourseId: courseId!,
                            targetBatchId: batchId!,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_link, size: 18),
                      label: const Text('Link from another batch'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final item = classes[index];
              final isLive = item.status == 'live';
              final isCompleted = item.status == 'completed';
              final hasLinks = item.linkedBatches.isNotEmpty;

              return Card(
                elevation: isLive ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 16),
                shape: isLive 
                  ? RoundedRectangleBorder(side: const BorderSide(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(12))
                  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pushNamed(
                    context, 
                    '/live_class_editor', 
                    arguments: {
                      'item': item,
                      'courseId': courseId,
                      'batchId': batchId,
                    }
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: item.thumbnailUrl.isNotEmpty ? NetworkImage(item.thumbnailUrl) : null,
                          child: item.thumbnailUrl.isEmpty ? const Icon(Icons.video_camera_front) : null,
                        ),
                        const SizedBox(width: 12),
                        // Title and info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.durationMinutes} min',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(item.startTime),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                              // Linked batches indicator
                              if (hasLinks) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.link, size: 14, color: Colors.blue[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Linked to ${item.linkedBatches.length} batch${item.linkedBatches.length > 1 ? "es" : ""}',
                                      style: TextStyle(color: Colors.blue[400], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status chip and actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Chip(
                              label: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  color: isLive ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              backgroundColor: isLive 
                                  ? Colors.red 
                                  : isCompleted ? Colors.grey[300] : Colors.blue[100],
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () => Navigator.pushNamed(
                                    context, 
                                    '/live_class_editor', 
                                    arguments: {
                                      'item': item,
                                      'courseId': courseId,
                                      'batchId': batchId,
                                    }
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () => _confirmDelete(context, adminService, item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirebaseAdminService adminService, AdminLiveClass item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Class?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                if (batchId != null && courseId != null) {
                  await adminService.deleteBatchLiveClass(courseId!, batchId!, item.id);
                } else {
                  await adminService.deleteLiveClass(item.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

