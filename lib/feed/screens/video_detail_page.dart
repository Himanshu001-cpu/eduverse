// file: lib/feed/screens/video_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/widgets/rich_text_block.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
import 'package:eduverse/common/widgets/cross_platform_youtube_player.dart';
import 'package:eduverse/common/widgets/video_skip_overlay.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/feed/models/comment_model.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:eduverse/core/utils/markdown_utils.dart';

/// Detail page for Video content type with YouTube player support
class VideoDetailPage extends StatefulWidget {
  final FeedItem item;

  const VideoDetailPage({super.key, required this.item});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  bool _isBookmarked = false;
  double _playbackSpeed = 1.0;

  final FeedRepository _feedRepo = FeedRepository();
  final AuthService _authService = AuthService();
  late Stream<bool> _isLikedStream;
  late Stream<List<Comment>> _commentsStream;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initializeStreams();
    _trackView();
  }

  void _initializeStreams() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _isLikedStream = _feedRepo.isLikedStream(widget.item.id, userId);
    } else {
      _isLikedStream = Stream.value(false);
    }
    _commentsStream = _feedRepo.getComments(widget.item.id);
  }

  Future<void> _trackView() async {
    if (!_viewCounted) {
      _viewCounted = true;
      try {
        await _feedRepo.incrementViewCount(widget.item.id);
      } catch (e) {
        debugPrint('Error tracking view: $e');
      }
    }
  }

  void _initializePlayer() {
    final videoUrl = widget.item.videoContent?.videoUrl ?? '';

    // Try standard converter first, then fall back to our custom extractor
    var videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      // Fallback to custom extractor for /live/ URLs
      videoId = YouTubeUtils.extractVideoId(videoUrl);
    }

    if (videoId != null && videoId.isNotEmpty) {
      final isLive = widget.item.videoContent?.isLive ?? false;
      // Only create youtube_player_flutter controller on mobile;
      // on Web, CrossPlatformYoutubePlayer (youtube_player_iframe) is used instead.
      if (!kIsWeb) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
            isLive: isLive,
          ),
        )..addListener(_listener);
      }
    }
  }

  void _listener() {
    if (_isPlayerReady &&
        mounted &&
        _controller != null &&
        !_controller!.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final content = item.videoContent;
    final videoId = YoutubePlayer.convertUrlToId(content?.videoUrl ?? '');

    // If no valid video controller and not on web, show placeholder without player
    // (On web, _controller is null by design; the kIsWeb path below uses CrossPlatformYoutubePlayer)
    if (_controller == null && !kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video'),
          actions: [
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              ),
              onPressed: _toggleBookmark,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildPlaceholder(item),
              _buildVideoInfo(context, item, content, colorScheme),
            ],
          ),
        ),
      );
    }

    // On Web, use CrossPlatformYoutubePlayer directly (not YoutubePlayerBuilder)
    if (kIsWeb) {
      return Scaffold(
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _handleShare,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // YouTube Player for Web
                    if (videoId != null)
                      CrossPlatformYoutubePlayer(
                        videoId: videoId,
                        autoPlay: false,
                        isLive: widget.item.videoContent?.isLive ?? false,
                        settingsButton: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => _showQualitySheet(context),
                        ),
                      )
                    else
                      _buildPlaceholder(item),
                    // Video info
                    _buildVideoInfo(context, item, content, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile: use YoutubePlayerBuilder
    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        // Lock to landscape when entering fullscreen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      onExitFullScreen: () {
        // Return to portrait when exiting fullscreen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: false,
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          _controller?.seekTo(const Duration(seconds: 0));
          _controller?.pause();
        },
      ),
      builder: (context, player) {
        // Wrap player with full custom controls overlay
        final playerWithSettings = VideoSkipOverlay(
          onSeek: (pos) => _controller!.seekTo(pos),
          getCurrentPosition: () => _controller!.value.position,
          getTotalDuration: () => _controller!.metadata.duration,
          getIsPlaying: () => _controller!.value.isPlaying,
          onPlay: () => _controller!.play(),
          onPause: () => _controller!.pause(),
          onToggleFullScreen: () => _controller!.toggleFullScreenMode(),
          onShowQuality: () => _showQualitySheet(context),
          currentPlaybackSpeed: _playbackSpeed,
          onPlaybackSpeedChanged: (speed) {
            setState(() => _playbackSpeed = speed);
            _controller!.setPlaybackRate(speed);
          },
          controllerListenable: _controller!,
          child: player,
        );

        return Scaffold(
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      ),
                      onPressed: _toggleBookmark,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _handleShare,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // YouTube Player with settings overlay
                      if (videoId != null)
                        playerWithSettings
                      else
                        _buildPlaceholder(item),
                      // Video info
                      _buildVideoInfo(context, item, content, colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Widget _buildVideoInfo(
    BuildContext context,
    FeedItem item,
    VideoContent? content,
    ColorScheme colorScheme,
  ) {
    return Padding(
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Metadata row with dynamic values
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              InfoChip(
                icon: Icons.access_time,
                label: '${content?.durationMinutes ?? 15} mins',
              ),
              InfoChip(
                icon: Icons.visibility,
                label: '${_formatCount(item.viewCount)} views',
              ),
              InfoChip(
                icon: Icons.thumb_up,
                label: '${_formatCount(item.likesCount)} likes',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Social Bar
          _buildSocialBar(),
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          // Description
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: MarkdownUtils.normalizeMarkdown(
              content?.description ?? item.description,
            ),
            selectable: true,
            softLineBreak: true,
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Key Points
          if (content?.keyPoints.isNotEmpty ?? false) ...[
            RichTextBulletList(
              title: 'Key Points Covered',
              items: content!.keyPoints,
              icon: Icons.list_alt,
              showDivider: false,
            ),
          ] else ...[
            RichTextBulletList(
              title: 'Key Points Covered',
              items: const [
                'Introduction to the topic and its importance',
                'Core concepts explained with examples',
                'Previous year question analysis',
                'Tips for answer writing and revision',
                'Summary and key takeaways',
              ],
              icon: Icons.list_alt,
              showDivider: false,
            ),
          ],
          const SizedBox(height: 32),
        ],
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

  Widget _buildPlaceholder(FeedItem item) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [item.color, item.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'No video URL provided',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare() {
    final String deepLink =
        'https://theeduverse.co.in/app/feed/${widget.item.id}';
    final String shareText =
        'Check out this Video Class on EduVerse:\n\n'
        '${widget.item.title}\n\n'
        'Watch here: $deepLink';

    SharePlus.instance.share(ShareParams(text: shareText));
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onQualityChanged(String quality) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Switching to $quality...')));
    // Logic similar to LecturePlayerScreen
  }

  void _showQualitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Quality for current video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.grey),
            ...['Auto', '1080p', '720p', '480p', '360p', '240p', '144p'].map(
              (q) => ListTile(
                leading: Icon(Icons.hd, color: Colors.blue[300]),
                title: Text(q, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _onQualityChanged(q);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
