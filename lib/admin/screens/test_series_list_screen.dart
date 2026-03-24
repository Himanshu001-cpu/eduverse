import 'package:flutter/material.dart';
import '../services/test_series_service.dart';
import '../models/test_series_models.dart';
import '../widgets/admin_scaffold.dart';

class TestSeriesListScreen extends StatelessWidget {
  const TestSeriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = TestSeriesService();

    return AdminScaffold(
      title: 'Test Series',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/test_series_editor'),
        icon: const Icon(Icons.add),
        label: const Text('New Test Series'),
      ),
      body: StreamBuilder<List<AdminTestSeries>>(
        stream: service.getTestSeriesList(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSeries = snapshot.data!;

          final published = allSeries
              .where((s) => s.visibility == 'published')
              .toList();
          final drafts = allSeries
              .where((s) => s.visibility == 'draft')
              .toList();
          final archived = allSeries
              .where((s) => s.visibility == 'archived')
              .toList();

          if (allSeries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No test series yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to create your first test series',
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (published.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Published',
                    published.length,
                    Colors.green,
                    Icons.public,
                  ),
                  const SizedBox(height: 8),
                  ...published.map(
                    (ts) => _TestSeriesCard(testSeries: ts, service: service),
                  ),
                  const SizedBox(height: 24),
                ],
                if (drafts.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Drafts',
                    drafts.length,
                    Colors.orange,
                    Icons.edit_note,
                  ),
                  const SizedBox(height: 8),
                  ...drafts.map(
                    (ts) => _TestSeriesCard(testSeries: ts, service: service),
                  ),
                  const SizedBox(height: 24),
                ],
                if (archived.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Archived',
                    archived.length,
                    Colors.grey,
                    Icons.archive,
                  ),
                  const SizedBox(height: 8),
                  ...archived.map(
                    (ts) => _TestSeriesCard(
                      testSeries: ts,
                      service: service,
                      isArchived: true,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestSeriesCard extends StatelessWidget {
  final AdminTestSeries testSeries;
  final TestSeriesService service;
  final bool isArchived;

  const _TestSeriesCard({
    required this.testSeries,
    required this.service,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: testSeries.gradientColors.isNotEmpty
                  ? testSeries.gradientColors.map((c) => Color(c)).toList()
                  : [Colors.green, Colors.greenAccent],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(testSeries.emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          testSeries.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isArchived ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            _buildVisibilityBadge(),
            const SizedBox(width: 8),
            if (testSeries.subject.isNotEmpty)
              Text(
                testSeries.subject,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(width: 8),
            Text(
              '${testSeries.totalTests} tests',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (testSeries.linkedBatches.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(Icons.link, size: 14, color: Colors.blue.shade400),
              Text(
                ' ${testSeries.linkedBatches.length}',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade400),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(
          context,
          '/test_series_editor',
          arguments: testSeries,
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge() {
    Color color;
    String text;

    switch (testSeries.visibility) {
      case 'published':
        color = Colors.green;
        text = 'PUBLISHED';
        break;
      case 'archived':
        color = Colors.grey;
        text = 'ARCHIVED';
        break;
      default:
        color = Colors.orange;
        text = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          '/test_series_editor',
          arguments: testSeries,
        );
        break;

      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Delete Test Series')),
              ],
            ),
            content: Text(
              'Are you sure you want to PERMANENTLY delete "${testSeries.title}"?\n\n⚠️ This action cannot be undone!\n\nAll tests within this series will also be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Forever'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          try {
            await service.deleteTestSeries(testSeries.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test series deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
    }
  }
}
