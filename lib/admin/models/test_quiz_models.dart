/// Models used by the test series test editor for subject-based quiz questions.
/// These are simple mutable models for in-editor state management.

class QuizSubject {
  String name;
  List<QuizQuestion> questions;

  QuizSubject({required this.name, List<QuizQuestion>? questions})
    : questions = questions ?? [];
}

class QuizQuestion {
  String questionText;
  List<String> options;
  int correctOptionIndex;
  double marks;
  double negativeMarks;
  String subject;
  String topic;
  String explanation;

  QuizQuestion({
    this.questionText = '',
    List<String>? options,
    this.correctOptionIndex = 0,
    this.marks = 4.0,
    this.negativeMarks = 1.0,
    this.subject = '',
    this.topic = '',
    this.explanation = '',
  }) : options = options ?? ['', '', '', ''];
}
