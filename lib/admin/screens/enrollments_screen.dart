import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';

class EnrollmentsScreen extends StatelessWidget {
  const EnrollmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: 'Enrollments',
      body: Center(child: Text('Enrollments List & Manual Enroll')),
    );
  }
}
