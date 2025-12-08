import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../profile/models/bookmark_model.dart';

class BookmarkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Collection reference: users/{uid}/bookmarks/{itemId}
  CollectionReference<Map<String, dynamic>>? get _bookmarksRef {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('bookmarks');
  }

  // Toggle bookmark: Add if not exists, Remove if exists
  Future<bool> toggleBookmark(BookmarkItem item) async {
    final ref = _bookmarksRef;
    if (ref == null) return false;

    try {
      final docRef = ref.doc(item.id);
      final doc = await docRef.get();

      if (doc.exists) {
        // Remove
        await docRef.delete();
        return false; // Not bookmarked anymore
      } else {
        // Add
        await docRef.set(item.toMap());
        return true; // Bookmarked
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      rethrow;
    }
  }

  // Check if an item is bookmarked
  Future<bool> isBookmarked(String itemId) async {
    final ref = _bookmarksRef;
    if (ref == null) return false;

    try {
      final doc = await ref.doc(itemId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking bookmark: $e');
      return false;
    }
  }

  // Check if an item is bookmarked (Stream for real-time updates)
  Stream<bool> isBookmarkedStream(String itemId) {
    final ref = _bookmarksRef;
    if (ref == null) return Stream.value(false);

    return ref.doc(itemId).snapshots().map((doc) => doc.exists);
  }

  // Get all bookmarks stream
  Stream<List<BookmarkItem>> getBookmarksStream() {
    final ref = _bookmarksRef;
    if (ref == null) return Stream.value([]);

    return ref
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookmarkItem.fromMap(doc.data()))
          .toList();
    });
  }
  
  // Explicitly remove bookmark
  Future<void> removeBookmark(String itemId) async {
      final ref = _bookmarksRef;
      if(ref == null) return;
      
      try {
          await ref.doc(itemId).delete();
      } catch (e) {
          debugPrint('Error removing bookmark: $e');
          rethrow;
      }
  }
}
