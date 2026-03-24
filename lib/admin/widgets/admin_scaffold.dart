import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../screens/admin_login_screen.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from admin panel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<FirebaseAdminService>().signOut();

      if (context.mounted) {
        // Navigate back to the admin login screen, clearing all routes
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isDashboard = currentRoute == '/dashboard';

    return Scaffold(
      appBar: AppBar(
        // Only show back button on sub-screens, never on dashboard
        leading: !isDashboard
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null, // null lets the default drawer icon show on dashboard
        title: Text('The Eduverse Admin: $title'),
        actions: [
          // Add menu button on sub-screens to still access the drawer
          if (!isDashboard)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ...?actions,
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Admin Menu', style: TextStyle(fontSize: 24)),
            ),
            _navItem(context, 'Dashboard', '/dashboard', Icons.dashboard),
            _navItem(context, 'Courses', '/courses', Icons.school),
            _navItem(context, 'Users', '/users', Icons.people),
            _navItem(context, 'Purchases', '/purchases', Icons.shopping_cart),
            _navItem(context, 'Enrollments', '/enrollments', Icons.how_to_reg),
            _navItem(context, 'Promo Codes', '/promo_codes', Icons.local_offer),
            _navItem(context, 'Test Series', '/test_series', Icons.quiz),
            _navItem(context, 'Feed Management', '/feed_list', Icons.feed),
            _navItem(
              context,
              'Free Live Classes',
              '/live_classes',
              Icons.live_tv,
            ),
            _navItem(
              context,
              'Payment Settings',
              '/payment_settings',
              Icons.payment,
            ),
            _navItem(context, 'Settings', '/settings', Icons.settings),
          ],
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _navItem(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      onTap: () {
        // Close the drawer first
        Navigator.pop(context);

        // If already on this route, do nothing
        if (isSelected) return;

        // If navigating to dashboard, replace all routes to clear history
        if (route == '/dashboard') {
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
        } else {
          // For other routes, use pushNamed to preserve history
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
