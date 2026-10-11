import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/admin/screens/batch_quiz_screen.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/admin/models/admin_models.dart';
import '../e2e/harness/fake_firebase_firestore.dart';
import '../e2e/harness/fake_firebase_auth.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;
  late FirebaseAdminService adminService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = FakeFirebaseAuth();

    EduverseFirebase.mockFirestore = fakeFirestore;
    EduverseFirebase.mockAuth = fakeAuth;

    fakeAuth.changeCurrentUser(FakeUser(
      uid: 'admin_1',
      email: 'admin@eduverse.com',
      displayName: 'Admin User',
    ));
    fakeFirestore.setDoc('users/admin_1', {
      'name': 'Admin User',
      'email': 'admin@eduverse.com',
      'role': 'admin',
      'disabled': false,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });

    adminService = FirebaseAdminService(
      auth: fakeAuth,
      db: fakeFirestore,
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Provider<FirebaseAdminService>.value(
        value: adminService,
        child: const BatchQuizScreen(
          courseId: 'course_123',
          batchId: 'batch_456',
        ),
      ),
    );
  }

  group('BatchQuizScreen (Quiz Studio) Tests', () {
    testWidgets('Step 0: Initializes at Exam Rules & Marking with editable controls', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify Stepper steps are rendered
      expect(find.text('1. Exam Rules & Marking'), findsOneWidget);
      expect(find.text('2. Section Builder'), findsOneWidget);
      expect(find.text('4. Solution Keys'), findsOneWidget);
      expect(find.text('5. Publishing & Timing'), findsOneWidget);

      // Verify Step 0 Content is visible
      expect(find.text('EXAM SPECIFICATION & METADATA'), findsOneWidget);
      expect(find.text('Marking Scheme'), findsOneWidget);
      expect(find.text('Examination Duration'), findsOneWidget);
      expect(find.text('STUDENT EXAM INSTRUCTIONS & CODE OF CONDUCT'), findsOneWidget);

      // Verify continue button
      expect(find.text('Continue to Section Builder →'), findsOneWidget);
    });

    testWidgets('Step 1: Section Builder allows adding new sections and viewing count', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Navigate to Section Builder via stepper tab
      await tester.tap(find.text('2. Section Builder'));
      await tester.pumpAndSettle();

      expect(find.text('PAPER SECTION BUILDER'), findsOneWidget);
      expect(find.text('Add Section'), findsOneWidget);

      // Add a custom section
      final addSectionInput = find.widgetWithText(TextField, 'Enter new section name (e.g. Section C — Quantitative Aptitude)');
      await tester.enterText(addSectionInput, 'Section C — Data Interpretation');
      await tester.tap(find.text('Add Section'));
      await tester.pumpAndSettle();

      expect(find.text('Section C — Data Interpretation'), findsOneWidget);
    });

    testWidgets('Step 2: Question Vault has Easy/Medium/Hard difficulty (NO UPSC)', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Navigate to Question Vault
      await tester.tap(find.textContaining('3. Question Vault'));
      await tester.pumpAndSettle();

      // Confirm NO UPSC strings are present on screen
      expect(find.textContaining('UPSC'), findsNothing);

      // Verify difficulty dropdown shows Medium by default
      expect(find.text('Medium'), findsOneWidget);

      // Open difficulty dropdown
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      // Check available difficulty options are strictly Easy, Medium, Hard
      expect(find.text('Easy'), findsWidgets);
      expect(find.text('Hard'), findsWidgets);
      expect(find.textContaining('UPSC Easy'), findsNothing);
      expect(find.textContaining('UPSC Moderate'), findsNothing);
      expect(find.textContaining('UPSC Hard'), findsNothing);
    });

    testWidgets('Step 2: Question Prompt and Answer Options have working formatting buttons', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Navigate to Question Vault
      await tester.tap(find.textContaining('3. Question Vault'));
      await tester.pumpAndSettle();

      // Verify formatting buttons exist on prompt
      expect(find.byTooltip('Bold'), findsWidgets);
      expect(find.byTooltip('Italic'), findsWidgets);
      expect(find.byTooltip('LaTeX Equation'), findsWidgets);

      // Tap Bold on Question prompt
      final boldButtons = find.byTooltip('Bold');
      await tester.tap(boldButtons.first);
      await tester.pumpAndSettle();

      // Verify options A, B, C, D each have their own format buttons
      expect(find.text('Option Builder & Distractor Settings'), findsOneWidget);
      expect(find.byTooltip('Bold'), findsNWidgets(6)); // prompt + 4 options + explanation
      expect(find.byTooltip('LaTeX Equation'), findsNWidgets(6)); // prompt + 4 options + explanation
    });

    testWidgets('Step 3 & Step 4: Solution Keys and Publishing steps render correctly', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Navigate to Step 3: Solution Keys
      final step4Tab = find.text('4. Solution Keys');
      await tester.ensureVisible(step4Tab);
      await tester.tap(step4Tab);
      await tester.pumpAndSettle();

      expect(find.text('MASTER ANSWER KEY & SOLUTION AUDIT'), findsOneWidget);
      expect(find.textContaining('Option A'), findsOneWidget);

      // Navigate to Step 4: Publishing & Timing
      final step5Tab = find.text('5. Publishing & Timing');
      await tester.ensureVisible(step5Tab);
      await tester.tap(step5Tab);
      await tester.pumpAndSettle();

      expect(find.text('PRE-FLIGHT EXAMINATION VERIFICATION'), findsOneWidget);
      expect(find.text('Publish Examination to Test Series'), findsOneWidget);
      expect(find.text('Security & Navigation Control'), findsOneWidget);
    });

    testWidgets('Step 4: Save Draft persists without empty document path error', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Navigate to Publishing & Timing
      final step5Tab = find.text('5. Publishing & Timing');
      await tester.ensureVisible(step5Tab);
      await tester.tap(step5Tab);
      await tester.pumpAndSettle();

      // Tap Save Draft (bottom action button)
      final saveDraftBtns = find.widgetWithText(OutlinedButton, 'Save Draft');
      expect(saveDraftBtns, findsWidgets);
      await tester.tap(saveDraftBtns.last);
      await tester.pumpAndSettle();

      // Confirm success snackbar and no red error snackbar
      expect(find.text('Quiz draft successfully saved.'), findsOneWidget);
      expect(find.textContaining('Error saving quiz:'), findsNothing);
      expect(find.textContaining('A document path must be a non-empty string'), findsNothing);
    });

    test('FirebaseAdminService safely saves quizzes with empty quiz.id and courseId', () async {
      // 1. Course Quiz with empty id and empty courseId
      final emptyQuiz = AdminQuiz(
        id: '',
        title: 'Empty ID Quiz',
        description: 'Test',
        questions: [],
        createdAt: DateTime.now(),
      );

      final generatedCourseQuizId = await adminService.saveCourseQuiz('', emptyQuiz, isNew: true);
      expect(generatedCourseQuizId, isNotEmpty);

      // 2. Recorded Batch Quiz with empty id, courseId, and batchId
      final generatedBatchQuizId = await adminService.saveRecordedBatchQuiz('', '', emptyQuiz, isNew: true);
      expect(generatedBatchQuizId, isNotEmpty);

      // 3. Streams return empty lists gracefully on blank IDs
      final courseStream = adminService.getCourseQuizzes('');
      expect(await courseStream.first, isEmpty);

      final batchStream = adminService.getRecordedBatchQuizzes('', '');
      expect(await batchStream.first, isEmpty);
    });
  });
}
