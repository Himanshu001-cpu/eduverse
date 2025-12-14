import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/feed_data.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import 'package:eduverse/core/notifications/notification_model.dart';

class FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepo = NotificationRepository();

  Stream<List<FeedItem>> getFeedItems({ContentType? type, int limit = 20}) {
    Query query = _firestore.collection(FirestorePaths.feed)
        .where('isPublic', isEqualTo: true)
        .orderBy('id'); 
    // Ideally orderBy 'createdAt' or 'publishedDate', but FeedItem uses 'id' currently as primary sorting unique.
    // We should probably add 'publishedDate' to FeedItem for real sorting. 
    // consistent ordering is needed. 'id' is distinct.

    if (type != null && type != ContentType.all) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      // Map docs to FeedItem
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure ID matches doc ID if not in data
        // data['id'] = doc.id; 
        return FeedItem.fromJson(data);
      }).toList();
    });
  }

  Future<FeedItem?> getFeedItem(String id) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.feed).doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      
      final data = doc.data()!;
      // Ensure ID is present for fromJson
      data['id'] = doc.id;
      
      return FeedItem.fromJson(data);
    } catch (e) {
      debugPrint('Error getting feed item $id: $e');
      return null;
    }
  }

  /// Add a new feed item and create a notification for all users
  Future<void> addFeedItem(FeedItem item, {bool sendNotification = true}) async {
    await _firestore.collection(FirestorePaths.feed).doc(item.id).set(item.toJson());
    
    // Create a global notification for all users
    if (sendNotification && item.isPublic) {
      await _notificationRepo.createGlobalNotification(
        title: _getNotificationTitle(item.type),
        body: item.title,
        targetType: NotificationTargetType.feedItem,
        targetId: item.id,
        imageUrl: item.thumbnailUrl,
      );
    }
  }

  /// Get notification title based on content type
  String _getNotificationTitle(ContentType type) {
    switch (type) {
      case ContentType.currentAffairs:
        return '📰 New Current Affairs';
      case ContentType.answerWriting:
        return '✍️ New Answer Writing Practice';
      case ContentType.articles:
        return '📝 New Article';
      case ContentType.videos:
        return '🎬 New Video';
      case ContentType.quizzes:
        return '🧠 New Quiz';
      case ContentType.jobs:
        return '💼 New Job Alert';
      default:
        return '🆕 New Content';
    }
  }

  /// Stream all feed items (for admin - no isPublic filter)
  Stream<List<FeedItem>> getAllFeedItems() {
    return _firestore
        .collection(FirestorePaths.feed)
        .orderBy('id')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FeedItem.fromJson(data);
      }).toList();
    });
  }

  /// Update an existing feed item
  Future<void> updateFeedItem(FeedItem item) async {
    await _firestore
        .collection(FirestorePaths.feed)
        .doc(item.id)
        .update(item.toJson());
  }

  /// Delete a feed item
  Future<void> deleteFeedItem(String id) async {
    await _firestore.collection(FirestorePaths.feed).doc(id).delete();
  }

  // Seeding is disabled - data is now managed via Admin Panel
  @Deprecated('Data is now managed via Admin Panel')
  Future<void> seedFeedData() async {
    // No-op: Feed items should be created via Admin Panel
    debugPrint('seedFeedData is deprecated. Use Admin Panel to manage feed items.');
  }
}
