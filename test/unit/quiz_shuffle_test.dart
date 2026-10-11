import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/feed/models/quiz_shuffle.dart';

void main() {
  group('shuffleQuizOptions', () {
    test('shuffles multiple-choice options while preserving correctness', () {
      final q1 = QuizQuestion(
        id: 'q1',
        questionText: 'Capital of France?',
        answerType: AnswerType.multipleChoice,
        options: const [
          AnswerOption(id: 'opt_a', text: 'Berlin', isCorrect: false),
          AnswerOption(id: 'opt_b', text: 'Madrid', isCorrect: false),
          AnswerOption(id: 'opt_c', text: 'Paris', isCorrect: true),
          AnswerOption(id: 'opt_d', text: 'Rome', isCorrect: false),
        ],
      );

      expect(q1.correctIndex, 2);
      expect(q1.options[q1.correctIndex].text, 'Paris');

      // Use a fixed random seed that produces a known permutation
      final rng = Random(42);
      final shuffledList = shuffleQuizOptions([q1], rng);

      expect(shuffledList.length, 1);
      final shuffledQ1 = shuffledList.first;

      // Ensure Paris is still marked correct and correctIndex points to it
      final newCorrectIdx = shuffledQ1.correctIndex;
      expect(shuffledQ1.options[newCorrectIdx].text, 'Paris');
      expect(shuffledQ1.options[newCorrectIdx].isCorrect, isTrue);

      // Verify original question was not mutated
      expect(q1.options[2].text, 'Paris');
      expect(q1.options[0].text, 'Berlin');
    });

    test('preserves True/False questions without altering option order', () {
      final tfQuestion = QuizQuestion(
        id: 'q_tf',
        questionText: 'The earth is round.',
        answerType: AnswerType.trueFalse,
        correctBooleanAnswer: true,
        options: const [
          AnswerOption(id: 't', text: 'True', isCorrect: true),
          AnswerOption(id: 'f', text: 'False', isCorrect: false),
        ],
      );

      final result = shuffleQuizOptions([tfQuestion], Random(99));
      expect(result.first.options[0].text, 'True');
      expect(result.first.options[1].text, 'False');
    });
  });
}
