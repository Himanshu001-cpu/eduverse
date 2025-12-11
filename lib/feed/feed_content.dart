import 'package:flutter/material.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'feed_card.dart';
import 'models.dart';

class FeedContent extends StatelessWidget {
  final ContentType type;

  const FeedContent({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    // Determine the type filter only if specific type is requested and not 'all'
    // Actually Repository handles 'all' automatically if type is passed as 'all' or null?
    // My Repository logic: if (type != null && type != ContentType.all) filter.
    // So passing ContentType.all works fine.
    
    return StreamBuilder<List<FeedItem>>(
      stream: FeedRepository().getFeedItems(type: type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No content available',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) => FeedCard(item: items[i]),
        );
      },
    );
  }
}
