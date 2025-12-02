import 'package:flutter/material.dart';
import 'models.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;

  const FeedCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(item.categoryLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        backgroundColor: item.color.withOpacity(0.2),
                      ),
                      const SizedBox(height: 8),
                      Text(item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: Icon(item.buttonIcon),
              label: Text(item.buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
