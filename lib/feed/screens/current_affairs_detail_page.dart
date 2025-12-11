// file: lib/feed/screens/current_affairs_detail_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/widgets/rich_text_block.dart';

/// Detail page for Current Affairs content type.
/// Shows structured sections: What Happened, Why It Matters, UPSC Relevance.
class CurrentAffairsDetailPage extends StatefulWidget {
  final FeedItem item;

  const CurrentAffairsDetailPage({super.key, required this.item});

  @override
  State<CurrentAffairsDetailPage> createState() => _CurrentAffairsDetailPageState();
}

class _CurrentAffairsDetailPageState extends State<CurrentAffairsDetailPage> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final content = item.currentAffairsContent;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // Hero AppBar
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.color,
                        item.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            content?.context.toUpperCase() ?? 'CURRENT AFFAIRS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
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
              ],
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Date and context
                    Row(
                      children: [
                        InfoChip(
                          icon: Icons.calendar_today,
                          label: _formatDate(content?.eventDate ?? DateTime.now()),
                        ),
                        const SizedBox(width: 8),
                        InfoChip(
                          icon: Icons.public,
                          label: content?.context ?? 'National',
                          color: content?.context.toLowerCase() == 'international'
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Tags
                    if (content?.tags.isNotEmpty ?? false) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: content!.tags
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
                      const SizedBox(height: 16),
                    ],
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 8),
                    // Section: What Happened?
                    RichTextBlock(
                      title: '📰 What Happened?',
                      body: content?.whatHappened ?? item.description,
                      icon: Icons.info_outline,
                    ),
                    // Section: Why It Matters?
                    RichTextBlock(
                      title: '💡 Why It Matters?',
                      body: content?.whyItMatters ?? _generatePlaceholder('importance'),
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.amber,
                    ),
                    // Section: UPSC Relevance
                    RichTextBlock(
                      title: '📚 UPSC Relevance',
                      body: content?.upscRelevance ?? _generatePlaceholder('upsc'),
                      icon: Icons.school,
                      iconColor: Colors.indigo,
                      showDivider: false,
                    ),
                    const SizedBox(height: 24),
                    // Quick Revision Points Card
                    Card(
                      elevation: 0,
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tips_and_updates, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Quick Revision Points',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildRevisionPoint('Key stakeholders and their roles'),
                            _buildRevisionPoint('Timeline of major events'),
                            _buildRevisionPoint('Impact on policy/economy/society'),
                            _buildRevisionPoint('Related constitutional provisions'),
                          ],
                        ),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notes feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text('Add to Notes'),
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

  Widget _buildRevisionPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks'),
        duration: const Duration(seconds: 1),
      ),
    );
    // TODO: Persist bookmark state to backend/local storage
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _generatePlaceholder(String type) {
    switch (type) {
      case 'importance':
        return 'This development has significant implications for policy-making, governance, and civil society. Understanding its nuances is crucial for comprehensive exam preparation and awareness of contemporary issues.';
      case 'upsc':
        return 'This topic is relevant for General Studies Paper I, II, and III. It can be linked to governance, international relations, economy, and current events. Potential questions may focus on analysis, comparison with similar events, and policy recommendations.';
      default:
        return 'Detailed information will be available soon.';
    }
  }
}
