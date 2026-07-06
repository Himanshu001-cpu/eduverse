import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/community_models.dart';

class CommunityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of communities linked to a course
  Stream<List<StudentCommunity>> getCommunitiesForCourse(String courseId) {
    return _db
        .collection('communities')
        .where('courseIds', arrayContains: courseId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StudentCommunity.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Stream of posts in a community (ordered by pinned first, then newest)
  Stream<List<StudentPost>> getPostsForCommunity(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StudentPost.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Stream of a single post
  Stream<StudentPost?> getPostById(String communityId, String postId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return StudentPost.fromMap(doc.data()!, doc.id);
        });
  }

  // Stream of replies for a post
  Stream<List<StudentReply>> getRepliesForPost(String communityId, String postId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StudentReply.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Student creates a new post
  Future<void> createPost({
    required String communityId,
    required String title,
    required String body,
    required String authorId,
    required String authorName,
    required String authorRole,
  }) async {
    final batch = _db.batch();

    final postRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc();

    final communityRef = _db.collection('communities').doc(communityId);

    final newPost = StudentPost(
      id: postRef.id,
      title: title,
      body: body,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      isAnswered: false,
      isPinned: false,
      replyCount: 0,
      createdAt: DateTime.now(),
    );

    batch.set(postRef, newPost.toMap());
    batch.update(communityRef, {
      'postCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Student creates a new reply
  Future<void> createReply({
    required String communityId,
    required String postId,
    required String body,
    required String authorId,
    required String authorName,
    required String authorRole,
    required bool isTeacherReply,
  }) async {
    final batch = _db.batch();

    final replyRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .collection('replies')
        .doc();

    final postRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId);

    final newReply = StudentReply(
      id: replyRef.id,
      body: body,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      isTeacherReply: isTeacherReply,
      createdAt: DateTime.now(),
    );

    batch.set(replyRef, newReply.toMap());

    final Map<String, dynamic> postUpdates = {
      'replyCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Automatically mark as answered if a teacher replies
    if (isTeacherReply) {
      postUpdates['isAnswered'] = true;
    }

    batch.update(postRef, postUpdates);

    await batch.commit();
  }

  // Student deletes their own post
  Future<void> deleteOwnPost(String communityId, String postId) async {
    final batch = _db.batch();

    final postRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId);

    final communityRef = _db.collection('communities').doc(communityId);

    // Clean up replies
    final repliesQuery = await postRef.collection('replies').get();
    for (var doc in repliesQuery.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(postRef);
    batch.update(communityRef, {
      'postCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
