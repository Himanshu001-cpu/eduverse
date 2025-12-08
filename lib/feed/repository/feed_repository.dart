import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/feed_data.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';

class FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      print('Error getting feed item $id: $e');
      return null;
    }
  }

  Future<void> addFeedItem(FeedItem item) async {
    await _firestore.collection(FirestorePaths.feed).doc(item.id).set(item.toJson());
  }

  // --- Seeding ---
  Future<void> seedFeedData() async {
    final feedRef = _firestore.collection(FirestorePaths.feed);
    // REMOVED check for existing data to force update 'isPublic' field
    // final snapshot = await feedRef.limit(1).get();
    // if (snapshot.docs.isNotEmpty) return; 

    for (final item in FeedData.feedItems) {
      await feedRef.doc(item.id).set(item.toJson(), SetOptions(merge: true));
    }
  }
}
