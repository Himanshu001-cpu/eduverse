import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'admin_router.dart';
import 'services/firebase_admin_service.dart';
import 'screens/admin_login_screen.dart';

/// Entry point for Admin panel from the main app.
/// Checks if user is admin before showing admin UI.
class AdminEntryPage extends StatefulWidget {
  const AdminEntryPage({super.key});

  @override
  State<AdminEntryPage> createState() => _AdminEntryPageState();
}

class _AdminEntryPageState extends State<AdminEntryPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      if (_authService.currentUser == null) {
         if (mounted) {
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
           );
         }
         return;
      }

      final isAdmin = await _authService.isAdmin();

      // Ensure Firestore data matches for the hardcoded admin
      if (isAdmin && _authService.currentUser?.email == 'admin@eduverse.com') {
         await _authService.syncAdminRole();
      }

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to verify admin status';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying admin access...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _checkAdminStatus();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      // Not an admin - automatically go back without showing any message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      
      // Show a simple loading indicator while navigating back
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // User is admin - show the admin app with proper routing
    return _AdminAppWithBackHandling(
      onExitAdminPanel: () => Navigator.of(context).pop(),
    );
  }
}

/// Separate widget to handle admin app with proper back button handling
class _AdminAppWithBackHandling extends StatefulWidget {
  final VoidCallback onExitAdminPanel;
  
  const _AdminAppWithBackHandling({required this.onExitAdminPanel});
  
  @override
  State<_AdminAppWithBackHandling> createState() => _AdminAppWithBackHandlingState();
}

class _AdminAppWithBackHandlingState extends State<_AdminAppWithBackHandling> {
  final GlobalKey<NavigatorState> _adminNavigatorKey = GlobalKey<NavigatorState>();
  late final _AdminRouteObserver _routeObserver;
  
  @override
  void initState() {
    super.initState();
    _routeObserver = _AdminRouteObserver(onRouteChanged: _onRouteChanged);
  }
  
  void _onRouteChanged(String routeName) {
    // This is called from the observer, which may be triggered during build
    // We use a post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _showExitConfirmation() async {
    // Use the admin navigator's context for showing dialog so it appears correctly
    final navigatorContext = _adminNavigatorKey.currentContext;
    if (navigatorContext == null) {
      widget.onExitAdminPanel();
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: navigatorContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Admin Panel'),
        content: const Text('Are you sure you want to exit the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      widget.onExitAdminPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider<FirebaseAdminService>(
      create: (_) => FirebaseAdminService(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          
          // Check if we're on dashboard using the observer's tracked route
          final currentRoute = _routeObserver.currentRoute;
          
          // If on dashboard (only one route in stack), show exit confirmation
          if (currentRoute == '/dashboard') {
            _showExitConfirmation();
          } else {
            // Not on dashboard, navigate back within admin panel
            final canPop = _adminNavigatorKey.currentState?.canPop() ?? false;
            if (canPop) {
              _adminNavigatorKey.currentState?.pop();
            } else {
              // If we cannot pop (shouldn't happen but safety check), show exit
              _showExitConfirmation();
            }
          }
        },
        child: MaterialApp(
          navigatorKey: _adminNavigatorKey,
          navigatorObservers: [_routeObserver],
          debugShowCheckedModeBanner: false,
          title: 'The Eduverse Admin',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          initialRoute: '/dashboard',
          onGenerateRoute: AdminRouter.generateRoute,
        ),
      ),
    );
  }
}

/// Navigator observer that tracks the current route in the admin panel
class _AdminRouteObserver extends NavigatorObserver {
  final List<String> _routeStack = ['/dashboard'];
  final Function(String) onRouteChanged;
  
  _AdminRouteObserver({required this.onRouteChanged});
  
  String get currentRoute => _routeStack.isNotEmpty ? _routeStack.last : '/dashboard';
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? '/dashboard';
    _routeStack.add(routeName);
    onRouteChanged(routeName);
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_routeStack.isNotEmpty) {
      _routeStack.removeLast();
    }
    // Ensure we always have at least dashboard in the stack
    if (_routeStack.isEmpty) {
      _routeStack.add('/dashboard');
    }
    onRouteChanged(currentRoute);
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_routeStack.isNotEmpty) {
      _routeStack.removeLast();
    }
    final routeName = newRoute?.settings.name ?? '/dashboard';
    _routeStack.add(routeName);
    onRouteChanged(routeName);
  }
  
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    final routeName = route.settings.name;
    if (routeName != null) {
      _routeStack.remove(routeName);
    }
    if (_routeStack.isEmpty) {
      _routeStack.add('/dashboard');
    }
    onRouteChanged(currentRoute);
  }
}

