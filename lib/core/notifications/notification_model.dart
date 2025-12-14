import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of notifications
enum NotificationType {
  feed,    // New feed item (global to all users)
  batch,   // Batch-specific content (enrolled users only)
  system,  // System notifications
}

/// What the notification links to
enum NotificationTargetType {
  feedItem,
  liveClass,
  lecture,
  quiz,
  batch,
  course,
}

/// Notification model for in-app and push notifications
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationTargetType targetType;
  final String targetId;
  final String? batchId; // Null for global notifications
  final String? courseId;
  final DateTime createdAt;
  final String? imageUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetType,
    required this.targetId,
    this.batchId,
    this.courseId,
    required this.createdAt,
    this.imageUrl,
  });

  /// Check if this is a global notification (for all users)
  bool get isGlobal => batchId == null;

  /// Create from Firestore document
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      targetType: NotificationTargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
        orElse: () => NotificationTargetType.feedItem,
      ),
      targetId: json['targetId'] ?? '',
      batchId: json['batchId'],
      courseId: json['courseId'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'targetType': targetType.name,
      'targetId': targetId,
      'batchId': batchId,
      'courseId': courseId,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationTargetType? targetType,
    String? targetId,
    String? batchId,
    String? courseId,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      batchId: batchId ?? this.batchId,
      courseId: courseId ?? this.courseId,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// User's notification with read status
class UserNotification {
  final NotificationModel notification;
  final bool isRead;

  const UserNotification({
    required this.notification,
    this.isRead = false,
  });
}
