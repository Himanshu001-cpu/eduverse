/// Acceptance Criteria:
/// - Admin panel runs in Flutter Web and mobile.
/// - Admins can create/edit/publish/unpublish courses and batches.
/// - Admin can upload media to Storage and attach to lectures.
/// - Creating purchase (simulated) triggers enrollment flow via Cloud Function.
/// - Audit entries exist for create/edit/enroll/refund actions.
/// - Firestore & Storage rules prevent unauthorized writes.
/// - Local emulator commands documented and runnable.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_admin_service.dart';
import 'services/auth_guard.dart';
import 'admin_router.dart';
import 'screens/dashboard_screen.dart';

// Entry point for standalone admin app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAdminService>(create: (_) => FirebaseAdminService()),
      ],
      child: MaterialApp(
        title: 'The Eduverse Admin',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: const AuthGuard(child: DashboardScreen()),
        onGenerateRoute: AdminRouter.generateRoute,
      ),
    );
  }
}
