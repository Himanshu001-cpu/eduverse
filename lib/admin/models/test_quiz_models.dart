/// Models used by the test series test editor for subject-based quiz questions.
/// These are simple mutable models for in-editor state management.
library;

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
  String difficulty;
  List<Map<String, String>> citations;
  Map<String, String> distractorExplanations;

  QuizQuestion({
    this.questionText = '',
    List<String>? options,
    this.correctOptionIndex = 0,
    this.marks = 4.0,
    this.negativeMarks = 1.0,
    this.subject = '',
    this.topic = '',
    this.explanation = '',
    this.difficulty = 'Medium',
    List<Map<String, String>>? citations,
    Map<String, String>? distractorExplanations,
  })  : options = options ?? ['', '', '', ''],
        citations = citations ?? [],
        distractorExplanations = distractorExplanations ?? {};

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['questionText'] ?? json['question'] ?? '',
      options: json['options'] != null ? List<String>.from(json['options']) : ['', '', '', ''],
      correctOptionIndex: json['correctOptionIndex'] as int? ?? (json['correctIndex'] as int? ?? 0),
      marks: (json['marks'] as num?)?.toDouble() ?? 4.0,
      negativeMarks: (json['negativeMarks'] as num?)?.toDouble() ?? 1.0,
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
      citations: json['citations'] != null
          ? (json['citations'] as List).map((c) => Map<String, String>.from(c as Map)).toList()
          : [],
      distractorExplanations: json['distractorExplanations'] != null
          ? Map<String, String>.from(json['distractorExplanations'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'marks': marks,
      'negativeMarks': negativeMarks,
      'subject': subject,
      'topic': topic,
      'explanation': explanation,
      'difficulty': difficulty,
      'citations': citations,
      'distractorExplanations': distractorExplanations,
    };
  }
}

/// Represents an editorial section in a test paper (e.g. "Section A: Macro & Budget").
class TestSection {
  final String id;
  final String name;

  const TestSection({required this.id, required this.name});

  factory TestSection.fromJson(Map<String, dynamic> json) {
    return TestSection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  TestSection copyWith({String? id, String? name}) {
    return TestSection(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

