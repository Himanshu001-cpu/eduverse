import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/screens/generic_feed_detail_router.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;

  const FeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => FeedDetailRouter.open(context, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'feed_emoji_${item.id}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: item.thumbnailUrl.isEmpty ? item.color : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.thumbnailUrl.isNotEmpty
                            ? Image.network(
                                item.thumbnailUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) => 
                                    _buildFallback(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return _buildFallback(showLoader: true);
                                },
                              )
                            : _buildFallback(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text(
                            item.categoryLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: item.color.withValues(alpha: 0.2),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => FeedDetailRouter.open(context, item),
                icon: Icon(item.buttonIcon),
                label: Text(item.buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback({bool showLoader = false}) {
    return Container(
      color: item.color,
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              )
            : Text(item.emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}
