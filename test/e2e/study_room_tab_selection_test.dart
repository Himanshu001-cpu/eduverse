import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/study/study_page.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';
import 'harness/e2e_harness.dart';

void main() {
  final harness = E2EHarness();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_study_e2e_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    harness.setup();
    harness.reset();
    await Hive.openBox<Map>('lecture_progress');
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Study Room Selection E2E Tests', () {
    testWidgets('Verify selector tabs, test series inline tests view, and ebook read trigger', (WidgetTester tester) async {
      // 1. Setup mock auth and data
      harness.authenticateUser(uid: 'test_user');
      harness.seedBaselineData();
      harness.grantOwnership(
        uid: 'test_user',
        courses: ['course_1'],
        ebooks: ['ebook_1'],
        testSeries: ['ts_1'],
      );

      // 2. Load the Study Page
      await tester.pumpWidget(
        const MaterialApp(
          home: StudyPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify page title and default selected course batch
      expect(find.text('The Eduverse'), findsOneWidget);
      expect(find.text('MY STUDY ROOM'), findsOneWidget);
      expect(find.text('Flutter Development Masterclass'), findsOneWidget);

      // 3. Open Selector Bottom Sheet
      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      // Verify selector tabs exist
      expect(find.text('Select Study Room'), findsOneWidget);
      expect(find.text('Courses'), findsAtLeastNWidgets(1));
      expect(find.text('Test Series'), findsAtLeastNWidgets(1));
      expect(find.text('E-books'), findsAtLeastNWidgets(1));

      // 4. Switch to Test Series tab in selector
      // Tab 0: Courses, Tab 1: Test Series, Tab 2: E-books
      await tester.tap(find.text('Test Series').last);
      await tester.pumpAndSettle();

      // Verify ts_1 is listed
      expect(find.text('UPSC Prelims Mock Series'), findsOneWidget);

      // Tap to select UPSC Prelims Mock Series
      await tester.tap(find.text('UPSC Prelims Mock Series'));
      await tester.pumpAndSettle();

      // Selector dropdown should update to Test Series
      expect(find.text('MY TEST SERIES'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('batch_selector_navigate')),
          matching: find.text('UPSC Prelims Mock Series'),
        ),
        findsOneWidget,
      );

      // The main page should display the Test Series inline UI (Available Tests section)
      expect(find.text('Available Tests'), findsOneWidget);
      expect(find.text('Mock Test 1'), findsOneWidget);
      expect(find.text('Mock Test 2'), findsOneWidget);

      // 5. Open Selector Bottom Sheet again to select E-book
      await tester.tap(find.byKey(const Key('batch_selector_dropdown')));
      await tester.pumpAndSettle();

      // Switch to E-books tab
      await tester.tap(find.text('E-books').last);
      await tester.pumpAndSettle();

      // Verify ebook_1 is listed
      expect(find.text('Flutter Cookbook'), findsOneWidget);

      // Tap to select Flutter Cookbook
      await tester.tap(find.text('Flutter Cookbook'));
      await tester.pumpAndSettle();

      // Selector dropdown should update to E-book
      expect(find.text('MY E-BOOK'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('batch_selector_navigate')),
          matching: find.text('Flutter Cookbook'),
        ),
        findsOneWidget,
      );

      // The main page should display E-book inline UI (READ E-BOOK button)
      expect(find.text('READ E-BOOK'), findsOneWidget);

      // Tap READ E-BOOK to open PDF viewer
      await tester.tap(find.text('READ E-BOOK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Secure PDF viewer screen should launch successfully
      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);
    });
  });
}
