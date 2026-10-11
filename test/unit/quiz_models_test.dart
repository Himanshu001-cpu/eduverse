import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/admin/models/test_quiz_models.dart' show TestSection;

void main() {
  group('AnswerOption Rationale Extension', () {
    test('serializes and deserializes rationale', () {
      const opt = AnswerOption(
        id: 'opt_1',
        text: 'Option A',
        isCorrect: true,
        rationale: 'This is the correct historical provision.',
      );

      final json = opt.toJson();
      expect(json['rationale'], 'This is the correct historical provision.');

      final parsed = AnswerOption.fromJson(json);
      expect(parsed.id, 'opt_1');
      expect(parsed.text, 'Option A');
      expect(parsed.isCorrect, isTrue);
      expect(parsed.rationale, 'This is the correct historical provision.');
    });

    test('omits rationale from toJson when null', () {
      const opt = AnswerOption(id: 'opt_2', text: 'Option B');
      final json = opt.toJson();
      expect(json.containsKey('rationale'), isFalse);

      final parsed = AnswerOption.fromJson(json);
      expect(parsed.rationale, isNull);
    });

    test('copyWith updates rationale', () {
      const opt = AnswerOption(id: 'opt_1', text: 'Option A');
      final updated = opt.copyWith(rationale: 'Updated rationale');
      expect(updated.rationale, 'Updated rationale');
    });
  });

  group('QuizQuestion Extended Fields', () {
    test('serializes and deserializes sectionId, difficulty, flaggedForReview', () {
      final q = QuizQuestion(
        id: 'q_100',
        questionText: 'What is FRBM?',
        answerType: AnswerType.multipleChoice,
        options: const [
          AnswerOption(id: 'o1', text: 'A', isCorrect: true, rationale: 'Correct'),
          AnswerOption(id: 'o2', text: 'B', isCorrect: false, rationale: 'Distractor'),
        ],
        sectionId: 'sec_macro',
        difficulty: QuestionDifficulty.hard,
        flaggedForReview: true,
      );

      final json = q.toJson();
      expect(json['sectionId'], 'sec_macro');
      expect(json['difficulty'], 'hard');
      expect(json['flaggedForReview'], isTrue);

      final parsed = QuizQuestion.fromJson(json);
      expect(parsed.id, 'q_100');
      expect(parsed.sectionId, 'sec_macro');
      expect(parsed.difficulty, QuestionDifficulty.hard);
      expect(parsed.flaggedForReview, isTrue);
      expect(parsed.options[0].rationale, 'Correct');
      expect(parsed.options[1].rationale, 'Distractor');
    });

    test('backward compatibility: parses legacy JSON without new fields', () {
      final legacyJson = {
        'id': 'legacy_q',
        'questionText': 'Legacy question text',
        'answerType': 'multipleChoice',
        'options': [
          {'id': 'o1', 'text': 'Option 1', 'isCorrect': true},
          {'id': 'o2', 'text': 'Option 2', 'isCorrect': false},
        ],
        'score': 2,
      };

      final parsed = QuizQuestion.fromJson(legacyJson);
      expect(parsed.id, 'legacy_q');
      expect(parsed.sectionId, isNull);
      expect(parsed.difficulty, isNull);
      expect(parsed.flaggedForReview, isFalse);
      expect(parsed.options[0].rationale, isNull);

      final json = parsed.toJson();
      expect(json.containsKey('sectionId'), isFalse);
      expect(json.containsKey('difficulty'), isFalse);
      expect(json.containsKey('flaggedForReview'), isFalse);
    });

    test('copyWith handles clearSectionId and clearDifficulty', () {
      final q = QuizQuestion(
        id: 'q_1',
        questionText: 'Test',
        sectionId: 'sec_1',
        difficulty: QuestionDifficulty.medium,
        flaggedForReview: true,
      );

      // Clearing sectionId
      final clearedSection = q.copyWith(clearSectionId: true);
      expect(clearedSection.sectionId, isNull);
      expect(clearedSection.difficulty, QuestionDifficulty.medium);
      expect(clearedSection.flaggedForReview, isTrue);

      // Clearing difficulty
      final clearedDiff = q.copyWith(clearDifficulty: true);
      expect(clearedDiff.sectionId, 'sec_1');
      expect(clearedDiff.difficulty, isNull);

      // Toggling flaggedForReview
      final unflagged = q.copyWith(flaggedForReview: false);
      expect(unflagged.flaggedForReview, isFalse);
    });
  });

  group('TestSection Model', () {
    test('serializes and deserializes correctly', () {
      const section = TestSection(id: 'sec_1', name: 'Section A: Macro');
      final json = section.toJson();
      expect(json['id'], 'sec_1');
      expect(json['name'], 'Section A: Macro');

      final parsed = TestSection.fromJson(json);
      expect(parsed, equals(section));
    });

    test('copyWith updates name', () {
      const section = TestSection(id: 'sec_1', name: 'Original');
      final updated = section.copyWith(name: 'Renamed');
      expect(updated.id, 'sec_1');
      expect(updated.name, 'Renamed');
    });
  });
}
