import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/common/widgets/empty_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationRepository _notificationRepo = NotificationRepository();

  void _markAllRead(List<UserNotification> notifications) async {
    final unreadIds = notifications
        .where((n) => !n.isRead)
        .map((n) => n.notification.id)
        .toList();
    
    if (unreadIds.isEmpty) return;

    await _notificationRepo.markAllAsRead(unreadIds);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  void _deleteNotification(String notificationId) async {
    await _notificationRepo.deleteForUser(notificationId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification removed')),
      );
    }
  }

  void _toggleRead(UserNotification item) async {
    if (!item.isRead) {
      await _notificationRepo.markAsRead(item.notification.id);
    }
  }

  void _showOptions(UserNotification item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(item.isRead ? Icons.mark_email_unread : Icons.mark_email_read),
            title: Text(item.isRead ? 'Mark as Unread' : 'Mark as Read'),
            onTap: () {
              Navigator.pop(ctx);
              _toggleRead(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(ctx);
              _deleteNotification(item.notification.id);
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
          StreamBuilder<List<UserNotification>>(
            stream: _notificationRepo.getUserNotifications(),
            builder: (context, snapshot) {
              return TextButton(
                onPressed: snapshot.hasData ? () => _markAllRead(snapshot.data!) : null,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<UserNotification>>(
        stream: _notificationRepo.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const EmptyState(
              title: 'No notifications',
              icon: Icons.notifications_none,
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final notification = item.notification;
              
              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteNotification(notification.id),
                child: Container(
                  color: item.isRead
                      ? null
                      : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  child: ListTile(
                    onTap: () => _toggleRead(item),
                    onLongPress: () => _showOptions(item),
                    leading: CircleAvatar(
                      backgroundColor: _getIconColor(notification.type).withValues(alpha: 0.1),
                      child: Icon(
                        _getIcon(notification.type),
                        color: _getIconColor(notification.type),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(notification.createdAt),
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
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.feed:
        return Icons.article;
      case NotificationType.batch:
        return Icons.school;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.feed:
        return Colors.blue;
      case NotificationType.batch:
        return Colors.green;
      case NotificationType.system:
        return Colors.orange;
    }
  }
}
