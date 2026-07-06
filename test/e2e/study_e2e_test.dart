import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/study/presentation/widgets/study_ebooks_content.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'harness/e2e_harness.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';

void main() {
  final harness = E2EHarness();

  setUp(() {
    harness.setup();
    harness.reset();
    PdfNavigationManager.reset();
  });

  group('Study E-books E2E Tests (Tier 3)', () {
    testWidgets('Tier 3: Shows empty state when no e-books are owned', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No e-books yet'), findsOneWidget);
      expect(find.text('Purchase e-books from the Store to read them here!'), findsOneWidget);
    });

    testWidgets('Tier 3: Displays owned e-books with correct details', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_1']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flutter Cookbook'), findsOneWidget);
      expect(find.text('No e-books yet'), findsNothing);
    });

    testWidgets('Tier 3: E-book card tap triggers PDF launch', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_1']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flutter Cookbook'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);
    });

    testWidgets('Tier 3: Read E-book button triggers PDF launch', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_1']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Read E-book button
      await tester.tap(find.text('Read E-book'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SecurePdfViewerScreen), findsOneWidget);
    });

    testWidgets('Tier 3: Filters out not owned e-books', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      // Ebooks seeded are ebook_1, ebook_2, ebook_3. Grant only ebook_2
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_2']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Python Interview Prep'), findsOneWidget);
      expect(find.text('Flutter Cookbook'), findsNothing);
      expect(find.text('Machine Learning Guide'), findsNothing);
    });

    testWidgets('Tier 3: Shows multiple owned e-books in list', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.seedBaselineData();
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_1', 'ebook_3']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flutter Cookbook'), findsOneWidget);
      expect(find.text('Machine Learning Guide'), findsOneWidget);
    });

    testWidgets('Tier 3: Renders fallback icon when thumbnail is empty', (WidgetTester tester) async {
      harness.authenticateUser();
      
      // Seed directly with empty thumbnail
      harness.firestore.setDoc('ebooks/ebook_empty_thumb', {
        'title': 'Empty Thumb Ebook',
        'pdfUrl': 'https://example.com/empty.pdf',
        'visibility': 'published',
        'isActive': true,
        'thumbnailUrl': '',
      });
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_empty_thumb']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Empty Thumb Ebook'), findsOneWidget);
      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('Tier 3: Shows snackbar on invalid empty PDF URL', (WidgetTester tester) async {
      harness.authenticateUser();
      harness.firestore.setDoc('ebooks/ebook_bad_url', {
        'title': 'Bad URL Ebook',
        'pdfUrl': '',
        'visibility': 'published',
        'isActive': true,
      });
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_bad_url']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bad URL Ebook'));
      await tester.pump(); // Start snackbar animation
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Invalid PDF URL'), findsOneWidget);
    });

    testWidgets('Tier 3: Shows snackbar when PDF launch fails due to exception', (WidgetTester tester) async {
      harness.authenticateUser();
      // Setup url launcher to throw exception or return false
      UrlLauncherPlatform.instance = BrokenUrlLauncher();
      
      harness.firestore.setDoc('ebooks/ebook_broken', {
        'title': 'Broken PDF',
        'pdfUrl': 'https://example.com/broken.pdf',
        'visibility': 'published',
        'isActive': true,
      });
      harness.grantOwnership(uid: 'test_user', ebooks: ['ebook_broken']);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyEbooksContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Broken PDF'));
      await tester.pumpAndSettle();

      expect(find.text('Could not open the PDF URL'), findsOneWidget);
    });

    testWidgets('Tier 3: Ebook model parsing and default properties', (WidgetTester tester) async {
      final ebook = Ebook.fromMap(const {
        'title': 'Model Title',
        'pdfUrl': 'https://url.pdf',
        'realPrice': 10,
        'finalPrice': 5,
      }, 'm_id');

      expect(ebook.id, 'm_id');
      expect(ebook.title, 'Model Title');
      expect(ebook.pdfUrl, 'https://url.pdf');
      expect(ebook.realPrice, 10.0);
      expect(ebook.finalPrice, 5.0);
      expect(ebook.subtitle, '');
      expect(ebook.isActive, isTrue);
    });
   group('Ebook serialization tests', () {
      test('toMap and fromMap matching serialization', () {
        final initial = Ebook(
          id: 'test_ebook_ser',
          title: 'Title serialization',
          pdfUrl: 'https://pdf.com',
          realPrice: 15.0,
          finalPrice: 10.0,
          subtitle: 'Author name',
        );

        final map = initial.toMap();
        expect(map['title'], 'Title serialization');
        expect(map['pdfUrl'], 'https://pdf.com');

        final parsed = Ebook.fromMap(map, 'test_ebook_ser');
        expect(parsed.title, 'Title serialization');
        expect(parsed.pdfUrl, 'https://pdf.com');
      });
    });
  });
}

class BrokenUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => false;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    throw Exception('Failed to launch');
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    throw Exception('Failed to launch');
  }
}
