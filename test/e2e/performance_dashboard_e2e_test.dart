import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eduverse/core/firebase/quiz_stats_service.dart';
import 'package:eduverse/core/firebase/watch_stats_service.dart';
import 'package:eduverse/profile/screens/performance_dashboard_page.dart';
import 'package:eduverse/profile/services/performance_dashboard_service.dart';
import 'package:eduverse/profile/widgets/stats_section.dart';
import 'harness/e2e_harness.dart';

void main() {
  final harness = E2EHarness();

  setUp(() {
    harness.setup();
    harness.reset();
  });

  group('Performance Dashboard E2E Tests (Tiers 1-4)', () {
    // =========================================================================
    // TIER 1: FEATURE COVERAGE (20 TESTS)
    // =========================================================================

    group('Tier 1: F1. Stats Persistence & Range Querying', () {
      testWidgets('T1_F1_1: saveQuizAttempt saves wrongAnswers, unattemptedCount, percentage, categoryLabel', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = QuizStatsService();

        await service.saveQuizAttempt(
          quizId: 'q1',
          quizTitle: 'Quiz One',
          questionsAttempted: 10,
          correctAnswers: 7,
          completed: true,
          source: 'feed',
          // Extended fields:
          wrongAnswers: 2,
          unattemptedCount: 1,
          percentage: 70.0,
          categoryLabel: 'Mathematics',
        );

        final attempts = await harness.firestore
            .collection('users')
            .doc('test_user')
            .collection('quiz_attempts')
            .get();

        expect(attempts.docs.length, 1);
        final doc = attempts.docs.first.data();
        expect(doc['wrongAnswers'], 2);
        expect(doc['unattemptedCount'], 1);
        expect(doc['percentage'], 70.0);
        expect(doc['categoryLabel'], 'Mathematics');
      });

      testWidgets('T1_F1_2: getQuizAttemptsInRange retrieves attempts inside start/end range', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = QuizStatsService();

        final now = DateTime.now();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'quizId': 'q1',
          'percentage': 80.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        });
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {
          'quizId': 'q2',
          'percentage': 90.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
        });

        final results = await service.getQuizAttemptsInRange(
          now.subtract(const Duration(days: 10)),
          now,
        );

        expect(results.length, 1);
        expect(results.first['quizId'], 'q1');
      });

      testWidgets('T1_F1_3: getDistinctCategories retrieves unique category labels', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = QuizStatsService();

        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {'categoryLabel': 'Math'});
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {'categoryLabel': 'Physics'});
        harness.firestore.setDoc('users/test_user/quiz_attempts/att3', {'categoryLabel': 'Math'});

        final categories = await service.getDistinctCategories();
        expect(categories.length, 2);
        expect(categories, containsAll(['Math', 'Physics']));
      });

      testWidgets('T1_F1_4: recordWatchTime saves subjectName', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = WatchStatsService();

        await service.recordWatchTime(
          lectureId: 'l1',
          lectureTitle: 'L1 Title',
          watchedMinutes: 20.0,
          subjectName: 'Chemistry',
        );

        final sessions = await harness.firestore
            .collection('users')
            .doc('test_user')
            .collection('watch_sessions')
            .get();

        expect(sessions.docs.length, 1);
        expect(sessions.docs.first.data()['subjectName'], 'Chemistry');
      });

      testWidgets('T1_F1_5: getWatchSessionsInRange returns sessions inside date range', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = WatchStatsService();

        final now = DateTime.now();
        harness.firestore.setDoc('users/test_user/watch_sessions/ws1', {
          'watchedMinutes': 10.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });
        harness.firestore.setDoc('users/test_user/watch_sessions/ws2', {
          'watchedMinutes': 15.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 12))),
        });

        final sessions = await service.getWatchSessionsInRange(
          now.subtract(const Duration(days: 5)),
          now,
        );

        expect(sessions.length, 1);
        expect(sessions.first['watchedMinutes'], 10.0);
      });
    });

    group('Tier 1: F2. Metrics Aggregation & Comparisons', () {
      testWidgets('T1_F2_1: Average score aggregation correct for period', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        final now = DateTime.now();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 80.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {
          'percentage': 90.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.overallScore, 85.0);
      });

      testWidgets('T1_F2_2: Quiz count aggregate correct for period', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        final now = DateTime.now();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.quizzesTaken, 2);
      });

      testWidgets('T1_F2_3: Study time total aggregate correct and formatted', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        final now = DateTime.now();
        harness.firestore.setDoc('users/test_user/watch_sessions/ws1', {
          'watchedMinutes': 45.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });
        harness.firestore.setDoc('users/test_user/watch_sessions/ws2', {
          'watchedMinutes': 75.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.formattedStudyTime, '2h 0m');
      });

      testWidgets('T1_F2_4: Improvement percentage trends computed correctly against prior equivalent period', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        final now = DateTime.now();
        // Current week (last 7 days): 80% score
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 80.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });
        // Prior week (days 8 to 14): 60% score
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {
          'percentage': 60.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.scoreImprovementPercentage, 33.33); // (80 - 60) / 60 = 33.33%
      });

      testWidgets('T1_F2_5: Correct/wrong/unattempted aggregate counts for accuracy ring correct', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        final now = DateTime.now();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'correctAnswers': 10,
          'wrongAnswers': 3,
          'unattemptedCount': 2,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.accuracyData.correct, 10);
        expect(stats.accuracyData.wrong, 3);
        expect(stats.accuracyData.unattempted, 2);
      });
    });

    group('Tier 1: F3. Dashboard UI Navigation & Period Selection', () {
      testWidgets('T1_F3_1: Click "View Dashboard →" button in StatsSection navigates to dashboard page', (WidgetTester tester) async {
        harness.authenticateUser();

        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/performance_dashboard': (context) => const PerformanceDashboardPage(),
            },
            home: const Scaffold(
              body: StatsSection(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final button = find.text('View Dashboard →');
        expect(button, findsOneWidget);

        await tester.tap(button);
        await tester.pumpAndSettle();

        expect(find.byType(PerformanceDashboardPage), findsOneWidget);
      });

      testWidgets('T1_F3_2: "This Week" chip selection updates active range to last 7 days', (WidgetTester tester) async {
        harness.authenticateUser();
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        final chip = find.widgetWithText(ChoiceChip, 'This Week');
        expect(chip, findsOneWidget);

        await tester.tap(chip);
        await tester.pumpAndSettle();

        // Should render weekly formatted widgets
        expect(find.text('from last week'), findsWidgets);
      });

      testWidgets('T1_F3_3: "This Month" chip selection updates active range to last 30 days', (WidgetTester tester) async {
        harness.authenticateUser();
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        final chip = find.widgetWithText(ChoiceChip, 'This Month');
        await tester.tap(chip);
        await tester.pumpAndSettle();

        expect(find.text('from last month'), findsWidgets);
      });

      testWidgets('T1_F3_4: "This Year" chip selection updates active range to last 365 days', (WidgetTester tester) async {
        harness.authenticateUser();
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        final chip = find.widgetWithText(ChoiceChip, 'This Year');
        await tester.tap(chip);
        await tester.pumpAndSettle();

        expect(find.text('from last year'), findsWidgets);
      });

      testWidgets('T1_F3_5: Cards for Overall Score, Quizzes, Study Time display values and trend indicators', (WidgetTester tester) async {
        harness.authenticateUser();
        // Seed mock results
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 85.0,
          'timestamp': Timestamp.now(),
        });

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.text('Overall Score'), findsOneWidget);
        expect(find.text('85.0%'), findsOneWidget);
        expect(find.text('Quizzes Taken'), findsOneWidget);
        expect(find.text('Study Time'), findsOneWidget);
      });
    });

    group('Tier 1: F4. Charts Visualizations & Dropdown filtering', () {
      testWidgets('T1_F4_1: Line chart displays quiz scores trend line', (WidgetTester tester) async {
        harness.authenticateUser();
        // Seed trend data points
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 85.0,
          'timestamp': Timestamp.now(),
        });
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('T1_F4_2: Line chart displays study time trend line', (WidgetTester tester) async {
        harness.authenticateUser();
        // Seed trend data points
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 85.0,
          'timestamp': Timestamp.now(),
        });
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Verify there is an active LineChart rendering multiple lines
        final lineChartFinder = find.byType(LineChart);
        expect(lineChartFinder, findsOneWidget);
        final LineChart chart = tester.widget(lineChartFinder);
        expect(chart.data.lineBarsData.length, 2); // Score + Study Time lines
      });

      testWidgets('T1_F4_3: Dropdown filters list available categories', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {'categoryLabel': 'Biology', 'timestamp': Timestamp.now()});

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        final dropdown = find.byType(DropdownButton<String>);
        expect(dropdown, findsOneWidget);

        await tester.tap(dropdown);
        await tester.pumpAndSettle();

        expect(find.text('Biology').last, findsOneWidget);
        expect(find.text('All Subjects').last, findsOneWidget);
      });

      testWidgets('T1_F4_4: Selecting dropdown item filters line chart points to that category', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {'categoryLabel': 'Biology', 'percentage': 90.0, 'timestamp': Timestamp.now()});
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {'categoryLabel': 'Math', 'percentage': 50.0, 'timestamp': Timestamp.now()});

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Tap dropdown
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();

        // Select Biology
        await tester.tap(find.text('Biology').last);
        await tester.pumpAndSettle();

        // Verify line chart now displays only the Biology point
        final lineChart = tester.widget<LineChart>(find.byType(LineChart));
        expect(lineChart.data.lineBarsData[0].spots.length, 1);
        expect(lineChart.data.lineBarsData[0].spots.first.y, 90.0);
      });

      testWidgets('T1_F4_5: Accuracy Ring PieChart renders correct slices', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'correctAnswers': 4,
          'wrongAnswers': 1,
          'unattemptedCount': 0,
          'timestamp': Timestamp.now(),
        });

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.byType(PieChart), findsOneWidget);
        final pieChart = tester.widget<PieChart>(find.byType(PieChart));
        expect(pieChart.data.sections.length, 3); // Correct, Wrong, Unattempted
      });
    });

    // =========================================================================
    // TIER 2: BOUNDARY & CORNER CASES (20 TESTS)
    // =========================================================================

    group('Tier 2: F1. Stats Persistence & Range Querying Boundary Cases', () {
      testWidgets('T2_F1_1: saveQuizAttempt with zero questions/correct handles division gracefully', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = QuizStatsService();

        await service.saveQuizAttempt(
          quizId: 'qz_empty',
          quizTitle: 'Empty Quiz',
          questionsAttempted: 0,
          correctAnswers: 0,
          completed: false,
          source: 'batch',
          wrongAnswers: 0,
          unattemptedCount: 0,
          percentage: 0.0,
          categoryLabel: 'N/A',
        );

        final doc = await harness.firestore
            .collection('users')
            .doc('test_user')
            .collection('quiz_attempts')
            .get();
        expect(doc.docs.first.data()['percentage'], 0.0);
      });

      testWidgets('T2_F1_2: getQuizAttemptsInRange query with start date equals end date', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = QuizStatsService();
        final time = DateTime.now();

        harness.firestore.setDoc('users/test_user/quiz_attempts/att', {
          'quizId': 'q',
          'timestamp': Timestamp.fromDate(time),
        });

        final results = await service.getQuizAttemptsInRange(time, time);
        expect(results.length, 1);
      });

      testWidgets('T2_F1_3: recordWatchTime with zero or negative minutes is ignored', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = WatchStatsService();

        await service.recordWatchTime(
          lectureId: 'l1',
          lectureTitle: 'L1',
          watchedMinutes: 0.0,
        );
        await service.recordWatchTime(
          lectureId: 'l2',
          lectureTitle: 'L2',
          watchedMinutes: -5.0,
        );

        final sessions = await harness.firestore
            .collection('users')
            .doc('test_user')
            .collection('watch_sessions')
            .get();
        expect(sessions.docs, isEmpty);
      });

      testWidgets('T2_F1_4: getWatchSessionsInRange query with start date after end date returns empty', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = WatchStatsService();
        final now = DateTime.now();

        harness.firestore.setDoc('users/test_user/watch_sessions/ws', {
          'watchedMinutes': 10.0,
          'timestamp': Timestamp.fromDate(now),
        });

        final sessions = await service.getWatchSessionsInRange(now, now.subtract(const Duration(hours: 1)));
        expect(sessions, isEmpty);
      });

      testWidgets('T2_F1_5: getDistinctCategories on user with no attempts returns empty', (WidgetTester tester) async {
        harness.authenticateUser();
        final service = QuizStatsService();

        final categories = await service.getDistinctCategories();
        expect(categories, isEmpty);
      });
    });

    group('Tier 2: F2. Metrics Aggregation & Comparisons Corner Cases', () {
      testWidgets('T2_F2_1: Improvement trend shows 0% / N/A when previous period has no data', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        // Seed only current week
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 80.0,
          'timestamp': Timestamp.now(),
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.scoreImprovementPercentage, 0.0);
        expect(stats.scoreImprovementFormatted, 'N/A');
      });

      testWidgets('T2_F2_2: Study time formatting handles boundary cases (0m, 45m, 1h 0m, 2h 15m)', (WidgetTester tester) async {
        harness.authenticateUser();
        final s = PerformanceDashboardService();

        expect(s.formatStudyMinutes(0), '0m');
        expect(s.formatStudyMinutes(45), '45m');
        expect(s.formatStudyMinutes(60), '1h 0m');
        expect(s.formatStudyMinutes(135), '2h 15m');
      });

      testWidgets('T2_F2_3: Accuracy ring handles zero quiz attempts without division error', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.accuracyData.correct, 0);
        expect(stats.accuracyData.total, 0);
      });

      testWidgets('T2_F2_4: Trend handles 100% improvement boundaries', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        final now = DateTime.now();
        // Current: 50% average
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 50.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });
        // Prior: 0% average
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {
          'percentage': 0.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 9))),
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.scoreImprovementPercentage, 100.0);
      });

      testWidgets('T2_F2_5: Trend handles count increase from 0 to positive count', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();

        // Current week: 3 quizzes, Prior week: 0 quizzes
        final now = DateTime.now();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1)))});
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2)))});
        harness.firestore.setDoc('users/test_user/quiz_attempts/att3', {'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 3)))});

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.quizzesImprovementCount, 3);
        expect(stats.quizzesImprovementFormatted, '+3 quizzes');
      });
    });

    group('Tier 2: F3. Dashboard UI Navigation & Period Selection Boundary Cases', () {
      testWidgets('T2_F3_1: Dashboard page renders fallback placeholders when database has no data', (WidgetTester tester) async {
        harness.authenticateUser();
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.text('0.0%'), findsWidgets);
        expect(find.text('0'), findsWidgets);
        expect(find.text('0m'), findsWidgets);
      });

      testWidgets('T2_F3_2: Date range query handles timezone offset difference', (WidgetTester tester) async {
        harness.authenticateUser();
        final dashboardService = PerformanceDashboardService();
        final localNow = DateTime.now();
        
        harness.firestore.setDoc('users/test_user/quiz_attempts/att', {
          'percentage': 75.0,
          'timestamp': Timestamp.fromDate(localNow.subtract(const Duration(days: 6, hours: 23))), // boundary of 7 days
        });

        final stats = await dashboardService.getAggregatedStats(Period.thisWeek);
        expect(stats.quizzesTaken, 1);
      });

      testWidgets('T2_F3_3: Period selector chips satisfy touch target bounds', (WidgetTester tester) async {
        harness.authenticateUser();
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        final Finder weekChip = find.widgetWithText(ChoiceChip, 'This Week');
        final Size size = tester.getSize(weekChip);
        expect(size.width, greaterThanOrEqualTo(48.0));
        expect(size.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('T2_F3_4: Rapid tapping on period chips fetches and resolves latest selected range without race condition', (WidgetTester tester) async {
        harness.authenticateUser();
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ChoiceChip, 'This Month'));
        await tester.tap(find.widgetWithText(ChoiceChip, 'This Year'));
        await tester.pumpAndSettle();

        // The dashboard must resolve to "This Year" description
        expect(find.text('from last year'), findsWidgets);
      });

      testWidgets('T2_F3_5: Summary card displays neutral trend indicator when difference is exactly 0', (WidgetTester tester) async {
        harness.authenticateUser();
        final now = DateTime.now();

        // Current: 80% average, Prior: 80% average
        harness.firestore.setDoc('users/test_user/quiz_attempts/a1', {'percentage': 80.0, 'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1)))});
        harness.firestore.setDoc('users/test_user/quiz_attempts/a2', {'percentage': 80.0, 'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 8)))});

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.text('0%'), findsOneWidget);
        expect(find.byIcon(Icons.trending_flat), findsWidgets);
      });
    });

    group('Tier 2: F4. Charts Visualizations & Dropdown filtering Boundary Cases', () {
      testWidgets('T2_F4_1: Dropdown selector "All Subjects" resets line chart filtering', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {'categoryLabel': 'Biology', 'percentage': 90.0, 'timestamp': Timestamp.now()});
        harness.firestore.setDoc('users/test_user/quiz_attempts/att2', {'categoryLabel': 'Physics', 'percentage': 70.0, 'timestamp': Timestamp.now()});

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Select Biology
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Biology').last);
        await tester.pumpAndSettle();

        // Reset to All Subjects
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('All Subjects').last);
        await tester.pumpAndSettle();

        final lineChart = tester.widget<LineChart>(find.byType(LineChart));
        expect(lineChart.data.lineBarsData[0].spots.length, 2); // Both points visible again
      });

      testWidgets('T2_F4_2: Accuracy ring handles single answer classification type (e.g. 100% correct, 0% wrong)', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att', {
          'correctAnswers': 10,
          'wrongAnswers': 0,
          'unattemptedCount': 0,
          'timestamp': Timestamp.now(),
        });

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.byType(PieChart), findsOneWidget);
        final pieChart = tester.widget<PieChart>(find.byType(PieChart));
        // Verify only 1 visual section has non-zero value or handles it safely
        final activeSections = pieChart.data.sections.where((sec) => sec.value > 0).toList();
        expect(activeSections.length, 1);
        expect(activeSections.first.value, 10.0);
      });

      testWidgets('T2_F4_3: Line chart displays graceful fallback when 0 data points exist', (WidgetTester tester) async {
        harness.authenticateUser();
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.text('No activity trend data available for this range'), findsOneWidget);
      });

      testWidgets('T2_F4_4: Line chart displays graceful fallback when exactly 1 data point exists', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att', {
          'percentage': 85.0,
          'timestamp': Timestamp.now(),
        });

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);
        final lineChart = tester.widget<LineChart>(find.byType(LineChart));
        expect(lineChart.data.lineBarsData[0].spots.length, 1);
      });

      testWidgets('T2_F4_5: Line chart legend spacing does not overflow screen boundaries', (WidgetTester tester) async {
        harness.authenticateUser();
        // Seed trend data points to show chart
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {
          'percentage': 85.0,
          'timestamp': Timestamp.now(),
        });
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Verify no pixel overflows occurred
        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // TIER 3: CROSS-FEATURE COMBINATIONS (5 TESTS)
    // =========================================================================

    group('Tier 3: Cross-Feature Integration Tests', () {
      testWidgets('T3_X_1: Selection of period chip (F3) requests new database range query (F1) and updates summary indicators (F2)', (WidgetTester tester) async {
        harness.authenticateUser();
        final now = DateTime.now();

        // Seed data in current week
        harness.firestore.setDoc('users/test_user/quiz_attempts/w1', {'percentage': 90.0, 'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2)))});
        // Seed data in current month (but older than a week)
        harness.firestore.setDoc('users/test_user/quiz_attempts/m1', {'percentage': 50.0, 'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 20)))});

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Default 'This Week' should show 90%
        expect(find.text('90.0%'), findsOneWidget);

        // Tap 'This Month' chip
        await tester.tap(find.widgetWithText(ChoiceChip, 'This Month'));
        await tester.pumpAndSettle();

        // Should combine both: (90 + 50) / 2 = 70%
        expect(find.text('70.0%'), findsOneWidget);
      });

      testWidgets('T3_X_2: Dropdown filter selection (F4) updates line chart series (F4) but leaves overall summary cards untouched (F2)', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/a1', {'categoryLabel': 'Biology', 'percentage': 80.0, 'timestamp': Timestamp.now()});
        harness.firestore.setDoc('users/test_user/quiz_attempts/a2', {'categoryLabel': 'Math', 'percentage': 60.0, 'timestamp': Timestamp.now()});

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Average overall is 70.0%
        expect(find.text('70.0%'), findsOneWidget);

        // Filter line chart by Biology
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Biology').last);
        await tester.pumpAndSettle();

        // Line chart filters, but aggregate summary card remains 70% overall as per requirements
        expect(find.text('70.0%'), findsOneWidget);
        final lineChart = tester.widget<LineChart>(find.byType(LineChart));
        expect(lineChart.data.lineBarsData[0].spots.length, 1);
      });

      testWidgets('T3_X_3: Seeding quiz attempt in Firestore (F1) automatically refreshes subjects dropdown choices (F4)', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.firestore.setDoc('users/test_user/quiz_attempts/att1', {'categoryLabel': 'History', 'timestamp': Timestamp.now()});

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Dropdown displays History
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        expect(find.text('History').last, findsOneWidget);
        await tester.tap(find.text('History').last); // close dropdown
        await tester.pumpAndSettle();

        // Save new category
        final quizService = QuizStatsService();
        await quizService.saveQuizAttempt(
          quizId: 'q2',
          quizTitle: 'Civics',
          questionsAttempted: 5,
          correctAnswers: 4,
          completed: true,
          source: 'feed',
          wrongAnswers: 1,
          unattemptedCount: 0,
          percentage: 80.0,
          categoryLabel: 'Civics',
        );

        // Re-render/pump
        await tester.pumpAndSettle();

        // Dropdown must now also display Civics
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        expect(find.text('Civics').last, findsOneWidget);
      });

      testWidgets('T3_X_4: Recording new watch sessions (F1) updates both total study time card (F2/F3) and line chart trend line (F4)', (WidgetTester tester) async {
        harness.authenticateUser();
        
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.text('0m'), findsOneWidget);

        // Record a watch session
        harness.firestore.setDoc('users/test_user/watch_sessions/new_ws', {
          'lectureId': 'l_new',
          'watchedMinutes': 90.0,
          'subjectName': 'Physics',
          'timestamp': Timestamp.now(),
        });

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('1h 30m'), findsOneWidget);
      });

      testWidgets('T3_X_5: Full User Dashboard Integration flow: Navigate -> Switch Range -> Filter Subject -> Assert charts & summary values', (WidgetTester tester) async {
        harness.authenticateUser();
        final now = DateTime.now();

        // Seed extensive profile details
        harness.firestore.setDoc('users/test_user/quiz_attempts/math1', {
          'categoryLabel': 'Math',
          'percentage': 90.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
        });
        harness.firestore.setDoc('users/test_user/quiz_attempts/bio1', {
          'categoryLabel': 'Biology',
          'percentage': 60.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
        });

        await tester.pumpWidget(
          MaterialApp(
            routes: {'/performance_dashboard': (_) => const PerformanceDashboardPage()},
            home: const Scaffold(body: StatsSection()),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate
        await tester.tap(find.text('View Dashboard →'));
        await tester.pumpAndSettle();

        // Switch period to Month
        await tester.tap(find.widgetWithText(ChoiceChip, 'This Month'));
        await tester.pumpAndSettle();

        // Verify monthly overall average is 75%
        expect(find.text('75.0%'), findsOneWidget);

        // Filter by Biology
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Biology').last);
        await tester.pumpAndSettle();

        // Verify line chart matches Biology (60%)
        final lineChart = tester.widget<LineChart>(find.byType(LineChart));
        expect(lineChart.data.lineBarsData[0].spots.first.y, 60.0);
      });
    });

    // =========================================================================
    // TIER 4: REAL-WORLD APPLICATION SCENARIOS (5 TESTS)
    // =========================================================================

    group('Tier 4: Real-World Scenarios', () {
      testWidgets('T4_S_1: Full Student Journey: user watches lecture -> attempts quiz -> dashboard matches', (WidgetTester tester) async {
        harness.authenticateUser();
        harness.seedBaselineData();

        // 1. User watches lecture
        harness.firestore.setDoc('users/test_user/watch_sessions/ws1', {
          'lectureId': 'lec_1',
          'lectureTitle': 'Flutter widgets',
          'watchedMinutes': 40.0,
          'subjectName': 'Development',
          'timestamp': Timestamp.now(),
        });

        // 2. User attempts quiz
        harness.firestore.setDoc('users/test_user/quiz_attempts/qa1', {
          'quizId': 'quiz_flutter',
          'quizTitle': 'Flutter Basics',
          'questionsAttempted': 5,
          'correctAnswers': 4,
          'wrongAnswers': 1,
          'unattemptedCount': 0,
          'completed': true,
          'source': 'feed',
          'percentage': 80.0,
          'categoryLabel': 'Development',
          'timestamp': Timestamp.now(),
        });

        // 3. Check Dashboard rendering
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.text('80.0%'), findsOneWidget);
        expect(find.text('40m'), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // 1 quiz taken
      });

      testWidgets('T4_S_2: Multi-day alternating study schedule rendering line chart peaks', (WidgetTester tester) async {
        harness.authenticateUser();
        final now = DateTime.now();

        // Alternating days: Study, Quiz, Study, Quiz
        harness.firestore.setDoc('users/test_user/watch_sessions/s1', {
          'watchedMinutes': 60.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        });
        harness.firestore.setDoc('users/test_user/quiz_attempts/q1', {
          'percentage': 70.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        });
        harness.firestore.setDoc('users/test_user/watch_sessions/s2', {
          'watchedMinutes': 120.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });
        harness.firestore.setDoc('users/test_user/quiz_attempts/q2', {
          'percentage': 90.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        final lineChart = tester.widget<LineChart>(find.byType(LineChart));
        // Verify scores bar has 2 spots
        expect(lineChart.data.lineBarsData[0].spots.length, 2);
        // Verify study mins bar has 2 spots
        expect(lineChart.data.lineBarsData[1].spots.length, 2);
      });

      testWidgets('T4_S_3: Multi-month progress review and historical comparison correctness', (WidgetTester tester) async {
        harness.authenticateUser();
        final now = DateTime.now();

        // This Month (last 30 days): Average score 90%
        harness.firestore.setDoc('users/test_user/quiz_attempts/cur_month', {
          'percentage': 90.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        });
        // Previous Month (days 31 to 60): Average score 60%
        harness.firestore.setDoc('users/test_user/quiz_attempts/prev_month', {
          'percentage': 60.0,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 40))),
        });

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ChoiceChip, 'This Month'));
        await tester.pumpAndSettle();

        // Check overall score is 90%
        expect(find.text('90.0%'), findsOneWidget);
        // Check improvement calculation is +50% (+30% absolute improvement from 60% base = 50.0% relative improvement)
        expect(find.text('+50%'), findsOneWidget);
      });

      testWidgets('T4_S_4: Offline database error/timeout handling displaying error state with Retry action', (WidgetTester tester) async {
        harness.authenticateUser();
        
        // Setup mock service failure behavior
        PerformanceDashboardService.mockThrowExceptionOnQuery = true;

        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        // Check if error message is printed on UI
        expect(find.text('Failed to load performance metrics'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Turn off error trigger
        PerformanceDashboardService.mockThrowExceptionOnQuery = false;
        
        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Error message must clear and default placeholders load
        expect(find.text('Failed to load performance metrics'), findsNothing);
        expect(find.text('Overall Score'), findsOneWidget);
      });

      testWidgets('T4_S_5: High volume load rendering and data aggregation performance', (WidgetTester tester) async {
        harness.authenticateUser();
        final now = DateTime.now();

        // Seed 100 quiz attempts
        final batch = harness.firestore.batch();
        for (int i = 0; i < 100; i++) {
          final ref = harness.firestore.collection('users').doc('test_user').collection('quiz_attempts').doc('att_$i');
          batch.set(ref, {
            'percentage': 70.0 + (i % 20),
            'timestamp': Timestamp.fromDate(now.subtract(Duration(days: i % 30))),
          });
        }
        await batch.commit();

        // Aggregation computation & dashboard paint must complete smoothly
        await tester.pumpWidget(const MaterialApp(home: PerformanceDashboardPage()));
        await tester.pumpAndSettle();

        expect(find.byType(LineChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
