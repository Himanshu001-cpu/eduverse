import 'dart:math';
import 'feed_models.dart';

/// Returns a copy of [questions] with the options of multiple-choice questions
/// shuffled using [rng].
///
/// Since [QuizQuestion.correctIndex] dynamically searches for the option
/// with `isCorrect == true`, shuffling the options array does not break
/// answer verification or scoring.
List<QuizQuestion> shuffleQuizOptions(
  List<QuizQuestion> questions, [
  Random? rng,
]) {
  final random = rng ?? Random();
  return questions.map((q) {
    if (q.answerType == AnswerType.multipleChoice && q.options.length > 1) {
      final shuffled = List<AnswerOption>.from(q.options)..shuffle(random);
      return q.copyWith(options: shuffled);
    }
    return q;
  }).toList();
}
