import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/feed_item_card.dart';

class FeedListScreen extends StatelessWidget {
  const FeedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = FeedRepository();

    return AdminScaffold(
      title: 'Feed Management',
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/feed_editor'),
        tooltip: 'Create New Feed Item',
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<FeedItem>>(
        stream: repository.getAllFeedItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/feed_list'),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No feed items yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click the + button to create your first feed item',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return FeedItemCard(
                item: item,
                onEdit: () => Navigator.pushNamed(
                  context,
                  '/feed_editor',
                  arguments: item,
                ),
                onDelete: () => _confirmDelete(context, repository, item),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, FeedRepository repository, FeedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Feed Item'),
        content: Text('Are you sure you want to delete "${item.title}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await repository.deleteFeedItem(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${item.title}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting item: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
