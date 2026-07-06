import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_models.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ensure only one community per (teacher, subject) exists, merge courseIds
  Future<Community> getOrCreateCommunity({
    required String teacherId,
    required String teacherName,
    required String subjectName,
    required List<String> courseIds,
  }) async {
    final query = await _db
        .collection('communities')
        .where('teacherId', isEqualTo: teacherId)
        .where('subjectName', isEqualTo: subjectName)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final existing = Community.fromMap(doc.data(), doc.id);
      
      // Merge courseIds
      final mergedCourseIds = <String>{...existing.courseIds, ...courseIds}.toList();
      
      await doc.reference.update({
        'courseIds': mergedCourseIds,
        'teacherName': teacherName, // Update in case teacher name changed
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return existing.copyWith(
        courseIds: mergedCourseIds,
        teacherName: teacherName,
        updatedAt: DateTime.now(),
      );
    } else {
      // Create new community
      final docRef = _db.collection('communities').doc();
      final newCommunity = Community(
        id: docRef.id,
        teacherId: teacherId,
        teacherName: teacherName,
        subjectName: subjectName,
        description: 'Community for $subjectName discussions with $teacherName',
        courseIds: courseIds,
        memberCount: 0,
        postCount: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(newCommunity.toMap());
      return newCommunity;
    }
  }

  // Get all communities stream
  Stream<List<Community>> getCommunities() {
    return _db
        .collection('communities')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Community.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get communities for a course
  Stream<List<Community>> getCommunitiesForCourse(String courseId) {
    return _db
        .collection('communities')
        .where('courseIds', arrayContains: courseId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Community.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get communities for a teacher
  Stream<List<Community>> getCommunitiesForTeacher(String teacherId) {
    return _db
        .collection('communities')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Community.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Update community description
  Future<void> updateCommunityDescription(String communityId, String description) async {
    await _db.collection('communities').doc(communityId).update({
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle active status
  Future<void> toggleCommunityActiveStatus(String communityId, bool isActive) async {
    await _db.collection('communities').doc(communityId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ POSTS MANAGEMENT ============

  // Get posts stream for community (ordered by pinned first, then newest)
  Stream<List<CommunityPost>> getPostsForCommunity(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommunityPost.fromMap(doc.data(), doc.id, communityId))
              .toList();
        });
  }

  // Get single post stream
  Stream<CommunityPost?> getPostById(String communityId, String postId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return CommunityPost.fromMap(doc.data()!, doc.id, communityId);
        });
  }

  // Create post
  Future<void> createPost(String communityId, CommunityPost post) async {
    final batch = _db.batch();
    
    final postRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc();
        
    final communityRef = _db.collection('communities').doc(communityId);
    
    batch.set(postRef, post.toMap());
    batch.update(communityRef, {
      'postCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  // Delete post
  Future<void> deletePost(String communityId, String postId) async {
    final batch = _db.batch();
    
    final postRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId);
        
    final communityRef = _db.collection('communities').doc(communityId);
    
    // Note: In Firestore, deleting a document doesn't delete its subcollections.
    // However, for simplicity here we delete the post doc. The subcollection replies will remain orphaned
    // but in a production environment we'd clean them up. We will do a batch delete for the replies we can fetch.
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

  // Pin / Unpin post
  Future<void> pinPost(String communityId, String postId, bool isPinned) async {
    await _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .update({
          'isPinned': isPinned,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Mark answered
  Future<void> markPostAnswered(String communityId, String postId, bool isAnswered) async {
    await _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .update({
          'isAnswered': isAnswered,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // ============ REPLIES MANAGEMENT ============

  // Get replies for a post
  Stream<List<CommunityReply>> getRepliesForPost(String communityId, String postId) {
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
              .map((doc) => CommunityReply.fromMap(doc.data(), doc.id, postId))
              .toList();
        });
  }

  // Create reply
  Future<void> createReply(String communityId, String postId, CommunityReply reply) async {
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
        
    batch.set(replyRef, reply.toMap());
    
    // If it's a teacher reply, also mark the post as answered
    final Map<String, dynamic> postUpdates = {
      'replyCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reply.isTeacherReply) {
      postUpdates['isAnswered'] = true;
    }
    
    batch.update(postRef, postUpdates);
    
    await batch.commit();
  }

  // Delete reply
  Future<void> deleteReply(String communityId, String postId, String replyId) async {
    final batch = _db.batch();
    
    final replyRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .collection('replies')
        .doc(replyId);
        
    final postRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId);
        
    batch.delete(replyRef);
    batch.update(postRef, {
      'replyCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }
}
