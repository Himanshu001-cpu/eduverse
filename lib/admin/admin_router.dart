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
import 'screens/feed_list_screen.dart';
import 'screens/quiz_editor_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_detail_screen.dart';
import 'models/admin_models.dart';
import 'package:eduverse/feed/models.dart';
import 'screens/batch_detail_screen.dart';
import 'screens/batch_notes_screen.dart';
import 'screens/batch_planner_screen.dart';
import 'screens/batch_quiz_screen.dart';
import 'screens/payment_settings_screen.dart';
import 'screens/live_classes_screen.dart';
import 'screens/live_class_editor_screen.dart';

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
      case '/batch_detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => BatchDetailScreen(courseId: args['courseId'], batch: args['batch']));
      case '/batch_notes':
         final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(builder: (_) => BatchNotesScreen(courseId: args['courseId']!, batchId: args['batchId']!));
      case '/batch_planner':
         final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(builder: (_) => BatchPlannerScreen(courseId: args['courseId']!, batchId: args['batchId']!));
      case '/batch_quizzes':
         final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(builder: (_) => BatchQuizScreen(courseId: args['courseId']!, batchId: args['batchId']!));
      case '/lecture_editor':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(builder: (_) => LectureEditorScreen(courseId: args['courseId']!, batchId: args['batchId']!));
      case '/users':
        return MaterialPageRoute(builder: (_) => const UsersScreen());
      case '/user_detail':
        final userId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => UserDetailScreen(userId: userId));
      case '/enrollments':
        return MaterialPageRoute(builder: (_) => const EnrollmentsScreen());
      case '/purchases':
        return MaterialPageRoute(builder: (_) => const PurchasesScreen());
      case '/feed_list':
        return MaterialPageRoute(builder: (_) => const FeedListScreen());
      case '/feed_editor':
        final feedItem = settings.arguments as FeedItem?;
        return MaterialPageRoute(builder: (_) => FeedEditorScreen(feedItem: feedItem));
      case '/quiz_editor':
        final feedItem = settings.arguments as FeedItem?;
        return MaterialPageRoute(builder: (_) => QuizEditorScreen(feedItem: feedItem));
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/payment_settings':
        return MaterialPageRoute(builder: (_) => const PaymentSettingsScreen());
      case '/live_classes':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => LiveClassesScreen(courseId: args?['courseId'], batchId: args?['batchId']));
      case '/live_class_editor':
        final args = settings.arguments as Map<String, dynamic>?;
        // Handle both old (direct object) and new (map) argument formats for backward compatibility if needed, 
        // though we are switching to map.
        if (args != null && args.containsKey('item')) {
           return MaterialPageRoute(builder: (_) => LiveClassEditorScreen(
             liveClass: args['item'],
             courseId: args['courseId'],
             batchId: args['batchId'],
           ));
        } else if (settings.arguments is AdminLiveClass) {
           return MaterialPageRoute(builder: (_) => LiveClassEditorScreen(liveClass: settings.arguments as AdminLiveClass));
        }
        // New creation case
        return MaterialPageRoute(builder: (_) => LiveClassEditorScreen(
           liveClass: null,
           courseId: args?['courseId'],
           batchId: args?['batchId'],
        ));
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('404'))));
    }
  }
}

