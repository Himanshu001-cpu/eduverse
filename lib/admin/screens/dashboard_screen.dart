import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/data_table_card.dart';
import '../services/admin_stats_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dashboard',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DashboardStats>(
                stream: AdminStatsService().getDashboardStatsStream(),
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  final isLoading = !snapshot.hasData;
                  
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        title: 'Total Users',
                        value: isLoading ? '...' : NumberFormat('#,###').format(stats!.totalUsers),
                      ),
                      _StatCard(
                        title: 'Active Courses',
                        value: isLoading ? '...' : stats!.activeCourses.toString(),
                      ),
                      _StatCard(
                        title: 'Enrollments Today',
                        value: isLoading ? '...' : stats!.enrollmentsToday.toString(),
                      ),
                      _StatCard(
                        title: 'Revenue (Today)',
                        value: isLoading ? '...' : '₹${NumberFormat('#,###').format(stats!.revenueToday)}',
                      ),
                    ],
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Recent Audit Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            DataTableCard(
              columns: const [DataColumn(label: Text('Action')), DataColumn(label: Text('Admin')), DataColumn(label: Text('Time'))],
              rows: const [
                DataRow(cells: [DataCell(Text('create_course')), DataCell(Text('admin@edu.com')), DataCell(Text('10:00 AM'))]),
                DataRow(cells: [DataCell(Text('refund_purchase')), DataCell(Text('support@edu.com')), DataCell(Text('09:45 AM'))]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
