import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/courses_list_screen.dart';
import 'screens/course_editor_screen.dart';
import 'screens/batch_editor_screen.dart';
import 'screens/lecture_editor_screen.dart';
import 'screens/users_screen.dart';
import 'screens/enrollments_screen.dart';
import 'screens/purchases_screen.dart';
import 'screens/feed_editor_screen.dart';
import 'screens/quiz_editor_screen.dart';
import 'screens/settings_screen.dart';
import 'models/admin_models.dart';
import 'package:eduverse/feed/models.dart';

class AdminRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/courses':
        return MaterialPageRoute(builder: (_) => const CoursesListScreen());
      case '/course_editor':
        final course = settings.arguments as AdminCourse?;
        return MaterialPageRoute(builder: (_) => CourseEditorScreen(course: course));
      case '/batch_editor':
        final courseId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => BatchEditorScreen(courseId: courseId));
      case '/lecture_editor':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(builder: (_) => LectureEditorScreen(courseId: args['courseId']!, batchId: args['batchId']!));
      case '/users':
        return MaterialPageRoute(builder: (_) => const UsersScreen());
      case '/enrollments':
        return MaterialPageRoute(builder: (_) => const EnrollmentsScreen());
      case '/purchases':
        return MaterialPageRoute(builder: (_) => const PurchasesScreen());
      case '/feed_editor':
        return MaterialPageRoute(builder: (_) => const FeedEditorScreen());
      case '/quiz_editor':
        final feedItem = settings.arguments as FeedItem?;
        return MaterialPageRoute(builder: (_) => QuizEditorScreen(feedItem: feedItem));
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('404'))));
    }
  }
}
