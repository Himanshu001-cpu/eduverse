import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_admin_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;

  const AuthGuard({super.key, required this.child, this.requiredRole = 'admin'});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseAdminService>(context);
    
    return StreamBuilder(
      stream: service.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          // Redirect to login
          // In a real app, you'd navigate to a login screen.
          // For this standalone admin app, we might show a login widget here if not logged in.
          return const Scaffold(body: Center(child: Text('Please Log In')));
        }

        // Check claims (async) - simplified for UI sync, ideally load claims on login
        // For now, we assume if logged in, we show the UI, and service calls will fail if unauthorized
        return child;
      },
    );
  }
}
