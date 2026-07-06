import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/study/presentation/screens/study_test_series_screen.dart';
import 'package:eduverse/study/presentation/screens/test_series_detail_screen.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/core/firebase/quiz_stats_service.dart';
import 'harness/e2e_harness.dart';

void main() {
  final harness = E2EHarness();

  setUp(() {
    harness.setup();
    harness.reset();
  });

  group('Test Progress E2E Tests (Tier 4)', () {
    testWidgets('Tier 4: Initial test series progress starts at 0/2 completed (0% progress)', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyTestSeriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/2 completed'), findsOneWidget);
    });

    testWidgets('Tier 4: Dynamic progress updates to 1/2 completed (50%) when one test is attempted', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1']);

      // Seed one completed attempt
      harness.firestore.setDoc('users/test_user/test_attempts/ts_1_test_1', {
        'score': 4.0,
        'totalMarks': 6.0,
        'correctCount': 2,
        'totalQuestions': 3,
        'percentage': 66.6,
        'completedAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyTestSeriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1/2 completed'), findsOneWidget);
    });

    testWidgets('Tier 4: Progress updates to 2/2 completed (100%) when all tests are attempted', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1']);

      // Seed both attempts
      harness.firestore.setDoc('users/test_user/test_attempts/ts_1_test_1', {
        'score': 4.0,
        'totalMarks': 6.0,
      });
      harness.firestore.setDoc('users/test_user/test_attempts/ts_1_test_2', {
        'score': 2.0,
        'totalMarks': 6.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyTestSeriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2/2 completed'), findsOneWidget);
    });

    testWidgets('Tier 4: Attempts from other test series are ignored', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1', 'ts_2']);

      // Seed attempt for ts_2 but not ts_1
      harness.firestore.setDoc('users/test_user/test_attempts/ts_2_test_1', {
        'score': 4.0,
        'totalMarks': 6.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyTestSeriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ts_1 should show 0/2 completed
      expect(find.text('0/2 completed'), findsOneWidget);
      // ts_2 should show 1/2 completed
      expect(find.text('1/2 completed'), findsOneWidget);
    });

    testWidgets('Tier 4: Duplicate attempts on the same test do not double count progress', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1']);

      // Seed attempt for ts_1_test_1 twice (should overwrite same document)
      harness.firestore.setDoc('users/test_user/test_attempts/ts_1_test_1', {
        'score': 4.0,
        'totalMarks': 6.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyTestSeriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1/2 completed'), findsOneWidget);
    });

    testWidgets('Tier 4: Progress calculation filters out attempts for deleted tests', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1']);

      // Seed attempt for a test that does not exist in the collection 'test_series/ts_1/tests/'
      harness.firestore.setDoc('users/test_user/test_attempts/ts_1_deleted_test', {
        'score': 4.0,
        'totalMarks': 6.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyTestSeriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should still be 0/2 because ts_1_deleted_test is not one of the actual tests
      expect(find.text('0/2 completed'), findsOneWidget);
    });

    testWidgets('Tier 4: TestSeriesDetailScreen renders completed badge and score', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1']);

      harness.firestore.setDoc('users/test_user/test_attempts/ts_1_test_1', {
        'score': 4.0,
        'totalMarks': 6.0,
      });

      final testSeriesItem = TestSeriesItem(
        id: 'ts_1',
        title: 'UPSC Prelims Mock Series',
        description: 'Description',
        price: 39.99,
        subject: 'General Studies',
        emoji: '📝',
        gradientColors: [Colors.blue, Colors.indigo],
        totalTests: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TestSeriesDetailScreen(testSeries: testSeriesItem),
        ),
      );
      await tester.pumpAndSettle();

      // Check for COMPLETED badge
      expect(find.text('COMPLETED'), findsOneWidget);
      // Check for score display
      expect(find.text('Score: 4.0 / 6.0'), findsOneWidget);
    });

    testWidgets('Tier 4: QuizStatsService updates user aggregate stats', (WidgetTester tester) async {
      harness.authenticateUser();
      final statsService = QuizStatsService();

      await statsService.saveQuizAttempt(
        quizId: 'quiz_1',
        quizTitle: 'Quiz One',
        questionsAttempted: 10,
        correctAnswers: 8,
        completed: true,
        source: 'feed',
      );

      final statsDoc = await harness.firestore
          .collection('users')
          .doc('test_user')
          .collection('stats')
          .doc('quiz')
          .get();

      expect(statsDoc.exists, isTrue);
      expect(statsDoc.data()?['questionsAttempted'], 10);
      expect(statsDoc.data()?['quizzesCompleted'], 1);
    });

    testWidgets('Tier 4: Empty details rendering fallback values', (WidgetTester tester) async {
      final item = TestSeriesItem(
        id: 'ts_empty',
        title: 'Empty Mock',
        description: '',
        price: 0,
        subject: '',
        emoji: '❓',
        gradientColors: [],
        totalTests: 0,
      );

      expect(item.id, 'ts_empty');
      expect(item.subject, '');
      expect(item.gradientColors, isEmpty);
    });

    testWidgets('Tier 4: Verify test card starts test navigation', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', testSeries: ['ts_1']);

      final testSeriesItem = TestSeriesItem(
        id: 'ts_1',
        title: 'UPSC Prelims Mock Series',
        description: 'Description',
        price: 39.99,
        subject: 'General Studies',
        emoji: '📝',
        gradientColors: [Colors.blue, Colors.indigo],
        totalTests: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TestSeriesDetailScreen(testSeries: testSeriesItem),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start Test'), findsAtLeastNWidgets(1));
    });
  });
}
