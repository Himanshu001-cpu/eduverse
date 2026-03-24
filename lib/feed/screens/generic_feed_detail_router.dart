// file: lib/feed/screens/generic_feed_detail_router.dart
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/screens/article_detail_page.dart';
import 'package:eduverse/feed/screens/current_affairs_detail_page.dart';
import 'package:eduverse/feed/screens/answer_writing_page.dart';
import 'package:eduverse/feed/screens/video_detail_page.dart';
import 'package:eduverse/feed/screens/quiz_page.dart';
import 'package:eduverse/feed/screens/job_detail_page.dart';

/// Router for navigating to the appropriate detail screen based on ContentType.
class FeedDetailRouter {
  /// Opens the appropriate detail screen based on the FeedItem's type.
  static void open(BuildContext context, FeedItem item) {
    final page = _getPage(item);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Opens the detail screen with replacement (for deep links).
  /// This replaces the current screen instead of pushing on top.
  static void openWithReplacement(BuildContext context, FeedItem item) {
    final page = _getPage(item);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Gets the appropriate page widget for the feed item type.
  static Widget _getPage(FeedItem item) {
    switch (item.type) {
      case ContentType.articles:
        return ArticleDetailPage(item: item);
      case ContentType.currentAffairs:
        return CurrentAffairsDetailPage(item: item);
      case ContentType.answerWriting:
        return AnswerWritingPage(item: item);
      case ContentType.videos:
        return VideoDetailPage(item: item);
      case ContentType.quizzes:
        return QuizPage(item: item);
      case ContentType.jobs:
        return JobDetailPage(item: item);
      case ContentType.all:
        // Fallback - should not happen normally
        return ArticleDetailPage(item: item);
    }
  }
}
