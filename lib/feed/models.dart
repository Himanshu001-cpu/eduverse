import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
export 'package:eduverse/feed/models/feed_models.dart';

enum ContentType {
  all,
  answerWriting,
  currentAffairs,
  articles,
  videos,
  quizzes,
  jobs,
}

class TrendingPost {
  final String title;
  final String likes;
  final String comments;
  final String emoji;
  final Color color;

  const TrendingPost({
    required this.title,
    required this.likes,
    required this.comments,
    required this.emoji,
    required this.color,
  });
}

class FeedItem {
  final String id;
  final ContentType type;
  final String title;
  final String description;
  final String categoryLabel;
  final String emoji;
  final Color color;
  final String thumbnailUrl;
  final bool isPublic;

  // Extended content fields for different types
  final ArticleContent? articleContent;
  final CurrentAffairsContent? currentAffairsContent;
  final AnswerWritingContent? answerWritingContent;
  final VideoContent? videoContent;
  final List<QuizQuestion>? quizQuestions;
  final String? quizInstructions;
  final int? quizTimeLimitMinutes;
  final int? quizTimeLimitSeconds; // New: stores time in seconds for precision
  final double? quizMarksPerQuestion;
  final double? quizNegativeMarking;
  final JobContent? jobContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final int viewCount;

  FeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.categoryLabel,
    required this.emoji,
    required this.color,
    this.thumbnailUrl = '',
    this.articleContent,
    this.currentAffairsContent,
    this.answerWritingContent,
    this.videoContent,
    this.quizQuestions,
    this.quizInstructions,
    this.quizTimeLimitMinutes,
    this.quizTimeLimitSeconds,
    this.quizMarksPerQuestion,
    this.quizNegativeMarking,
    this.jobContent,
    this.isPublic = true,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get buttonLabel {
    switch (type) {
      case ContentType.videos:
        return 'Watch Now';
      case ContentType.quizzes:
        return 'Start Quiz';
      case ContentType.jobs:
        return 'View Job';
      case ContentType.answerWriting:
        return 'Practice Now';
      default:
        return 'Read More';
    }
  }

  IconData get buttonIcon {
    switch (type) {
      case ContentType.videos:
        return Icons.play_circle_outline;
      case ContentType.quizzes:
        return Icons.quiz_outlined;
      case ContentType.jobs:
        return Icons.work_outline;
      case ContentType.answerWriting:
        return Icons.edit_note;
      default:
        return Icons.arrow_forward;
    }
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // Parse extended content based on type
    VideoContent? videoContent;
    ArticleContent? articleContent;
    JobContent? jobContent;
    CurrentAffairsContent? currentAffairsContent;
    AnswerWritingContent? answerWritingContent;
    List<QuizQuestion>? quizQuestions;

    if (json['videoContent'] != null) {
      videoContent = VideoContent.fromJson(
        json['videoContent'] as Map<String, dynamic>,
      );
    }
    if (json['articleContent'] != null) {
      articleContent = ArticleContent.fromJson(
        json['articleContent'] as Map<String, dynamic>,
      );
    }
    if (json['jobContent'] != null) {
      jobContent = JobContent.fromJson(
        json['jobContent'] as Map<String, dynamic>,
      );
    }
    if (json['currentAffairsContent'] != null) {
      currentAffairsContent = CurrentAffairsContent.fromJson(
        json['currentAffairsContent'] as Map<String, dynamic>,
      );
    }
    if (json['answerWritingContent'] != null) {
      answerWritingContent = AnswerWritingContent.fromJson(
        json['answerWritingContent'] as Map<String, dynamic>,
      );
    }
    if (json['quizQuestions'] != null) {
      quizQuestions = (json['quizQuestions'] as List<dynamic>)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    return FeedItem(
      id: json['id'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContentType.articles,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      categoryLabel: json['categoryLabel'] as String,
      emoji: json['emoji'] as String,
      color: Color(json['color'] as int),
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      isPublic: json['isPublic'] as bool? ?? true,
      videoContent: videoContent,
      articleContent: articleContent,
      jobContent: jobContent,
      currentAffairsContent: currentAffairsContent,
      answerWritingContent: answerWritingContent,
      quizQuestions: quizQuestions,
      quizInstructions: json['quizInstructions'] as String?,
      quizTimeLimitMinutes: json['quizTimeLimitMinutes'] as int?,
      quizTimeLimitSeconds: json['quizTimeLimitSeconds'] as int?,
      quizMarksPerQuestion: (json['quizMarksPerQuestion'] as num?)?.toDouble(),
      quizNegativeMarking: (json['quizNegativeMarking'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime(2000), // Default to old date for legacy items
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime(2000), // Default to old date for legacy items
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'categoryLabel': categoryLabel,
    'emoji': emoji,
    'color': color.toARGB32(),
    'thumbnailUrl': thumbnailUrl,
    'isPublic': isPublic,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'viewCount': viewCount,
    if (videoContent != null) 'videoContent': videoContent!.toJson(),
    if (articleContent != null) 'articleContent': articleContent!.toJson(),
    if (jobContent != null) 'jobContent': jobContent!.toJson(),
    if (currentAffairsContent != null)
      'currentAffairsContent': currentAffairsContent!.toJson(),
    if (answerWritingContent != null)
      'answerWritingContent': answerWritingContent!.toJson(),
    if (quizQuestions != null)
      'quizQuestions': quizQuestions!.map((q) => q.toJson()).toList(),
    if (quizInstructions != null) 'quizInstructions': quizInstructions,
    if (quizTimeLimitMinutes != null)
      'quizTimeLimitMinutes': quizTimeLimitMinutes,
    if (quizTimeLimitSeconds != null)
      'quizTimeLimitSeconds': quizTimeLimitSeconds,
    if (quizMarksPerQuestion != null)
      'quizMarksPerQuestion': quizMarksPerQuestion,
    if (quizNegativeMarking != null) 'quizNegativeMarking': quizNegativeMarking,
  };
}
