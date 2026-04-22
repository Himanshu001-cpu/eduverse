import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:eduverse/core/firebase/firebase_initializer.dart';
import 'package:eduverse/core/notifications/notification_service.dart';
import 'package:eduverse/core/services/deep_link_service.dart';
import 'package:eduverse/core/services/deep_link_screens.dart';
import 'auth/auth_wrapper.dart';
import 'package:eduverse/settings/delete_account_page.dart';
import 'package:eduverse/web/landing/landing_page.dart';

void main() async {
  // Use path URLs (no /#/) for web deep linking
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseInitializer.init();

    // Initialize push notifications (non-blocking)
    NotificationService().initialize().catchError((e) {
      debugPrint('FCM initialization error (non-fatal): $e');
    });

    runApp(const LearningApp());
  } catch (e) {
    runApp(InitializationErrorApp(error: e.toString()));
  }
}

class InitializationErrorApp extends StatelessWidget {
  final String error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your firebase_options.dart configuration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LearningApp extends StatefulWidget {
  const LearningApp({super.key});

  @override
  State<LearningApp> createState() => _LearningAppState();
}

class _LearningAppState extends State<LearningApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize deep link handling and notification navigation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService().initialize(_navigatorKey);
      // Set navigator key for push notification navigation
      NotificationService().setNavigatorKey(_navigatorKey);
    });
  }

  @override
  void dispose() {
    DeepLinkService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'The Eduverse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      // Route generator for deep link routes with parameters
      onGenerateRoute: (settings) {
        // Handle /course route
        if (settings.name == '/course') {
          final courseId = settings.arguments as String?;
          if (courseId != null) {
            return MaterialPageRoute(
              builder: (_) => DeepLinkCourseScreen(courseId: courseId),
            );
          }
        }

        // Handle /batch route
        if (settings.name == '/batch') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (_) => DeepLinkBatchScreen(
                courseId: args['courseId'] as String,
                batchId: args['batchId'] as String,
              ),
            );
          }
        }

        // Handle /feed route
        if (settings.name == '/feed') {
          final feedId = settings.arguments as String?;
          if (feedId != null) {
            return MaterialPageRoute(
              builder: (_) => DeepLinkFeedScreen(feedId: feedId),
            );
          }
        }

        return null;
      },
      routes: {
        '/delete-account': (context) => const DeleteAccountPage(),
        '/landing': (context) => const LandingPage(),
      },
      home: const AuthWrapper(),
    );
  }
}
