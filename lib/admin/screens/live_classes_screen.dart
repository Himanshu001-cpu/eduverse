import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_scaffold.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';

class LiveClassesScreen extends StatelessWidget {
  final String? courseId;
  final String? batchId;
  
  const LiveClassesScreen({super.key, this.courseId, this.batchId});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: batchId != null ? 'Batch Schedule' : 'Free Live Classes',
      floatingActionButton: FloatingActionButton(
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
        stream: batchId != null && courseId != null
            ? context.read<FirebaseAdminService>().getBatchLiveClasses(courseId!, batchId!)
            : context.read<FirebaseAdminService>().getLiveClasses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data!;

          if (classes.isEmpty) {
            return const Center(child: Text('No classes scheduled'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final item = classes[index];
              final isLive = item.status == 'live';
              final isCompleted = item.status == 'completed';

              return Card(
                elevation: isLive ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 16),
                shape: isLive 
                  ? RoundedRectangleBorder(side: const BorderSide(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(12))
                  : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: item.thumbnailUrl.isNotEmpty ? NetworkImage(item.thumbnailUrl) : null,
                    child: item.thumbnailUrl.isEmpty ? const Icon(Icons.video_camera_front) : null,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.durationMinutes} min'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM dd, yyyy HH:mm').format(item.startTime)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            color: isLive ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: isLive 
                            ? Colors.red 
                            : isCompleted ? Colors.grey[300] : Colors.blue[100],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit),
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
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, item),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.pushNamed(
                    context, 
                    '/live_class_editor', 
                    arguments: {
                      'item': item,
                      'courseId': courseId,
                      'batchId': batchId,
                    }
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminLiveClass item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (batchId != null && courseId != null) {
                await context.read<FirebaseAdminService>().deleteBatchLiveClass(courseId!, batchId!, item.id);
              } else {
                await context.read<FirebaseAdminService>().deleteLiveClass(item.id);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
