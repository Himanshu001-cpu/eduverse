// file: lib/feed/models/feed_models.dart

/// Extended content for articles
class ArticleContent {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final int estimatedReadTime; // in minutes
  final DateTime? publishedDate;

  const ArticleContent({
    required this.id,
    required this.title,
    required this.body,
    this.tags = const [],
    this.estimatedReadTime = 5,
    this.publishedDate,
  });

  factory ArticleContent.fromJson(Map<String, dynamic> json) {
    return ArticleContent(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      estimatedReadTime: json['estimatedReadTime'] as int? ?? 5,
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'tags': tags,
        'estimatedReadTime': estimatedReadTime,
        'publishedDate': publishedDate?.toIso8601String(),
      };
}

/// Current Affairs extended content with structured sections
class CurrentAffairsContent {
  final String id;
  final String title;
  final DateTime eventDate;
  final String context; // national/international
  final String whatHappened;
  final String whyItMatters;
  final String upscRelevance;
  final List<String> tags;

  const CurrentAffairsContent({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.context,
    required this.whatHappened,
    required this.whyItMatters,
    required this.upscRelevance,
    this.tags = const [],
  });

  factory CurrentAffairsContent.fromJson(Map<String, dynamic> json) {
    return CurrentAffairsContent(
      id: json['id'] as String,
      title: json['title'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      context: json['context'] as String,
      whatHappened: json['whatHappened'] as String,
      whyItMatters: json['whyItMatters'] as String,
      upscRelevance: json['upscRelevance'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'eventDate': eventDate.toIso8601String(),
        'context': context,
        'whatHappened': whatHappened,
        'whyItMatters': whyItMatters,
        'upscRelevance': upscRelevance,
        'tags': tags,
      };
}

/// Answer writing question content
class AnswerWritingContent {
  final String id;
  final String question;
  final int wordLimit;
  final int timeLimitMinutes;
  final String? modelAnswer;
  final List<String> keyPoints;

  const AnswerWritingContent({
    required this.id,
    required this.question,
    this.wordLimit = 250,
    this.timeLimitMinutes = 7,
    this.modelAnswer,
    this.keyPoints = const [],
  });

  factory AnswerWritingContent.fromJson(Map<String, dynamic> json) {
    return AnswerWritingContent(
      id: json['id'] as String,
      question: json['question'] as String,
      wordLimit: json['wordLimit'] as int? ?? 250,
      timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 7,
      modelAnswer: json['modelAnswer'] as String?,
      keyPoints: (json['keyPoints'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'wordLimit': wordLimit,
        'timeLimitMinutes': timeLimitMinutes,
        'modelAnswer': modelAnswer,
        'keyPoints': keyPoints,
      };
}

/// Answer types for quiz questions
enum AnswerType { multipleChoice, trueFalse, shortAnswer }

/// Individual answer option for multiple choice questions
class AnswerOption {
  final String id;
  final String text;
  final bool isCorrect;

  const AnswerOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isCorrect': isCorrect,
      };

  AnswerOption copyWith({String? id, String? text, bool? isCorrect}) {
    return AnswerOption(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

/// Enhanced Quiz question model supporting multiple answer types
class QuizQuestion {
  final String id;
  final String questionText;
  final AnswerType answerType;
  final List<AnswerOption> options; // For multiple choice
  final bool? correctBooleanAnswer; // For true/false
  final String? correctShortAnswer; // For short answer
  final int score;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    this.answerType = AnswerType.multipleChoice,
    this.options = const [],
    this.correctBooleanAnswer,
    this.correctShortAnswer,
    this.score = 1,
    this.explanation,
  });

  // Legacy compatibility: get question text
  String get question => questionText;

  // Legacy compatibility: get correct index for multiple choice
  int get correctIndex {
    final idx = options.indexWhere((o) => o.isCorrect);
    return idx >= 0 ? idx : 0;
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Handle legacy format (just options as strings)
    if (json['options'] != null && json['options'] is List && 
        (json['options'] as List).isNotEmpty && 
        json['options'][0] is String) {
      // Legacy format: convert to new format
      final legacyOptions = (json['options'] as List<dynamic>).cast<String>();
      final correctIdx = json['correctIndex'] as int? ?? 0;
      return QuizQuestion(
        id: json['id'] as String,
        questionText: json['question'] as String? ?? json['questionText'] as String,
        answerType: AnswerType.multipleChoice,
        options: legacyOptions.asMap().entries.map((e) => AnswerOption(
          id: 'opt_${e.key}',
          text: e.value,
          isCorrect: e.key == correctIdx,
        )).toList(),
        score: json['score'] as int? ?? 1,
        explanation: json['explanation'] as String?,
      );
    }

    // New format
    final typeStr = json['answerType'] as String? ?? 'multipleChoice';
    final answerType = AnswerType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AnswerType.multipleChoice,
    );

    return QuizQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String? ?? json['question'] as String? ?? '',
      answerType: answerType,
      options: json['options'] != null
          ? (json['options'] as List<dynamic>)
              .map((o) => AnswerOption.fromJson(o as Map<String, dynamic>))
              .toList()
          : [],
      correctBooleanAnswer: json['correctBooleanAnswer'] as bool?,
      correctShortAnswer: json['correctShortAnswer'] as String?,
      score: json['score'] as int? ?? 1,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionText': questionText,
        'answerType': answerType.name,
        'options': options.map((o) => o.toJson()).toList(),
        'correctBooleanAnswer': correctBooleanAnswer,
        'correctShortAnswer': correctShortAnswer,
        'score': score,
        'explanation': explanation,
      };

  QuizQuestion copyWith({
    String? id,
    String? questionText,
    AnswerType? answerType,
    List<AnswerOption>? options,
    bool? correctBooleanAnswer,
    String? correctShortAnswer,
    int? score,
    String? explanation,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      answerType: answerType ?? this.answerType,
      options: options ?? this.options,
      correctBooleanAnswer: correctBooleanAnswer ?? this.correctBooleanAnswer,
      correctShortAnswer: correctShortAnswer ?? this.correctShortAnswer,
      score: score ?? this.score,
      explanation: explanation ?? this.explanation,
    );
  }
}

/// Quiz container model
class Quiz {
  final String id;
  final String title;
  final String? description;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Quiz({
    required this.id,
    required this.title,
    this.description,
    this.questions = const [],
    required this.createdAt,
    this.updatedAt,
  });

  int get totalScore => questions.fold(0, (sum, q) => sum + q.score);
  int get questionCount => questions.length;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      questions: json['questions'] != null
          ? (json['questions'] as List<dynamic>)
              .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    List<QuizQuestion>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Video content model
class VideoContent {
  final String id;
  final String title;
  final String description;
  final String videoUrl; // placeholder for now
  final int durationMinutes;
  final List<String> keyPoints;
  final String? thumbnailUrl;

  const VideoContent({
    required this.id,
    required this.title,
    required this.description,
    this.videoUrl = '',
    this.durationMinutes = 0,
    this.keyPoints = const [],
    this.thumbnailUrl,
  });

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      keyPoints: (json['keyPoints'] as List<dynamic>?)?.cast<String>() ?? [],
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'durationMinutes': durationMinutes,
        'keyPoints': keyPoints,
        'thumbnailUrl': thumbnailUrl,
      };
}

/// Job content model
class JobContent {
  final String id;
  final String title;
  final String organization;
  final String location;
  final String? salaryRange;
  final String? applyUrl;
  final String detailsText;
  final DateTime? applicationStart;
  final DateTime? applicationEnd;
  final String? eligibility;
  final String? jobType;
  final int? vacancies;

  const JobContent({
    required this.id,
    required this.title,
    required this.organization,
    required this.location,
    this.salaryRange,
    this.applyUrl,
    required this.detailsText,
    this.applicationStart,
    this.applicationEnd,
    this.eligibility,
    this.jobType,
    this.vacancies,
  });

  factory JobContent.fromJson(Map<String, dynamic> json) {
    return JobContent(
      id: json['id'] as String,
      title: json['title'] as String,
      organization: json['organization'] as String,
      location: json['location'] as String,
      salaryRange: json['salaryRange'] as String?,
      applyUrl: json['applyUrl'] as String?,
      detailsText: json['detailsText'] as String,
      applicationStart: json['applicationStart'] != null
          ? DateTime.parse(json['applicationStart'] as String)
          : null,
      applicationEnd: json['applicationEnd'] != null
          ? DateTime.parse(json['applicationEnd'] as String)
          : null,
      eligibility: json['eligibility'] as String?,
      jobType: json['jobType'] as String?,
      vacancies: json['vacancies'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'organization': organization,
        'location': location,
        'salaryRange': salaryRange,
        'applyUrl': applyUrl,
        'detailsText': detailsText,
        'applicationStart': applicationStart?.toIso8601String(),
        'applicationEnd': applicationEnd?.toIso8601String(),
        'eligibility': eligibility,
        'jobType': jobType,
        'vacancies': vacancies,
      };
}
