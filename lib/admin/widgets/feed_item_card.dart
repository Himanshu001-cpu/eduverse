import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FeedItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildLeading(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTypeBadge(),
                      _buildVisibilityBadge(),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (item.thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item.thumbnailUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildEmojiLeading(),
        ),
      );
    }
    return _buildEmojiLeading();
  }

  Widget _buildEmojiLeading() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item.type.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: item.color,
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge() {
    final isPublic = item.isPublic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPublic ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.visibility : Icons.visibility_off,
            size: 12,
            color: isPublic ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPublic ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
