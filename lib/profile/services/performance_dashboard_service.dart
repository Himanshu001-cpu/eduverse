import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/core/firebase/quiz_stats_service.dart';
import 'package:eduverse/core/firebase/watch_stats_service.dart';

enum Period { thisWeek, thisMonth, thisYear }

class AccuracyData {
  final int correct;
  final int wrong;
  final int unattempted;
  final int total;

  AccuracyData({
    required this.correct,
    required this.wrong,
    required this.unattempted,
    required this.total,
  });
}

class DashboardStats {
  final double overallScore;
  final int quizzesTaken;
  final String formattedStudyTime;
  final double scoreImprovementPercentage;
  final String scoreImprovementFormatted;
  final int quizzesImprovementCount;
  final String quizzesImprovementFormatted;
  final AccuracyData accuracyData;
  final List<Map<String, dynamic>> rawQuizAttempts;
  final List<Map<String, dynamic>> rawWatchSessions;
  final int priorQuizzesTaken;
  final List<Map<String, dynamic>> rawTestAttempts;
  final List<String> purchasedTestSeriesIds;
  final Map<String, int> testSeriesTestCounts;

  DashboardStats({
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
    required this.rawTestAttempts,
    required this.purchasedTestSeriesIds,
    required this.testSeriesTestCounts,
  });
}

class PerformanceDashboardService {
  static bool mockThrowExceptionOnQuery = false;

  final QuizStatsService _quizStatsService = QuizStatsService();
  final WatchStatsService _watchStatsService = WatchStatsService();

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

  Future<DashboardStats> getAggregatedStats(
    Period period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    if (mockThrowExceptionOnQuery) {
      throw Exception('Failed to load performance metrics');
    }

    final now = DateTime.now();
    late final DateTime currentStart;
    late final DateTime priorStart;
    late final DateTime currentEnd;

    if (customStart != null && customEnd != null) {
      currentStart = customStart;
      currentEnd = customEnd;
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

    final currentAttempts = await _quizStatsService.getQuizAttemptsInRange(currentStart, currentEnd);
    final priorAttempts = await _quizStatsService.getQuizAttemptsInRange(priorStart, currentStart);
    final currentSessions = await _watchStatsService.getWatchSessionsInRange(currentStart, currentEnd);

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

    final accuracyData = AccuracyData(
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

    // 5. Test Attempts and Purchased Test Series
    final user = EduverseFirebase.auth.currentUser;
    List<Map<String, dynamic>> rawTestAttempts = [];
    List<String> purchasedTestSeriesIds = [];
    Map<String, int> testSeriesTestCounts = {};

    if (user != null) {
      final testAttemptsSnapshot = await EduverseFirebase.firestore
          .collection('users')
          .doc(user.uid)
          .collection('test_attempts')
          .orderBy('completedAt', descending: true)
          .get();
      rawTestAttempts = testAttemptsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      final userDoc = await EduverseFirebase.firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        purchasedTestSeriesIds = List<String>.from(userData['purchasedTestSeries'] ?? []);
      }

      for (final tsId in purchasedTestSeriesIds) {
        final tsDoc = await EduverseFirebase.firestore.collection('test_series').doc(tsId).get();
        if (tsDoc.exists) {
          final tsData = tsDoc.data() ?? {};
          testSeriesTestCounts[tsId] = (tsData['totalTests'] ?? 0) as int;
        }
      }
    }

    return DashboardStats(
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
      rawTestAttempts: rawTestAttempts,
      purchasedTestSeriesIds: purchasedTestSeriesIds,
      testSeriesTestCounts: testSeriesTestCounts,
    );
  }
}
