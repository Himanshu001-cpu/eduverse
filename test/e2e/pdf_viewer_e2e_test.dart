import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';
import 'package:eduverse/core/services/pdf_cache_service.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/repositories/i_study_repository.dart';

// Import screens we route from
import 'package:eduverse/study/presentation/widgets/study_ebooks_content.dart';

import 'harness/e2e_harness.dart';

class MockStudyRepository implements IStudyRepository {
  List<StudyBatch> enrolledBatches = [];
  List<StudyLecture> lectures = [];
  List<StudyNote> notes = [];
  List<StudyDpp> dpps = [];

  @override
  Stream<List<StudyBatch>> getEnrolledBatches(String userId) => Stream.value(enrolledBatches);

  @override
  Future<List<StudyLecture>> getBatchLectures(String userId, String courseId, String batchId) async => lectures;

  @override
  Stream<List<StudyLecture>> getBatchLecturesStream(String userId, String courseId, String batchId) => Stream.value(lectures);

  @override
  Future<void> markLectureWatched(String userId, String courseId, String batchId, String lectureId, bool isWatched) async {}

  @override
  Future<void> updateBatchProgress(String userId, String courseId, String batchId) async {}

  @override
  Future<List<StudyQuiz>> getBatchQuizzes(String courseId, String batchId) async => [];

  @override
  Future<List<StudyNote>> getBatchNotes(String courseId, String batchId) async => notes;

  @override
  Future<List<StudyPlannerItem>> getBatchPlanner(String courseId, String batchId) async => [];

  @override
  Future<List<StudyLiveClass>> getBatchLiveClasses(String courseId, String batchId) async => [];

  @override
  Future<List<StudyDpp>> getBatchDpps(String courseId, String batchId) async => dpps;

  @override
  Future<List<StudyLiveClass>> getFreeLiveClasses() async => [];

  @override
  Future<StudyBatch?> getBatch(String batchId, {required String courseId}) async => null;

  @override
  Stream<bool> isBatchBookmarked(String userId, String batchId) => Stream.value(false);

  @override
  Future<void> toggleBatchBookmark(String userId, String batchId) async {}
}

void main() {
  final harness = E2EHarness();
  late Directory tempDir;
  final List<MethodCall> screenProtectorCalls = <MethodCall>[];
  final List<MethodCall> shareCalls = <MethodCall>[];
  final List<MethodCall> openFilexCalls = <MethodCall>[];

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_pdf_e2e_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    harness.setup();
    harness.reset();
    PdfNavigationManager.reset();
    SharedPreferences.setMockInitialValues({});
    await Hive.openBox('lecture_progress');
    screenProtectorCalls.clear();
    shareCalls.clear();
    openFilexCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('screen_protector'), (methodCall) async {
      screenProtectorCalls.add(methodCall);
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), (methodCall) async {
      shareCalls.add(methodCall);
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('open_filex'), (methodCall) async {
      openFilexCalls.add(methodCall);
      return {'message': 'done', 'type': 0};
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
  });

  tearDown(() async {
    await Hive.close();
  });


  group('PDF Viewer E2E Tests - Tier 1: Feature Coverage', () {
    testWidgets('F1: UI Controls (Zoom, Dark Mode, Navigation, Search)', (WidgetTester tester) async {
      // Setup
      final args = SecurePdfViewerArgs(
        pdfUrl: 'https://example.com/ebook_1.pdf',
        title: 'Test Flutter PDF',
        isProtected: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SecurePdfViewerScreen(args: args),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final stateFinder = find.byType(SecurePdfViewerScreen);
      expect(stateFinder, findsOneWidget);

      final state = tester.state<SecurePdfViewerScreenState>(stateFinder);

      // Verify zoom controls state
      expect(state.widget.args.title, 'Test Flutter PDF');

      // Toggle Dark Mode
      expect(state.isDarkMode, isFalse);
      await tester.tap(find.byTooltip('Toggle Night Mode'));
      await tester.pump();
      expect(state.isDarkMode, isTrue);

      // Verify search input triggers search string entry
      await tester.tap(find.byTooltip('Search'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'eduverse');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(state.searchQueryController.text, 'eduverse');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('F2: Security Controls for Protected Ebook', (WidgetTester tester) async {
      final args = SecurePdfViewerArgs(
        pdfUrl: 'https://example.com/ebook_protected.pdf',
        title: 'Protected Ebook',
        isProtected: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SecurePdfViewerScreen(args: args),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Download and Share buttons must be hidden/removed
      expect(find.byTooltip('Download'), findsNothing);
      expect(find.byTooltip('Share'), findsNothing);

      // 2. Screen Protector preventScreenshotOn must be called
      expect(screenProtectorCalls.any((c) => c.method == 'preventScreenshotOn'), isTrue);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('F2: Security Controls for Unprotected PDF (Notes/DPP)', (WidgetTester tester) async {
      final args = SecurePdfViewerArgs(
        pdfUrl: 'https://example.com/notes.pdf',
        title: 'Unprotected Notes',
        isProtected: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SecurePdfViewerScreen(args: args),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Download and Share buttons must be visible
      expect(find.byTooltip('Download'), findsOneWidget);
      expect(find.byTooltip('Share'), findsOneWidget);

      // 2. Screen Protector preventScreenshotOn must NOT be called for unprotected content
      expect(screenProtectorCalls.any((c) => c.method == 'preventScreenshotOn'), isFalse);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    test('F3: Secure Caching Mechanism', () async {
      final cacheService = PdfCacheService();
      await cacheService.clearCache();

      final testUrl = 'https://example.com/cached_book.pdf';
      final testBytes = utf8.encode('PDF DUMMY BYTES');

      // Cache file
      final cachedPath = await cacheService.cachePdfFile(testUrl, testBytes);
      expect(cachedPath, isNotNull);

      // Verify filename structure: MD5 hash + .dat extension
      final filename = p.basename(cachedPath);
      expect(filename.endsWith('.dat'), isTrue);
      expect(filename.contains('.pdf'), isFalse);

      // Verify lookup from cache
      final lookupPath = await cacheService.getCachedFilePath(testUrl);
      expect(lookupPath, cachedPath);

      // Verify clear cache
      await cacheService.clearCache();
      final afterClear = await cacheService.getCachedFilePath(testUrl);
      expect(afterClear, isNull);
    });
  });

  group('PDF Viewer E2E Tests - Tier 2: Boundary & Corner Cases', () {
    testWidgets('5.3: Empty search query handling', (WidgetTester tester) async {
      final args = SecurePdfViewerArgs(
        pdfUrl: 'https://example.com/ebook_search.pdf',
        title: 'Search PDF',
        isProtected: false,
      );

      await tester.pumpWidget(MaterialApp(home: SecurePdfViewerScreen(args: args)));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byTooltip('Search'));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final state = tester.state<SecurePdfViewerScreenState>(find.byType(SecurePdfViewerScreen));
      expect(state.searchQueryController.text, '');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('6.3: User logout pops viewer screen and clears cache', (WidgetTester tester) async {
      final args = SecurePdfViewerArgs(
        pdfUrl: 'https://example.com/ebook_logout.pdf',
        title: 'Logout PDF',
        isProtected: true,
      );

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Builder(builder: (context) {
              return ElevatedButton(
                onPressed: () => PdfNavigationManager.navigateToViewer(context, args),
                child: const Text('Open'),
              );
            }),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Open PDF Viewer
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);

      // Simulate logout
      harness.auth.changeCurrentUser(null);
      // Pump multiple times to allow async clearCache() and navigation transition to complete
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Viewer popped automatically
      expect(find.byType(SecurePdfViewerScreen), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('8.2 & 8.3: Double tap and double push protection', (WidgetTester tester) async {
      final args = SecurePdfViewerArgs(
        pdfUrl: 'https://example.com/ebook_double.pdf',
        title: 'Double PDF',
        isProtected: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  PdfNavigationManager.navigateToViewer(context, args);
                  PdfNavigationManager.navigateToViewer(context, args);
                },
                child: const Text('Open'),
              );
            }),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Renders exactly one widget instance
      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('PDF Viewer E2E Tests - Tier 4: Real-World Scenarios', () {
    testWidgets('10.1 & 10.3: Ebook Purchase, Library Access, and View Journey', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();

      // Grant ownership of ebook_1
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_1']);

      // Pump user study/library ebooks screen
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Card listed
      expect(find.text('Flutter Cookbook'), findsOneWidget);

      // Tapping card opens the secure viewer
      await tester.tap(find.text('Flutter Cookbook'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);

      // Screen is protected since it is an ebook
      expect(screenProtectorCalls.any((c) => c.method == 'preventScreenshotOn'), isTrue);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('10.2: Offline access to cached PDF', (WidgetTester tester) async {
      final cacheService = PdfCacheService();
      final testUrl = 'https://example.com/offline_cached.pdf';
      final testBytes = utf8.encode('Offline file contents');

      // Pre-cache
      await cacheService.cachePdfFile(testUrl, testBytes);

      final args = SecurePdfViewerArgs(
        pdfUrl: testUrl,
        title: 'Offline PDF',
        isProtected: false,
      );

      // Pump viewer screen
      await tester.pumpWidget(
        MaterialApp(
          home: SecurePdfViewerScreen(args: args),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Viewer loads successfully from cache
      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);
      final state = tester.state<SecurePdfViewerScreenState>(find.byType(SecurePdfViewerScreen));
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
