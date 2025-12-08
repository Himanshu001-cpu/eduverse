import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to track and manage quiz statistics for users
class QuizStatsService {
  static final QuizStatsService _instance = QuizStatsService._internal();
  factory QuizStatsService() => _instance;
  QuizStatsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save quiz attempt to user's quiz_stats subcollection
  Future<void> saveQuizAttempt({
    required String quizId,
    required String quizTitle,
    required int questionsAttempted,
    required int correctAnswers,
    required bool completed,
    required String source, // 'batch' or 'feed'
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Save individual quiz attempt
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_attempts')
        .add({
      'quizId': quizId,
      'quizTitle': quizTitle,
      'questionsAttempted': questionsAttempted,
      'correctAnswers': correctAnswers,
      'completed': completed,
      'source': source,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update aggregate stats
    await _updateAggregateStats(
      user.uid,
      questionsAttempted: questionsAttempted,
      completed: completed,
    );
  }

  /// Update user's aggregate quiz statistics
  Future<void> _updateAggregateStats(
    String uid, {
    required int questionsAttempted,
    required bool completed,
  }) async {
    final statsRef = _firestore.collection('users').doc(uid).collection('stats').doc('quiz');
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(statsRef);
      
      if (snapshot.exists) {
        final data = snapshot.data()!;
        transaction.update(statsRef, {
          'questionsAttempted': (data['questionsAttempted'] ?? 0) + questionsAttempted,
          'quizzesAttempted': (data['quizzesAttempted'] ?? 0) + 1,
          'quizzesCompleted': (data['quizzesCompleted'] ?? 0) + (completed ? 1 : 0),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(statsRef, {
          'questionsAttempted': questionsAttempted,
          'quizzesAttempted': 1,
          'quizzesCompleted': completed ? 1 : 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get user's aggregate quiz stats as a stream
  Stream<Map<String, dynamic>> getQuizStatsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({
        'questionsAttempted': 0,
        'quizzesAttempted': 0,
        'quizzesCompleted': 0,
      });
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('quiz')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()!;
      }
      return {
        'questionsAttempted': 0,
        'quizzesAttempted': 0,
        'quizzesCompleted': 0,
      };
    });
  }
}
