import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: 'Settings',
      body: Center(child: Text('Admin Settings & Maintenance Mode')),
    );
  }
}
