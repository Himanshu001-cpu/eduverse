import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/feed/models/comment_model.dart';

class FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepo = NotificationRepository();

  Stream<List<FeedItem>> getFeedItems({ContentType? type, int? limit}) {
    Query query = _firestore
        .collection(FirestorePaths.feed)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (type != null && type != ContentType.all) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      // Map docs to FeedItem
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Debug: log quiz timer data
        if (data['type'] == 'quizzes') {
          debugPrint(
            'DEBUG FeedRepo: Quiz "${data['title']}" - Minutes: ${data['quizTimeLimitMinutes']}, Seconds: ${data['quizTimeLimitSeconds']}',
          );
        }
        // Ensure ID matches doc ID if not in data
        // data['id'] = doc.id;
        return FeedItem.fromJson(data);
      }).toList();
    });
  }

  Future<FeedItem?> getFeedItem(String id) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.feed)
          .doc(id)
          .get();
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
  Future<void> addFeedItem(
    FeedItem item, {
    bool sendNotification = true,
  }) async {
    await _firestore
        .collection(FirestorePaths.feed)
        .doc(item.id)
        .set(item.toJson());

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
        .orderBy('createdAt', descending: true)
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

  /// Increment view count for a feed item
  Future<void> incrementViewCount(String feedId) async {
    await _firestore.collection(FirestorePaths.feed).doc(feedId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// Stream to check if a user has liked a feed item
  Stream<bool> isLikedStream(String feedId, String userId) {
    return _firestore
        .collection(FirestorePaths.feed)
        .doc(feedId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Toggle like status for a user
  Future<void> toggleLike(String feedId, String userId) async {
    final feedRef = _firestore.collection(FirestorePaths.feed).doc(feedId);
    final likeRef = feedRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final feedDoc = await transaction.get(feedRef);

      if (!feedDoc.exists) return;

      if (likeDoc.exists) {
        // Unlike
        transaction.delete(likeRef);
        final currentLikes = feedDoc.data()?['likesCount'] ?? 0;
        transaction.update(feedRef, {
          'likesCount': currentLikes > 0 ? currentLikes - 1 : 0,
        });
      } else {
        // Like
        transaction.set(likeRef, {
          'createdAt': DateTime.now().toIso8601String(),
        });
        final currentLikes = feedDoc.data()?['likesCount'] ?? 0;
        transaction.update(feedRef, {'likesCount': currentLikes + 1});
      }
    });
  }

  /// Get comments stream for a feed item
  Stream<List<Comment>> getComments(String feedId) {
    return _firestore
        .collection(FirestorePaths.feed)
        .doc(feedId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Comment.fromJson(doc.data()))
              .toList();
        });
  }

  /// Add a comment
  Future<void> addComment(String feedId, Comment comment) async {
    final feedRef = _firestore.collection(FirestorePaths.feed).doc(feedId);
    final commentsRef = feedRef.collection('comments').doc(comment.id);

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentsRef, comment.toJson());
      final feedDoc = await transaction.get(feedRef);
      final currentComments = feedDoc.data()?['commentsCount'] ?? 0;
      transaction.update(feedRef, {'commentsCount': currentComments + 1});
    });
  }

  // Seeding is disabled - data is now managed via Admin Panel
  @Deprecated('Data is now managed via Admin Panel')
  Future<void> seedFeedData() async {
    // No-op: Feed items should be created via Admin Panel
    debugPrint(
      'seedFeedData is deprecated. Use Admin Panel to manage feed items.',
    );
  }

  /// Stream to check if a user has bookmarked a feed item
  Stream<bool> isBookmarkedStream(String feedId, String userId) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .collection('bookmarks')
        .doc(feedId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Toggle bookmark status for a user
  Future<void> toggleBookmark(String feedId, String userId) async {
    final bookmarkRef = _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .collection('bookmarks')
        .doc(feedId);

    final doc = await bookmarkRef.get();
    if (doc.exists) {
      await bookmarkRef.delete();
    } else {
      await bookmarkRef.set({
        'createdAt': DateTime.now().toIso8601String(),
        'feedId': feedId,
      });
    }
  }

  /// Submit an answer for answer writing
  Future<void> submitAnswer(
    String feedId,
    String userId,
    String answerText,
    int timeTakenSeconds,
  ) async {
    final answerRef = _firestore
        .collection(FirestorePaths.feed)
        .doc(feedId)
        .collection('answers')
        .doc(userId);

    await answerRef.set({
      'text': answerText,
      'timeTakenSeconds': timeTakenSeconds,
      'submittedAt': DateTime.now().toIso8601String(),
      'userId': userId,
    });
  }
}
