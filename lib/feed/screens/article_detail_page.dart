// file: lib/feed/screens/article_detail_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/widgets/rich_text_block.dart';
import 'package:eduverse/core/firebase/bookmark_service.dart';
import 'package:eduverse/profile/models/bookmark_model.dart';

/// Detail page for Article content type.
/// Shows full article with metadata, body text, and action buttons.
class ArticleDetailPage extends StatefulWidget {
  final FeedItem item;

  const ArticleDetailPage({super.key, required this.item});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  bool _isMarkedAsRead = false;
  bool _isBookmarked = false;
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final status = await _bookmarkService.isBookmarked(widget.item.id);
    if (mounted) setState(() => _isBookmarked = status);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // Hero AppBar with emoji thumbnail
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.color,
                        item.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Hero(
                      tag: 'feed_emoji_${item.id}',
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: Colors.white,
                  ),
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    Chip(
                      label: Text(
                        item.categoryLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item.color,
                        ),
                      ),
                      backgroundColor: item.color.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Metadata row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        InfoChip(
                          icon: Icons.access_time,
                          label: '${item.articleContent?.estimatedReadTime ?? 5} min read',
                        ),
                        InfoChip(
                          icon: Icons.calendar_today,
                          label: _formatDate(item.articleContent?.publishedDate ?? DateTime.now()),
                        ),
                        if (_isMarkedAsRead)
                          const InfoChip(
                            icon: Icons.check_circle,
                            label: 'Read',
                            color: Colors.green,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Tags
                    if (item.articleContent?.tags.isNotEmpty ?? false) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.articleContent!.tags
                            .map(
                              (tag) => Chip(
                                label: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    // Article body
                    SelectableText(
                      item.articleContent?.body ?? item.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.7,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleMarkAsRead,
                  icon: Icon(_isMarkedAsRead ? Icons.check : Icons.check_circle_outline),
                  label: Text(_isMarkedAsRead ? 'Marked as Read' : 'Mark as Read'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toggleBookmark,
                  icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined),
                  label: Text(_isBookmarked ? 'Saved' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleMarkAsRead() {
    setState(() {
      _isMarkedAsRead = !_isMarkedAsRead;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMarkedAsRead ? 'Marked as read' : 'Unmarked'),
        duration: const Duration(seconds: 1),
      ),
    );
    // TODO: Persist read state to backend/local storage
  }

  Future<void> _toggleBookmark() async {
    // Optimistic UI update
    setState(() => _isBookmarked = !_isBookmarked);

    try {
      final bookmarkItem = BookmarkItem(
        id: widget.item.id,
        title: widget.item.title,
        type: BookmarkType.article,
        dateAdded: DateTime.now(),
        metadata: {
          'category': widget.item.categoryLabel,
          'emoji': widget.item.emoji,
          // Add essential fields needed for basic rendering in bookmarks list
        },
      );

      final isBookmarkedNow = await _bookmarkService.toggleBookmark(bookmarkItem);
      
      // Sync state if it differs from optimism (rare but possible)
      if (mounted && _isBookmarked != isBookmarkedNow) {
        setState(() => _isBookmarked = isBookmarkedNow);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBookmarkedNow ? 'Added to bookmarks' : 'Removed from bookmarks'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) setState(() => _isBookmarked = !_isBookmarked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
