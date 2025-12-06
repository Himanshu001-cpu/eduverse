import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  const AdminScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eduverse Admin: $title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<FirebaseAdminService>().signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Admin Menu', style: TextStyle(fontSize: 24))),
            _navItem(context, 'Dashboard', '/dashboard', Icons.dashboard),
            _navItem(context, 'Courses', '/courses', Icons.school),
            _navItem(context, 'Users', '/users', Icons.people),
            _navItem(context, 'Purchases', '/purchases', Icons.shopping_cart),
            _navItem(context, 'Feed Editor', '/feed_editor', Icons.feed),
            _navItem(context, 'Settings', '/settings', Icons.settings),
          ],
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _navItem(BuildContext context, String title, String route, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.pushReplacementNamed(context, route),
    );
  }
}
