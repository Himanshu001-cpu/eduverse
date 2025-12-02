import 'package:flutter/material.dart';

enum ContentType { all, answerWriting, currentAffairs, articles, videos, quizzes, jobs }

class TrendingPost {
  final String title;
  final String likes;
  final String comments;
  final String emoji;
  final Color color;

  TrendingPost({required this.title, required this.likes, required this.comments, required this.emoji, required this.color});
}

class FeedItem {
  final ContentType type;
  final String title;
  final String description;
  final String categoryLabel;
  final String emoji;
  final Color color;

  FeedItem({
    required this.type,
    required this.title,
    required this.description,
    required this.categoryLabel,
    required this.emoji,
    required this.color,
  });

  String get buttonLabel {
    switch (type) {
      case ContentType.videos:
        return 'Watch Now';
      case ContentType.quizzes:
        return 'Start Quiz';
      case ContentType.jobs:
        return 'View Job';
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
      default:
        return Icons.arrow_forward;
    }
  }
}
