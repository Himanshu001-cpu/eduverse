import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';
import 'package:eduverse/core/notifications/notification_model.dart';

/// Repository for notification Firestore operations
class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection(FirestorePaths.notifications);

  /// Get notifications for current user
  /// Returns global notifications + batch-specific notifications for enrolled batches
  Stream<List<UserNotification>> getUserNotifications() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      // Get user's enrolled batches
      final userDoc = await _firestore
          .collection(FirestorePaths.users)
          .doc(userId)
          .get();
      
      final enrolledCourses = List<String>.from(
        userDoc.data()?['enrolledCourses'] ?? [],
      );
      
      // Get user's read notifications
      final readNotifications = List<String>.from(
        userDoc.data()?['readNotifications'] ?? [],
      );

      final notifications = <UserNotification>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final notification = NotificationModel.fromJson(data);

        // Include if:
        // 1. Global notification (batchId is null)
        // 2. Batch-specific and user is enrolled
        if (notification.isGlobal) {
          notifications.add(UserNotification(
            notification: notification,
            isRead: readNotifications.contains(notification.id),
          ));
        } else if (notification.batchId != null) {
          // Check if user is enrolled in this batch
          // enrolledCourses format is typically "courseId_batchId"
          final isEnrolled = enrolledCourses.any((enrollment) =>
              enrollment.contains(notification.batchId!));
          
          if (isEnrolled) {
            notifications.add(UserNotification(
              notification: notification,
              isRead: readNotifications.contains(notification.id),
            ));
          }
        }
      }

      return notifications;
    });
  }

  /// Get unread notification count for current user
  Stream<int> getUnreadCount() {
    return getUserNotifications().map((notifications) =>
        notifications.where((n) => !n.isRead).length);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _userId;
    if (userId == null) return;

    await _firestore.collection(FirestorePaths.users).doc(userId).update({
      'readNotifications': FieldValue.arrayUnion([notificationId]),
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(List<String> notificationIds) async {
    final userId = _userId;
    if (userId == null) return;

    await _firestore.collection(FirestorePaths.users).doc(userId).update({
      'readNotifications': FieldValue.arrayUnion(notificationIds),
    });
  }

  /// Delete a notification for user (removes from read list, notification stays)
  Future<void> deleteForUser(String notificationId) async {
    final userId = _userId;
    if (userId == null) return;

    // Add to user's deleted notifications list
    await _firestore.collection(FirestorePaths.users).doc(userId).update({
      'deletedNotifications': FieldValue.arrayUnion([notificationId]),
    });
  }

  /// Create a global notification (for all users) - typically for new feed items
  Future<void> createGlobalNotification({
    required String title,
    required String body,
    required NotificationTargetType targetType,
    required String targetId,
    String? imageUrl,
  }) async {
    try {
      final id = _firestore.collection(FirestorePaths.notifications).doc().id;
      
      final notification = NotificationModel(
        id: id,
        title: title,
        body: body,
        type: NotificationType.feed,
        targetType: targetType,
        targetId: targetId,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _notificationsRef.doc(id).set(notification.toJson());
      debugPrint('Created global notification: $title');
    } catch (e) {
      debugPrint('Error creating global notification: $e');
    }
  }

  /// Create a batch-specific notification (for enrolled users only)
  Future<void> createBatchNotification({
    required String title,
    required String body,
    required NotificationTargetType targetType,
    required String targetId,
    required String batchId,
    required String courseId,
    String? imageUrl,
  }) async {
    try {
      final id = _firestore.collection(FirestorePaths.notifications).doc().id;
      
      final notification = NotificationModel(
        id: id,
        title: title,
        body: body,
        type: NotificationType.batch,
        targetType: targetType,
        targetId: targetId,
        batchId: batchId,
        courseId: courseId,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _notificationsRef.doc(id).set(notification.toJson());
      debugPrint('Created batch notification for batch $batchId: $title');
    } catch (e) {
      debugPrint('Error creating batch notification: $e');
    }
  }
}
