import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/models/test_series_models.dart';
import '../../admin/widgets/admin_scaffold.dart';
import 'test_series_test_editor_screen.dart';

class TestSeriesTestsListScreen extends StatelessWidget {
  final AdminTestSeries testSeries;

  const TestSeriesTestsListScreen({super.key, required this.testSeries});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Tests: ${testSeries.title}',
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('test_series')
            .doc(testSeries.id)
            .collection('tests')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tests = snapshot.data!.docs;

          if (tests.isEmpty) {
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
                    'No tests added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _openEditor(context, null, tests.length),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Test'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length + 1, // +1 for the Add New button
            itemBuilder: (context, index) {
              if (index == tests.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditor(context, null, tests.length),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Test'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              }

              final doc = tests[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(data['title'] ?? 'Untitled Test'),
                  subtitle: Text(
                    '${data['questions']?.length ?? 0} Questions • ${data['durationMinutes'] ?? 0} min',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _openEditor(context, doc.id, index, data: data),
                        tooltip: 'Edit Test',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteTest(context, doc.id, doc.reference),
                        tooltip: 'Delete Test',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    String? testId,
    int order, {
    Map<String, dynamic>? data,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestSeriesTestEditorScreen(
          testSeriesId: testSeries.id,
          testId: testId,
          order: order,
          initialData: data,
        ),
      ),
    );
  }

  Future<void> _deleteTest(
    BuildContext context,
    String testId,
    DocumentReference ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Test?'),
        content: const Text(
          'Are you sure you want to delete this test? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.delete();

        // Update test count in parent test series
        final tsRef = FirebaseFirestore.instance
            .collection('test_series')
            .doc(testSeries.id);
        await tsRef.update({'totalTests': FieldValue.increment(-1)});

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Test deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
