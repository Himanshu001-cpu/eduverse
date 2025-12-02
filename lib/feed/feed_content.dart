import 'package:flutter/material.dart';
import 'feed_data.dart';
import 'feed_card.dart';
import 'models.dart';

class FeedContent extends StatelessWidget {
  final ContentType type;

  const FeedContent({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<FeedItem> items = type == ContentType.all
        ? FeedData.feedItems
        : FeedData.feedItems.where((e) => e.type == type).toList();

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
  }
}
