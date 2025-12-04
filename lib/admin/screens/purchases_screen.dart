import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: 'Purchases',
      body: Center(child: Text('Purchases List & Refund Actions')),
    );
  }
}
