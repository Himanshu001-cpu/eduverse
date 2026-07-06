import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';

/// Service to track and manage video watch time statistics
class WatchStatsService {
  static final WatchStatsService _instance = WatchStatsService._internal();
  factory WatchStatsService() => _instance;
  WatchStatsService._internal();

  FirebaseFirestore get _firestore => EduverseFirebase.firestore;

  /// Record watch session and update aggregate stats
  Future<void> recordWatchTime({
    required String lectureId,
    required String lectureTitle,
    double? watchedMinutes,
    int? seconds,
    String? subjectName,
    String? courseId,
    String? batchId,
  }) async {
    final user = EduverseFirebase.auth.currentUser;
    if (user == null) return;

    // Resolve minutes and seconds dynamically
    double finalMinutes = watchedMinutes ?? 0.0;
    int finalSeconds = seconds ?? 0;

    if (seconds != null) {
      if (watchedMinutes == null) {
        finalMinutes = seconds / 60.0;
      }
    } else if (watchedMinutes != null) {
      finalSeconds = (watchedMinutes * 60).round();
    }

    if (finalSeconds <= 0 && finalMinutes <= 0.0) return;

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
      'watchedMinutes': finalMinutes,
      'seconds': finalSeconds,
      'subjectName': subjectName ?? 'General',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update aggregate stats
    await _updateAggregateStats(user.uid, finalMinutes);
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
    final user = EduverseFirebase.auth.currentUser;
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

  /// Get watch sessions inside date range
  Future<List<Map<String, dynamic>>> getWatchSessionsInRange(DateTime start, DateTime end) async {
    final user = EduverseFirebase.auth.currentUser;
    if (user == null) return [];
    if (start.isAfter(end)) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('watch_sessions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
