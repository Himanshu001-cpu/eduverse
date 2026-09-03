import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_scaffold.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/link_live_class_dialog.dart';
import '../widgets/manage_linked_courses_dialog.dart';

class LiveClassesScreen extends StatelessWidget {
  final String? courseId;
  
  const LiveClassesScreen({super.key, this.courseId, String? batchId});

  @override
  Widget build(BuildContext context) {
    // Get service reference before any async operations
    final adminService = context.read<FirebaseAdminService>();
    final isCourseScoped = courseId != null && courseId!.isNotEmpty;
    
    return AdminScaffold(
      title: isCourseScoped ? 'Course Schedule' : 'Free Live Classes',
      floatingActionButton: isCourseScoped
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Link existing class button
                FloatingActionButton.small(
                  heroTag: 'link_class',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => Provider<FirebaseAdminService>.value(
                        value: adminService,
                        child: LinkLiveClassDialog(
                          targetCourseId: courseId!,
                        ),
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
                }
              ),
              child: const Icon(Icons.add),
            ),
      body: StreamBuilder<List<AdminLiveClass>>(
        stream: isCourseScoped
            ? adminService.getCourseLiveClasses(courseId!)
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
                  if (isCourseScoped) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => Provider<FirebaseAdminService>.value(
                            value: adminService,
                            child: LinkLiveClassDialog(
                              targetCourseId: courseId!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_link, size: 18),
                      label: const Text('Link from another course'),
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
              final hasLinks = item.linkedCourses.isNotEmpty;

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
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMM dd, yyyy HH:mm').format(item.startTime),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              // Linked courses indicator
                              if (hasLinks) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.link, size: 14, color: Colors.blue[400]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Linked to ${item.linkedCourses.length} course${item.linkedCourses.length > 1 ? "s" : ""}',
                                        style: TextStyle(color: Colors.blue[400], fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                if (item.linkedCourses.isNotEmpty) ...[
                                  IconButton(
                                    icon: const Icon(Icons.hub, size: 20, color: Colors.teal),
                                    tooltip: 'Manage Linked Courses (Bulk & Single)',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => Provider<FirebaseAdminService>.value(
                                          value: adminService,
                                          child: ManageLinkedCoursesDialog(
                                            liveClass: item,
                                            sourceCourseId: courseId ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                ] else if (hasLinks) ...[
                                  IconButton(
                                    icon: const Icon(Icons.sync, size: 20, color: Colors.teal),
                                    tooltip: 'Sync to All Linked Courses',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _confirmAndSyncLiveClass(context, adminService, item),
                                  ),
                                  const SizedBox(width: 4),
                                ],
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

  Future<void> _confirmAndSyncLiveClass(
    BuildContext context,
    FirebaseAdminService service,
    AdminLiveClass liveClass,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Live Class to Linked Courses?'),
        content: Text(
          'This will update details for "${liveClass.title}" in all other courses where this live class is shared/linked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final updatedCount = await service.syncLiveClassToLinkedCourses(
        sourceCourseId: courseId ?? '',
        liveClass: liveClass,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully synced live class across $updatedCount location(s)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync live class: $e')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, FirebaseAdminService adminService, AdminLiveClass item) {
    final isLinked = item.linkedFrom != null || item.linkedCourses.isNotEmpty;

    if (!isLinked) {
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  if (courseId != null && courseId!.isNotEmpty) {
                    await adminService.deleteCourseLiveClass(courseId!, item.id);
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
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Class is linked - show choice dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Linked Live Class Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${item.title}" is linked to other courses.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose what you would like to do:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔗 Delink', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 2),
                  Text(
                    'Removes sync connection. The class stays in this course as an independent copy.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🗑️ Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 2),
                  Text(
                    'Warning: Permanently removes the live class from this course.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.link_off, size: 16),
            label: const Text('Delink'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                if (courseId != null && courseId!.isNotEmpty) {
                  await adminService.delinkLiveClass(courseId!, item.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live class delinked successfully (now independent)')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error delinking: $e')),
                  );
                }
              }
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                if (courseId != null && courseId!.isNotEmpty) {
                  await adminService.deleteCourseLiveClass(courseId!, item.id, deleteAllLinked: false);
                } else {
                  await adminService.deleteLiveClass(item.id, deleteAllLinked: false);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from this course successfully')),
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
          ),
        ],
      ),
    );
  }
}
