import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/courses_list_screen.dart';
import 'screens/course_editor_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/lecture_editor_screen.dart';
import 'screens/combination_packs_screen.dart';
import 'screens/ebooks_screen.dart';
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
import 'screens/exam_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/batch_notes_screen.dart';
import 'screens/batch_planner_screen.dart';
import 'screens/batch_quiz_screen.dart';
import 'screens/payment_settings_screen.dart';
import 'screens/live_classes_screen.dart';
import 'screens/live_class_editor_screen.dart';
import 'screens/batch_dpp_screen.dart';
import 'screens/promo_codes_screen.dart';
import 'screens/test_series_list_screen.dart';
import 'screens/test_series_editor_screen.dart';
import 'screens/test_series_test_editor_screen.dart';
import 'models/test_series_models.dart';
import 'screens/notification_list_screen.dart';
import 'screens/notification_editor_screen.dart';
import 'screens/communities_list_screen.dart';
import 'screens/course_schedule_dashboard.dart';
import 'screens/course_schedule_rules_screen.dart';
import 'screens/poster_list_screen.dart';
import 'screens/poster_editor_screen.dart';
import 'package:eduverse/store/models/poster_model.dart';

class AdminRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/dashboard':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );
      case '/courses':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CoursesListScreen(),
        );
      case '/course_editor':
        final course = settings.arguments as AdminCourse?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CourseEditorScreen(course: course),
        );
      case '/course_detail':
        final course = settings.arguments as AdminCourse;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CourseDetailScreen(course: course),
        );
      case '/batch_notes':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BatchNotesScreen(
            courseId: args['courseId']!,
            batchId: args['batchId'] ?? '',
          ),
        );
      case '/batch_planner':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BatchPlannerScreen(
            courseId: args['courseId']!,
            batchId: args['batchId'] ?? '',
          ),
        );
      case '/batch_quizzes':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BatchQuizScreen(
            courseId: args['courseId']!,
            batchId: args['batchId'] ?? '',
          ),
        );
      case '/batch_dpps':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BatchDppScreen(
            courseId: args['courseId']!,
            batchId: args['batchId'] ?? '',
          ),
        );
      case '/lecture_editor':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LectureEditorScreen(
            courseId: args['courseId']!,
            batchId: args['batchId'] ?? '',
            initialResourceType: args['initialResourceType'],
          ),
        );
      case '/combination_packs':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CombinationPacksScreen(),
        );
      case '/ebooks_manager':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const EbooksScreen(),
        );
      case '/users':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const UsersScreen(),
        );
      case '/user_detail':
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => UserDetailScreen(userId: userId),
        );
      case '/enrollments':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const EnrollmentsScreen(),
        );
      case '/purchases':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PurchasesScreen(),
        );
      case '/feed_list':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const FeedListScreen(),
        );
      case '/feed_editor':
        final feedItem = settings.arguments as FeedItem?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FeedEditorScreen(feedItem: feedItem),
        );
      case '/quiz_editor':
        final feedItem = settings.arguments as FeedItem?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuizEditorScreen(feedItem: feedItem),
        );
      case '/settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      case '/payment_settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PaymentSettingsScreen(),
        );
      case '/live_classes':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LiveClassesScreen(
            courseId: args?['courseId'],
            batchId: args?['batchId'],
          ),
        );
      case '/live_class_editor':
        final args = settings.arguments is Map
            ? Map<String, dynamic>.from(settings.arguments as Map)
            : null;
        // Handle both old (direct object) and new (map) argument formats for backward compatibility if needed,
        // though we are switching to map.
        if (args != null && args.containsKey('item')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => LiveClassEditorScreen(
              liveClass: args['item'],
              courseId: args['courseId'],
              batchId: args['batchId'],
            ),
          );
        } else if (settings.arguments is AdminLiveClass) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => LiveClassEditorScreen(
              liveClass: settings.arguments as AdminLiveClass,
            ),
          );
        }
        // New creation case
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LiveClassEditorScreen(
            liveClass: null,
            courseId: args?['courseId'],
            batchId: args?['batchId'],
          ),
        );
      case '/promo_codes':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PromoCodesScreen(),
        );
      case '/test_series':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TestSeriesListScreen(),
        );
      case '/test_series_editor':
        final ts = settings.arguments as AdminTestSeries?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TestSeriesEditorScreen(testSeries: ts),
        );
      case '/test_series_test_editor':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TestSeriesTestEditorScreen(
            testSeriesId: args['testSeriesId'],
            testId: args['testId'],
            order: args['order'] ?? 0,
            initialData: args['initialData'],
          ),
        );
      case '/notifications':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NotificationListScreen(),
        );
      case '/notification_editor':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NotificationEditorScreen(),
        );
      case '/posters':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PosterListScreen(),
        );
      case '/poster_editor':
        final poster = settings.arguments as Poster?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PosterEditorScreen(poster: poster),
        );
      case '/communities':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CommunitiesListScreen(),
        );
      case '/exams':
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider<StudyController>(
            create: (_) => StudyController(
              repository: StudyRepositoryImpl(),
              userId: userId,
            ),
            child: const ExamManagementScreen(),
          ),
        );
      case '/course_schedule_dashboard':
        final args = settings.arguments;
        final String courseId = args is Map ? args['courseId'] : args as String;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CourseScheduleDashboard(courseId: courseId),
        );
      case '/course_schedule_rules':
        final args = settings.arguments;
        final String courseId = args is Map ? args['courseId'] : args as String;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CourseScheduleRulesScreen(courseId: courseId),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(body: Center(child: Text('404'))),
        );
    }
  }
}
