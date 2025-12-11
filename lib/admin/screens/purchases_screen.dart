import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: 'Purchases',
      body: Center(child: Text('Purchases List & Refund Actions')),
    );
  }
}
