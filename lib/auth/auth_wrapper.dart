import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/web/landing/landing_page.dart';
import 'login_page.dart';
import '../navigation/main_navigation_page.dart';

/// Wrapper widget that manages authentication state.
/// Shows WebHomepage for web visitors (not authenticated),
/// LoginPage for mobile users (not authenticated),
/// otherwise shows the main app content.
/// Also manages screenshot protection based on user role.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  String? _lastUserId;

  Future<void> _updateScreenProtection(User user) async {
    if (kIsWeb) return;

    final isAdmin = await _authService.isAdmin();
    if (isAdmin) {
      // Allow admins to take screenshots
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      debugPrint('Screenshot protection DISABLED for admin: ${user.email}');
    } else {
      // Prevent non-admin users from taking screenshots
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
      debugPrint('Screenshot protection ENABLED for user: ${user.email}');
    }
  }

  Future<void> _disableScreenProtection() async {
    if (kIsWeb) return;
    // When user is not authenticated, no need for protection
    // (nothing sensitive on login screen)
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // Show error if something went wrong
        if (snapshot.hasError) {
          return _ErrorScreen(
            error: snapshot.error.toString(),
            onRetry: () {
              // Force rebuild
            },
          );
        }

        // User is authenticated -> show main app
        if (snapshot.hasData && snapshot.data != null) {
          // Update screenshot protection when user changes
          final user = snapshot.data!;
          if (_lastUserId != user.uid) {
            _lastUserId = user.uid;
            _updateScreenProtection(user);
          }
          return const MainNavigationPage();
        }

        // User is not authenticated
        _lastUserId = null;
        _disableScreenProtection();

        // Web: show landing page with features
        // Mobile: show login page
        if (kIsWeb) {
          return const LandingPage();
        }
        return const LoginPage();
      },
    );
  }
}

/// Loading screen shown while checking auth state
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // App Name
              const Text(
                'EduVerse',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error screen shown if auth check fails
class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF667eea),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
