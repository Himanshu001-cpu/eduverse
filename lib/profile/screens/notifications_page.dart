import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/profile/profile_mock_data.dart';
import 'package:eduverse/common/widgets/empty_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotificationItem> _notifications = ProfileMockData.notifications;

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    _updateUnreadCount();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _updateUnreadCount() {
    final count = _notifications.where((n) => !n.isRead).length;
    ProfileMockData.unreadNotificationCount.value = count;
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    _updateUnreadCount();
  }

  void _toggleRead(int index) {
    setState(() {
      _notifications[index].isRead = !_notifications[index].isRead;
    });
    _updateUnreadCount();
  }

  void _showOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(_notifications[index].isRead ? Icons.mark_email_unread : Icons.mark_email_read),
            title: Text(_notifications[index].isRead ? 'Mark as Unread' : 'Mark as Read'),
            onTap: () {
              Navigator.pop(ctx);
              _toggleRead(index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(ctx);
              _deleteNotification(index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off),
            title: const Text('Mute similar notifications'),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Muted similar notifications')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const EmptyState(title: 'No notifications', icon: Icons.notifications_none)
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return Dismissible(
                  key: Key(item.id),
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (_) => _deleteNotification(index),
                  child: Container(
                    color: item.isRead ? null : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    child: ListTile(
                      onLongPress: () => _showOptions(index),
                      leading: CircleAvatar(
                        backgroundColor: _getIconColor(item.type).withValues(alpha: 0.1),
                        child: Icon(_getIcon(item.type), color: _getIconColor(item.type), size: 20),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, h:mm a').format(item.timestamp),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: item.isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.promo: return Icons.local_offer;
      case NotificationType.reminder: return Icons.alarm;
      case NotificationType.system: return Icons.info;
      case NotificationType.courseUpdate: return Icons.update;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.promo: return Colors.purple;
      case NotificationType.reminder: return Colors.orange;
      case NotificationType.system: return Colors.blue;
      case NotificationType.courseUpdate: return Colors.green;
    }
  }
}
