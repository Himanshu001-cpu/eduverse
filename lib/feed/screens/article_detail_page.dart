// file: lib/feed/screens/article_detail_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/widgets/rich_text_block.dart';
import 'package:eduverse/core/firebase/bookmark_service.dart';
import 'package:eduverse/profile/models/bookmark_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/feed/models/comment_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduverse/core/utils/markdown_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  final FeedRepository _feedRepo = FeedRepository();
  final AuthService _authService = AuthService();
  late Stream<bool> _isLikedStream;
  late Stream<List<Comment>> _commentsStream;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _isLikedStream = _feedRepo.isLikedStream(widget.item.id, userId);
    } else {
      _isLikedStream = Stream.value(false);
    }
    _commentsStream = _feedRepo.getComments(widget.item.id);
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
            // Hero AppBar with thumbnail or emoji fallback
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: item.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        item.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildEmojiHeader(item),
                      )
                    : _buildEmojiHeader(item),
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
                  onPressed: _handleShare,
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Metadata row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        InfoChip(
                          icon: Icons.access_time,
                          label:
                              '${item.articleContent?.estimatedReadTime ?? 5} min read',
                        ),
                        InfoChip(
                          icon: Icons.calendar_today,
                          label: _formatDate(
                            item.articleContent?.publishedDate ??
                                DateTime.now(),
                          ),
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
                                backgroundColor: colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    // Article body with markdown support
                    MarkdownBody(
                      data: MarkdownUtils.normalizeMarkdown(
                        item.articleContent?.body ?? item.description,
                      ),
                      selectable: true,
                      softLineBreak: true,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.7,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        strong: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.7,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        em: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.7,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Social Bar
                    _buildSocialBar(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBar() {
    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Like Button
              StreamBuilder<bool>(
                stream: _isLikedStream,
                builder: (context, snapshot) {
                  final isLiked = snapshot.data ?? false;
                  return _SocialButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'Like',
                    color: isLiked ? Colors.red : null,
                    onTap: () => _handleLike(isLiked),
                  );
                },
              ),
              // Comment Button
              _SocialButton(
                icon: Icons.chat_bubble_outline,
                label: 'Comment',
                onTap: _showCommentSheet,
              ),
              // Share Button
              _SocialButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: _handleShare,
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  void _handleLike(bool currentStatus) async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to like')));
      return;
    }
    await _feedRepo.toggleLike(widget.item.id, user.uid);
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsSheet(
        feedId: widget.item.id,
        commentsStream: _commentsStream,
        feedRepo: _feedRepo,
        authService: _authService,
      ),
    );
  }

  void _handleShare() {
    final String deepLink =
        'https://theeduverse.co.in/app/feed/${widget.item.id}';
    final String shareText =
        'Check out this Article on EduVerse:\n\n'
        '${widget.item.title}\n\n'
        'Read more: $deepLink';

    SharePlus.instance.share(ShareParams(text: shareText));
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
        },
      );

      final isBookmarkedNow = await _bookmarkService.toggleBookmark(
        bookmarkItem,
      );

      if (mounted && _isBookmarked != isBookmarkedNow) {
        setState(() => _isBookmarked = isBookmarkedNow);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBookmarkedNow ? 'Added to bookmarks' : 'Removed from bookmarks',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isBookmarked = !_isBookmarked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildEmojiHeader(FeedItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [item.color, item.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Hero(
          tag: 'feed_emoji_${item.id}',
          child: Text(item.emoji, style: const TextStyle(fontSize: 64)),
        ),
      ),
    );
  }
}

/// Social Button Widget
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comments Sheet Widget
class _CommentsSheet extends StatefulWidget {
  final String feedId;
  final Stream<List<Comment>> commentsStream;
  final FeedRepository feedRepo;
  final AuthService authService;

  const _CommentsSheet({
    required this.feedId,
    required this.commentsStream,
    required this.feedRepo,
    required this.authService,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = widget.authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to comment')));
      return;
    }

    setState(() => _isPosting = true);
    try {
      final comment = Comment(
        id: const Uuid().v4(),
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userAvatarUrl: user.photoURL,
        text: text,
        createdAt: DateTime.now(),
      );
      await widget.feedRepo.addComment(widget.feedId, comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting comment: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comments',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Comments List
            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: widget.commentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final comment = snapshot.data![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: comment.userAvatarUrl != null
                                  ? NetworkImage(comment.userAvatarUrl!)
                                  : null,
                              child: comment.userAvatarUrl == null
                                  ? Text(comment.userName[0].toUpperCase())
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeago.format(comment.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment.text),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Comment Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isPosting ? null : _postComment,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
