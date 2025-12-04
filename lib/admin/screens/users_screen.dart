import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: 'Users',
      body: Center(child: Text('User Management (Search, Role Assignment)')),
    );
  }
}
