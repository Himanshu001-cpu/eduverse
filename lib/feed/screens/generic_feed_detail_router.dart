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
    Widget page;

    switch (item.type) {
      case ContentType.articles:
        page = ArticleDetailPage(item: item);
        break;
      case ContentType.currentAffairs:
        page = CurrentAffairsDetailPage(item: item);
        break;
      case ContentType.answerWriting:
        page = AnswerWritingPage(item: item);
        break;
      case ContentType.videos:
        page = VideoDetailPage(item: item);
        break;
      case ContentType.quizzes:
        page = QuizPage(item: item);
        break;
      case ContentType.jobs:
        page = JobDetailPage(item: item);
        break;
      case ContentType.all:
        // Fallback - should not happen normally
        page = ArticleDetailPage(item: item);
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
