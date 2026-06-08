import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/common/widgets/empty_state.dart';
import 'package:eduverse/core/services/deep_link_screens.dart';

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

          final rawNotifications = snapshot.data ?? [];

          // Client-side deduplication filter
          final notifications = <UserNotification>[];
          final seenKeys = <String>{};

          for (final item in rawNotifications) {
            final n = item.notification;
            final key = '${n.title}_${n.body}_${n.imageUrl ?? ""}';
            if (!seenKeys.contains(key)) {
              seenKeys.add(key);
              notifications.add(item);
            }
          }

          if (notifications.isEmpty) {
            return const EmptyState(
              title: 'No notifications',
              icon: Icons.notifications_none,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Card(
                    elevation: item.isRead ? 0.5 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: item.isRead
                            ? Colors.grey.shade200
                            : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    color: item.isRead ? Colors.white : Theme.of(context).primaryColor.withValues(alpha: 0.01),
                    child: InkWell(
                      onTap: () => _handleNotificationTap(item),
                      onLongPress: () => _showOptions(item),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _getIconColor(notification.type).withValues(alpha: 0.1),
                                  child: Icon(
                                    _getIcon(notification.type),
                                    color: _getIconColor(notification.type),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(notification.createdAt),
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    notification.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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

  void _handleNotificationTap(UserNotification item) {
    // 1. Mark as read
    _toggleRead(item);

    final n = item.notification;

    // 2. Navigate based on target type
    switch (n.targetType) {
      case NotificationTargetType.feedItem:
      case NotificationTargetType.quiz: // Assumes global quiz
        // Open DeepLinkFeedScreen to fetch and show the item
        if (n.targetId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeepLinkFeedScreen(feedId: n.targetId),
            ),
          );
        }
        break;

      case NotificationTargetType.course:
        if (n.targetId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeepLinkCourseScreen(courseId: n.targetId),
            ),
          );
        }
        break;

      case NotificationTargetType.batch:
        if (n.courseId != null && n.targetId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeepLinkBatchScreen(
                courseId: n.courseId!,
                batchId: n.targetId,
              ),
            ),
          );
        } else {
          _showErrorSnackBar('Missing course information for this batch');
        }
        break;

      case NotificationTargetType.liveClass:
      case NotificationTargetType.lecture:
        // These are inside a batch, so we navigate to the batch page
        // Ideally, we could pass an extra argument to highlight the specific lesson
        if (n.courseId != null && n.batchId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeepLinkBatchScreen(
                courseId: n.courseId!,
                batchId: n.batchId!,
              ),
            ),
          );
        } else {
          _showErrorSnackBar('Missing batch information for this content');
        }
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
