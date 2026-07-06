import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/profile/services/performance_dashboard_service.dart';

class StudentAccuracyData {
  final int correct;
  final int wrong;
  final int unattempted;
  final int total;

  StudentAccuracyData({
    required this.correct,
    required this.wrong,
    required this.unattempted,
    required this.total,
  });
}

class StudentDashboardStats {
  final double overallScore;
  final int quizzesTaken;
  final String formattedStudyTime;
  final double scoreImprovementPercentage;
  final String scoreImprovementFormatted;
  final int quizzesImprovementCount;
  final String quizzesImprovementFormatted;
  final StudentAccuracyData accuracyData;
  final List<Map<String, dynamic>> rawQuizAttempts;
  final List<Map<String, dynamic>> rawWatchSessions;
  final int priorQuizzesTaken;

  StudentDashboardStats({
    required this.overallScore,
    required this.quizzesTaken,
    required this.formattedStudyTime,
    required this.scoreImprovementPercentage,
    required this.scoreImprovementFormatted,
    required this.quizzesImprovementCount,
    required this.quizzesImprovementFormatted,
    required this.accuracyData,
    required this.rawQuizAttempts,
    required this.rawWatchSessions,
    required this.priorQuizzesTaken,
  });
}

class StudentPerformanceService {
  static final StudentPerformanceService _instance = StudentPerformanceService._internal();
  factory StudentPerformanceService() => _instance;
  StudentPerformanceService._internal();

  FirebaseFirestore get _firestore => EduverseFirebase.firestore;

  String formatStudyMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    } else {
      return '${m}m';
    }
  }

  /// Get quiz attempts in range for a specific user
  Future<List<Map<String, dynamic>>> getQuizAttemptsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('quiz_attempts')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get watch sessions in range for a specific user
  Future<List<Map<String, dynamic>>> getWatchSessionsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    if (start.isAfter(end)) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('watch_sessions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get test attempts (Test Series results) for a specific user
  Future<List<Map<String, dynamic>>> getTestAttempts(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('test_attempts')
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get distinct category labels for a specific user's quiz attempts
  Future<List<String>> getDistinctCategories(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('quiz_attempts')
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['categoryLabel'] as String?)
        .where((label) => label != null && label.isNotEmpty)
        .map((label) => label!)
        .toSet()
        .toList();
  }

  /// Get aggregated stats for a specific user
  Future<StudentDashboardStats> getAggregatedStats(
    String userId,
    Period period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final now = DateTime.now();
    late final DateTime currentStart;
    late final DateTime priorStart;
    late final DateTime currentEnd;

    if (customStart != null && customEnd != null) {
      currentStart = customStart;
      currentEnd = customEnd;
      // For prior comparison, we take the same duration before customStart
      final duration = customEnd.difference(customStart);
      priorStart = customStart.subtract(duration);
    } else {
      currentEnd = now;
      switch (period) {
        case Period.thisWeek:
          currentStart = now.subtract(const Duration(days: 7));
          priorStart = now.subtract(const Duration(days: 14));
          break;
        case Period.thisMonth:
          currentStart = now.subtract(const Duration(days: 30));
          priorStart = now.subtract(const Duration(days: 60));
          break;
        case Period.thisYear:
          currentStart = now.subtract(const Duration(days: 365));
          priorStart = now.subtract(const Duration(days: 730));
          break;
      }
    }

    final currentAttempts = await getQuizAttemptsInRange(userId, currentStart, currentEnd);
    final priorAttempts = await getQuizAttemptsInRange(userId, priorStart, currentStart);
    final currentSessions = await getWatchSessionsInRange(userId, currentStart, currentEnd);

    // 1. Current Quiz Stats
    final quizzesTaken = currentAttempts.length;
    double overallScore = 0.0;
    if (quizzesTaken > 0) {
      final sum = currentAttempts.fold<double>(0.0, (acc, doc) {
        final pct = doc['percentage'] ?? 0.0;
        return acc + (pct as num).toDouble();
      });
      overallScore = sum / quizzesTaken;
    }

    int correct = 0;
    int wrong = 0;
    int unattempted = 0;
    int totalQuestions = 0;

    for (final doc in currentAttempts) {
      correct += (doc['correctAnswers'] ?? 0) as int;
      wrong += (doc['wrongAnswers'] ?? 0) as int;
      unattempted += (doc['unattemptedCount'] ?? 0) as int;
      totalQuestions += (doc['questionsAttempted'] ?? 0) as int;
    }

    final accuracyData = StudentAccuracyData(
      correct: correct,
      wrong: wrong,
      unattempted: unattempted,
      total: totalQuestions,
    );

    // 2. Prior Quiz Stats
    final priorQuizzesTaken = priorAttempts.length;
    double priorOverallScore = 0.0;
    if (priorQuizzesTaken > 0) {
      final sum = priorAttempts.fold<double>(0.0, (acc, doc) {
        final pct = doc['percentage'] ?? 0.0;
        return acc + (pct as num).toDouble();
      });
      priorOverallScore = sum / priorQuizzesTaken;
    }

    // 3. Current Watch Stats
    final totalMinutes = currentSessions.fold<double>(0.0, (acc, doc) {
      final mins = doc['watchedMinutes'] ?? 0.0;
      return acc + (mins as num).toDouble();
    });
    final formattedStudyTime = formatStudyMinutes(totalMinutes.round());

    // 4. Improvements
    double scoreImprovementPercentage = 0.0;
    if (priorQuizzesTaken > 0) {
      if (priorOverallScore == 0.0) {
        scoreImprovementPercentage = overallScore > 0 ? 100.0 : 0.0;
      } else {
        final rawDiff = ((overallScore - priorOverallScore) / priorOverallScore) * 100;
        scoreImprovementPercentage = double.parse(rawDiff.toStringAsFixed(2));
      }
    }

    String scoreImprovementFormatted = 'N/A';
    if (priorQuizzesTaken > 0) {
      final diff = scoreImprovementPercentage;
      if (diff > 0) {
        scoreImprovementFormatted = '+${diff.toStringAsFixed(0)}%';
      } else if (diff < 0) {
        scoreImprovementFormatted = '${diff.toStringAsFixed(0)}%';
      } else {
        scoreImprovementFormatted = '0%';
      }
    }

    final quizzesImprovementCount = quizzesTaken - priorQuizzesTaken;
    final quizzesImprovementFormatted = quizzesImprovementCount >= 0
        ? '+$quizzesImprovementCount quizzes'
        : '$quizzesImprovementCount quizzes';

    return StudentDashboardStats(
      overallScore: overallScore,
      quizzesTaken: quizzesTaken,
      formattedStudyTime: formattedStudyTime,
      scoreImprovementPercentage: scoreImprovementPercentage,
      scoreImprovementFormatted: scoreImprovementFormatted,
      quizzesImprovementCount: quizzesImprovementCount,
      quizzesImprovementFormatted: quizzesImprovementFormatted,
      accuracyData: accuracyData,
      rawQuizAttempts: currentAttempts,
      rawWatchSessions: currentSessions,
      priorQuizzesTaken: priorQuizzesTaken,
    );
  }
}
