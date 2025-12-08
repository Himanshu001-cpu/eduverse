import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to track and manage video watch time statistics
class WatchStatsService {
  static final WatchStatsService _instance = WatchStatsService._internal();
  factory WatchStatsService() => _instance;
  WatchStatsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record watch session and update aggregate stats
  Future<void> recordWatchTime({
    required String lectureId,
    required String lectureTitle,
    required double watchedMinutes,
    String? courseId,
    String? batchId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || watchedMinutes <= 0) return;

    // Save individual watch session
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('watch_sessions')
        .add({
      'lectureId': lectureId,
      'lectureTitle': lectureTitle,
      'courseId': courseId,
      'batchId': batchId,
      'watchedMinutes': watchedMinutes,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update aggregate stats
    await _updateAggregateStats(user.uid, watchedMinutes);
  }

  /// Update user's aggregate watch statistics
  Future<void> _updateAggregateStats(String uid, double watchedMinutes) async {
    final statsRef = _firestore.collection('users').doc(uid).collection('stats').doc('watch');
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(statsRef);
      
      if (snapshot.exists) {
        final data = snapshot.data()!;
        transaction.update(statsRef, {
          'totalMinutes': (data['totalMinutes'] ?? 0.0) + watchedMinutes,
          'sessionsCount': (data['sessionsCount'] ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(statsRef, {
          'totalMinutes': watchedMinutes,
          'sessionsCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get user's aggregate watch stats as a stream
  Stream<Map<String, dynamic>> getWatchStatsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({
        'totalMinutes': 0.0,
        'sessionsCount': 0,
      });
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('watch')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()!;
      }
      return {
        'totalMinutes': 0.0,
        'sessionsCount': 0,
      };
    });
  }
}
