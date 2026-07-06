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
      // Get user's enrolled courses
      final userDoc = await _firestore
          .collection(FirestorePaths.users)
          .doc(userId)
          .get();
      
      final enrolledCourses = List<String>.from(
        userDoc.data()?['enrolledCourses'] ?? [],
      ).map((e) => e.contains('_') ? e.split('_')[0] : e).toSet();
      
      // Get user's read notifications
      final readNotifications = List<String>.from(
        userDoc.data()?['readNotifications'] ?? [],
      );

      final notifications = <UserNotification>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final notification = NotificationModel.fromJson(data);

        // Include if:
        // 1. Global notification
        // 2. Course-specific/batch-specific and user is enrolled
        if (notification.isGlobal) {
          notifications.add(UserNotification(
            notification: notification,
            isRead: readNotifications.contains(notification.id),
          ));
        } else {
          final targetId = notification.courseId ?? (notification.batchId != null && notification.batchId!.contains('_') ? notification.batchId!.split('_')[0] : notification.batchId);
          if (targetId != null && targetId.isNotEmpty) {
            final isEnrolled = enrolledCourses.contains(targetId);
            if (isEnrolled) {
              notifications.add(UserNotification(
                notification: notification,
                isRead: readNotifications.contains(notification.id),
              ));
            }
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
    String? courseId,
    String? batchId,
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
        courseId: courseId,
        batchId: batchId,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _notificationsRef.doc(id).set(notification.toJson());
      debugPrint('Created global notification: $title');
    } catch (e) {
      debugPrint('Error creating global notification: $e');
    }
  }

  /// Create a course-specific notification (for enrolled users only)
  Future<void> createCourseNotification({
    required String title,
    required String body,
    required NotificationTargetType targetType,
    required String targetId,
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
        courseId: courseId,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _notificationsRef.doc(id).set(notification.toJson());
      debugPrint('Created course notification for course $courseId: $title');
    } catch (e) {
      debugPrint('Error creating course notification: $e');
    }
  }

  /// Delete a notification globally (admin level)
  Future<void> deleteNotification(String id) async {
    try {
      await _notificationsRef.doc(id).delete();
      debugPrint('Deleted notification: $id');
    } catch (e) {
      debugPrint('Error deleting notification $id: $e');
      rethrow;
    }
  }

  /// Get all notifications globally (admin level)
  Stream<List<NotificationModel>> getAllNotifications() {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList());
  }

  /// Create notifications for multiple courses efficiently using Firestore write batch
  Future<void> createMultipleCourseNotifications({
    required String title,
    required String body,
    required NotificationTargetType targetType,
    required String targetId,
    required List<String> targetCourses,
    String? imageUrl,
  }) async {
    try {
      final writeBatch = _firestore.batch();
      for (final courseId in targetCourses) {
        if (courseId.isEmpty) continue;

        final id = _notificationsRef.doc().id;
        final notification = NotificationModel(
          id: id,
          title: title,
          body: body,
          type: NotificationType.batch,
          targetType: targetType,
          targetId: targetId,
          courseId: courseId,
          createdAt: DateTime.now(),
          imageUrl: imageUrl,
        );

        writeBatch.set(_notificationsRef.doc(id), notification.toJson());
      }
      await writeBatch.commit();
      debugPrint('Created notifications for ${targetCourses.length} courses: $title');
    } catch (e) {
      debugPrint('Error creating multiple course notifications: $e');
      rethrow;
    }
  }
}
