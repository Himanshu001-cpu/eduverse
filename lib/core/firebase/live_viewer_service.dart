import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service to track live viewer counts using Firestore + RTDB presence.
///
/// Uses Firebase Realtime Database `onDisconnect` to handle ungraceful
/// disconnects (app kills, network loss). A Cloud Function triggers on
/// RTDB node removal to decrement the Firestore `viewerCount`.
class LiveViewerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  /// Returns the Firestore document reference for the live class.
  DocumentReference _liveClassDoc(
    String courseId,
    String batchId,
    String liveClassId,
  ) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('batches')
        .doc(batchId)
        .collection('live_classes')
        .doc(liveClassId);
  }

  /// Returns the RTDB reference for a viewer's presence node.
  DatabaseReference _presenceRef(
    String courseId,
    String batchId,
    String liveClassId,
    String userId,
  ) {
    final sessionKey = '${courseId}_${batchId}_${liveClassId}';
    return _rtdb.ref('live_viewers/$sessionKey/$userId');
  }

  /// Join a live class: increment Firestore counter and set RTDB presence
  /// with onDisconnect cleanup.
  Future<void> joinLive(
    String courseId,
    String batchId,
    String liveClassId,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // 1. Increment Firestore viewer count
      await _liveClassDoc(courseId, batchId, liveClassId).update({
        'viewerCount': FieldValue.increment(1),
      });

      // 2. Set RTDB presence node with onDisconnect removal
      final ref = _presenceRef(courseId, batchId, liveClassId, userId);
      await ref.onDisconnect().remove();
      await ref.set({
        'joinedAt': ServerValue.timestamp,
        'courseId': courseId,
        'batchId': batchId,
        'liveClassId': liveClassId,
      });
    } catch (e) {
      debugPrint('LiveViewerService: Error joining live: $e');
    }
  }

  /// Leave a live class: decrement Firestore counter and remove RTDB
  /// presence node. Cancels the onDisconnect so the Cloud Function
  /// does not double-decrement.
  Future<void> leaveLive(
    String courseId,
    String batchId,
    String liveClassId,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // 1. Cancel the onDisconnect handler (prevent Cloud Function trigger)
      final ref = _presenceRef(courseId, batchId, liveClassId, userId);
      await ref.onDisconnect().cancel();

      // 2. Remove RTDB presence node
      await ref.remove();

      // 3. Decrement Firestore viewer count (graceful leave)
      await _liveClassDoc(courseId, batchId, liveClassId).update({
        'viewerCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('LiveViewerService: Error leaving live: $e');
    }
  }

  /// Returns a real-time stream of the current viewer count.
  Stream<int> viewerCountStream(
    String courseId,
    String batchId,
    String liveClassId,
  ) {
    return _liveClassDoc(courseId, batchId, liveClassId)
        .snapshots()
        .map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      final count = data?['viewerCount'] as int? ?? 0;
      return count < 0 ? 0 : count;
    });
  }
}
