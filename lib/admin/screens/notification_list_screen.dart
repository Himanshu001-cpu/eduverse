import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import '../widgets/admin_scaffold.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationRepository _repository = NotificationRepository();
  NotificationType? _filterType;
  String _searchQuery = '';

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Notifications Management',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/notification_editor'),
        icon: const Icon(Icons.add_alert),
        label: const Text('Create Notification'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by title or body...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 30, child: VerticalDivider()),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<NotificationType?>(
                        initialValue: _filterType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'All Types',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...NotificationType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _filterType = val;
                          });
                        },
                      ),
                    ),
                    if (_filterType != null || _searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Clear Filters',
                        onPressed: _clearFilters,
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // List of Notifications
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _repository.getAllNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                var items = snapshot.data ?? [];

                // Filter items
                if (_filterType != null) {
                  items = items.where((item) => item.type == _filterType).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  items = items.where((item) {
                    return item.title.toLowerCase().contains(query) ||
                        item.body.toLowerCase().contains(query);
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications found',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(item.createdAt);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Notification Image (if available)
                            if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            // Notification Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Type Tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.type == NotificationType.feed
                                              ? Colors.blue.shade50
                                              : item.type == NotificationType.batch
                                                  ? Colors.green.shade50
                                                  : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.type == NotificationType.feed
                                              ? 'GLOBAL'
                                              : item.type == NotificationType.batch
                                                  ? 'BATCH-SPECIFIC'
                                                  : 'SYSTEM',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.type == NotificationType.feed
                                                ? Colors.blue.shade800
                                                : item.type == NotificationType.batch
                                                    ? Colors.green.shade800
                                                    : Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 12),
                                  // Targeting Meta info
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (item.courseId != null)
                                        _buildMetaChip(Icons.book_outlined, 'Course ID: ${item.courseId}'),
                                      if (item.batchId != null)
                                        _buildMetaChip(Icons.group_outlined, 'Batch ID: ${item.batchId}'),
                                      if (item.targetType != NotificationTargetType.feedItem || item.targetId.isNotEmpty)
                                        _buildMetaChip(
                                          Icons.link_outlined,
                                          'Links to: ${item.targetType.name} (${item.targetId.isEmpty ? "None" : item.targetId})',
                                        ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, item),
                            ),
                          ],
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

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label.length > 30 ? '${label.substring(0, 27)}...' : label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, NotificationModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification ("${item.title}")? This will remove it from all student feeds.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repository.deleteNotification(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${item.title}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
