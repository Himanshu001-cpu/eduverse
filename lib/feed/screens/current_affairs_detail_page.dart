// file: lib/feed/screens/current_affairs_detail_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/widgets/rich_text_block.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/feed/models/comment_model.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Detail page for Current Affairs content type.
/// Shows structured sections: What Happened, Why It Matters, UPSC Relevance.
class CurrentAffairsDetailPage extends StatefulWidget {
  final FeedItem item;

  const CurrentAffairsDetailPage({super.key, required this.item});

  @override
  State<CurrentAffairsDetailPage> createState() =>
      _CurrentAffairsDetailPageState();
}

class _CurrentAffairsDetailPageState extends State<CurrentAffairsDetailPage> {
  final FeedRepository _feedRepo = FeedRepository();
  final AuthService _authService = AuthService();
  late Stream<bool> _isLikedStream;
  late Stream<bool> _isBookmarkedStream;
  late Stream<List<Comment>> _commentsStream;

  @override
  void initState() {
    super.initState();
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _isLikedStream = _feedRepo.isLikedStream(widget.item.id, userId);
      _isBookmarkedStream = _feedRepo.isBookmarkedStream(
        widget.item.id,
        userId,
      );
    } else {
      _isLikedStream = Stream.value(false);
      _isBookmarkedStream = Stream.value(false);
    }
    _commentsStream = _feedRepo.getComments(widget.item.id);
  }

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
            // Hero AppBar with thumbnail or emoji fallback
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: item.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        item.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildEmojiHeader(item, content),
                      )
                    : _buildEmojiHeader(item, content),
              ),
              actions: [
                StreamBuilder<bool>(
                  stream: _isBookmarkedStream,
                  builder: (context, snapshot) {
                    final isBookmarked = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        color: Colors.white,
                      ),
                      onPressed: () => _toggleBookmark(isBookmarked),
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
                    // Title
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Date and context
                    Row(
                      children: [
                        InfoChip(
                          icon: Icons.calendar_today,
                          label: _formatDate(
                            content?.eventDate ?? DateTime.now(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InfoChip(
                          icon: Icons.public,
                          label: content?.context ?? 'National',
                          color:
                              content?.context.toLowerCase() == 'international'
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
                      body:
                          content?.whyItMatters ??
                          _generatePlaceholder('importance'),
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.amber,
                    ),
                    // Section: UPSC Relevance
                    RichTextBlock(
                      title: '📚 Exam Relevance',
                      body:
                          content?.examRelevance ??
                          _generatePlaceholder('exam'),
                      icon: Icons.school,
                      iconColor: Colors.indigo,
                      showDivider: false,
                    ),
                    const SizedBox(height: 24),
                    // Quick Revision Points Card
                    Card(
                      elevation: 0,
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quick Revision Points',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildRevisionPoint(
                              'Key stakeholders and their roles',
                            ),
                            _buildRevisionPoint('Timeline of major events'),
                            _buildRevisionPoint(
                              'Impact on policy/economy/society',
                            ),
                            _buildRevisionPoint(
                              'Related constitutional provisions',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Social Interaction Bar
                    _buildSocialBar(item),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBar(FeedItem item) {
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
    // Optimistic update handled by StreamBuilder eventually, but repo handles logic
    await _feedRepo.toggleLike(widget.item.id, user.uid);
  }

  void _handleShare() {
    // Construct deep link
    // Scheme: https://theeduverse.co.in/app/feed/{id}
    final String deepLink =
        'https://theeduverse.co.in/app/feed/${widget.item.id}';
    final String shareText =
        'Check out this Current Affairs topic on EduVerse:\n\n'
        '${widget.item.title}\n\n'
        'Read more: $deepLink';

    SharePlus.instance.share(ShareParams(text: shareText));
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
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark(bool currentStatus) async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to bookmark items')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !currentStatus ? 'Added to bookmarks' : 'Removed from bookmarks',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    await _feedRepo.toggleBookmark(widget.item.id, user.uid);
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

  String _generatePlaceholder(String type) {
    switch (type) {
      case 'importance':
        return 'This development has significant implications for policy-making, governance, and civil society. Understanding its nuances is crucial for comprehensive exam preparation and awareness of contemporary issues.';
      case 'exam':
        return 'This topic is relevant for General Studies Paper I, II, and III. It can be linked to governance, international relations, economy, and current events. Potential questions may focus on analysis, comparison with similar events, and policy recommendations.';
      default:
        return 'Detailed information will be available soon.';
    }
  }

  Widget _buildEmojiHeader(FeedItem item, CurrentAffairsContent? content) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [item.color, item.color.withValues(alpha: 0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(item.emoji, style: const TextStyle(fontSize: 48)),
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
    );
  }
}

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
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700], size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        userName: user.displayName ?? 'User',
        text: text,
        createdAt: DateTime.now(),
        userAvatarUrl: user.photoURL,
      );

      await widget.feedRepo.addComment(widget.feedId, comment);
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),

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
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
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
                                        color: Colors.grey[600],
                                        fontSize: 12,
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

          // Input Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isPosting ? null : _postComment,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
