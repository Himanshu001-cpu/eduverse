import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/admin/models/test_quiz_models.dart' show TestSection;
import 'package:eduverse/admin/widgets/test_paper_editor/question_status.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/test_paper_header.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/test_stats_strip.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/section_tabs.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/question_palette_rail.dart';
import 'package:eduverse/admin/widgets/test_paper_editor/question_editor_card.dart';

void main() {
  group('QuestionStatus Logic', () {
    test('isQuestionComplete evaluates prompt and option validity', () {
      // Empty question
      final emptyQ = QuizQuestion(
        id: 'q1',
        questionText: '',
        options: const [
          AnswerOption(id: '1', text: 'A', isCorrect: true),
          AnswerOption(id: '2', text: 'B', isCorrect: false),
        ],
      );
      expect(isQuestionComplete(emptyQ), isFalse);

      // Prompt without correct answer
      final noCorrectQ = QuizQuestion(
        id: 'q2',
        questionText: 'Prompt here',
        options: const [
          AnswerOption(id: '1', text: 'A', isCorrect: false),
          AnswerOption(id: '2', text: 'B', isCorrect: false),
        ],
      );
      expect(isQuestionComplete(noCorrectQ), isFalse);

      // Prompt with <2 filled options
      final oneOptionQ = QuizQuestion(
        id: 'q3',
        questionText: 'Prompt here',
        options: const [
          AnswerOption(id: '1', text: 'A', isCorrect: true),
          AnswerOption(id: '2', text: '', isCorrect: false),
        ],
      );
      expect(isQuestionComplete(oneOptionQ), isFalse);

      // Valid MCQ
      final validMcq = QuizQuestion(
        id: 'q4',
        questionText: 'Valid Prompt',
        options: const [
          AnswerOption(id: '1', text: 'A', isCorrect: true),
          AnswerOption(id: '2', text: 'B', isCorrect: false),
        ],
      );
      expect(isQuestionComplete(validMcq), isTrue);

      // True/False
      final validTf = QuizQuestion(
        id: 'q5',
        questionText: 'T/F Prompt',
        answerType: AnswerType.trueFalse,
        correctBooleanAnswer: true,
      );
      expect(isQuestionComplete(validTf), isTrue);

      final unselectedTf = QuizQuestion(
        id: 'q6',
        questionText: 'T/F Prompt',
        answerType: AnswerType.trueFalse,
        correctBooleanAnswer: null,
      );
      expect(isQuestionComplete(unselectedTf), isFalse);
    });
  });

  group('TestPaperHeader Widget', () {
    testWidgets('renders title, categories, tags, and handles callbacks at 1440x900', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool settingsOpened = false;
      bool saved = false;
      bool savedAndClosed = false;
      bool discarded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestPaperHeader(
              title: 'Mock #19 — Indian Economy',
              category: 'Prelims',
              testCode: 'TS-PRE-019',
              autosaveText: 'Autosaved at 11:42 AM',
              hasUnsavedChanges: true,
              onOpenSettings: () => settingsOpened = true,
              onDiscard: () => discarded = true,
              onSave: () => saved = true,
              onSaveAndClose: () => savedAndClosed = true,
            ),
          ),
        ),
      );

      expect(find.text('Mock #19 — Indian Economy'), findsOneWidget);
      expect(find.text('PRELIMS'), findsOneWidget);
      expect(find.text('CODE: TS-PRE-019'), findsOneWidget);
      expect(find.text('Autosaved at 11:42 AM'), findsOneWidget);
      expect(find.text('UNSAVED CHANGES'), findsOneWidget);

      await tester.tap(find.text('Test Settings'));
      expect(settingsOpened, isTrue);

      await tester.tap(find.text('Save'));
      expect(saved, isTrue);

      await tester.tap(find.text('Save & Close'));
      expect(savedAndClosed, isTrue);

      await tester.tap(find.text('Discard'));
      expect(discarded, isTrue);
    });

    testWidgets('renders without overflow on mobile viewport 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TestPaperHeader(
                title: 'Mock #19 — Indian Economy and Fiscal Union Long Title',
                category: 'Full Length',
                testCode: 'TEST-1234',
                autosaveText: 'Autosaved at 11:42 AM',
                hasUnsavedChanges: true,
                onOpenSettings: () {},
                onDiscard: () {},
                onSave: () {},
                onSaveAndClose: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('TestStatsStrip Widget', () {
    testWidgets('renders all 5 metric cards and triggers onTapCard', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestStatsStrip(
              totalQuestions: 25,
              totalMarks: 50.0,
              marksPerQuestion: 2.0,
              negativeMarks: 0.66,
              timeLimit: const Duration(minutes: 60),
              sectionsCount: 3,
              scheduledAt: DateTime(2026, 10, 15, 10, 0),
              onTapCard: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('25 Qs'), findsOneWidget);
      expect(find.text('50 Marks'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('3 Sections'), findsOneWidget);
      expect(find.text('15/10/2026'), findsOneWidget);

      await tester.tap(find.text('25 Qs'));
      expect(tapped, isTrue);
    });
  });

  group('SectionTabs Widget', () {
    testWidgets('renders all and section tabs with counts and selection', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? selectedSection = 'sec_1';
      bool addPressed = false;

      final sections = [
        const TestSection(id: 'sec_1', name: 'Section A: Macro'),
        const TestSection(id: 'sec_2', name: 'Section B: Banking'),
      ];

      final counts = <String?, int>{
        null: 30,
        'sec_1': 20,
        'sec_2': 10,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionTabs(
              sections: sections,
              activeSectionId: selectedSection,
              questionCounts: counts,
              onSelectSection: (id) => selectedSection = id,
              onAddSection: () => addPressed = true,
              onRenameSection: (_) {},
              onDeleteSection: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('All Questions'), findsOneWidget);
      expect(find.text('Section A: Macro'), findsOneWidget);
      expect(find.text('Section B: Banking'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.text('All Questions'));
      expect(selectedSection, isNull);

      await tester.tap(find.text('Add Section'));
      expect(addPressed, isTrue);
    });
  });

  group('QuestionPaletteRail Widget', () {
    testWidgets('renders matrix chips, legend, and responds to selection', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selectedIdx = -1;
      bool addQPressed = false;
      bool importPressed = false;

      final questions = [
        const QuizQuestion(
          id: 'q1',
          questionText: 'Prompt 1',
          difficulty: QuestionDifficulty.hard,
          options: [
            AnswerOption(id: '1', text: 'A', isCorrect: true),
            AnswerOption(id: '2', text: 'B', isCorrect: false),
          ],
        ),
        const QuizQuestion(
          id: 'q2',
          questionText: '',
          flaggedForReview: true,
          difficulty: QuestionDifficulty.easy,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionPaletteRail(
              questions: questions,
              currentIndex: 0,
              onSelectQuestion: (i) => selectedIdx = i,
              onReorderQuestions: (oldIdx, newIdx) {},
              onAddQuestion: () => addQPressed = true,
              onAddMultiple: () {},
              onImportFromLibrary: () => importPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Question Matrix'), findsOneWidget);
      expect(find.text('1 Validated'), findsOneWidget);
      expect(find.text('1 Flagged'), findsOneWidget);

      // Verify chip 2 exists and tap it
      final chip2 = find.descendant(
        of: find.byType(DragTarget<int>).last,
        matching: find.text('2'),
      );
      expect(chip2, findsOneWidget);
      await tester.tap(chip2);
      expect(selectedIdx, 1);

      await tester.tap(find.text('Add Question'));
      expect(addQPressed, isTrue);

      await tester.tap(find.text('Import Pool'));
      expect(importPressed, isTrue);
    });
  });

  group('QuestionEditorCard Widget', () {
    testWidgets('renders question editor, options, and handles updates', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      QuizQuestion currentQ = const QuizQuestion(
        id: 'q1',
        questionText: 'Which constitutional article covers FRBM?',
        difficulty: QuestionDifficulty.medium,
        score: 2,
        options: [
          AnswerOption(id: '1', text: 'Article 112', isCorrect: true, rationale: 'Budget provision'),
          AnswerOption(id: '2', text: 'Article 280', isCorrect: false, rationale: 'Finance commission'),
          AnswerOption(id: '3', text: 'Article 360', isCorrect: false),
          AnswerOption(id: '4', text: 'None of the above', isCorrect: false),
        ],
      );

      bool nextPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuestionEditorCard(
                question: currentQ,
                questionIndex: 0,
                totalQuestions: 5,
                sections: const [TestSection(id: 'sec_1', name: 'Section A')],
                subjects: const ['Economy', 'Polity'],
                onUpdateQuestion: (updated) => currentQ = updated,
                onDuplicateQuestion: () {},
                onDeleteQuestion: () {},
                onPreviousQuestion: null,
                onNextOrAddQuestion: () => nextPressed = true,
                isLastQuestion: false,
                onPromptNewSubject: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Q1'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('Question Statement Prompt'), findsOneWidget);
      expect(find.text('Answer Options & Distractor Rationale'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Correct Answer Key'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Next: Q2'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Next: Q2'));
      expect(nextPressed, isTrue);
    });
  });
}
