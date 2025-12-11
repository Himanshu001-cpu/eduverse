// file: lib/feed/screens/video_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/widgets/rich_text_block.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoUrl = widget.item.videoContent?.videoUrl ?? '';
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      )..addListener(_listener);
    }
  }

  void _listener() {
    if (_isPlayerReady && mounted && _controller != null && !_controller!.value.isFullScreen) {
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

    // If no valid video controller, show placeholder without player
    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video'),
          actions: [
            IconButton(
              icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
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
        showVideoProgressIndicator: true,
        progressIndicatorColor: colorScheme.primary,
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          _controller?.seekTo(const Duration(seconds: 0));
          _controller?.pause();
        },
      ),
      builder: (context, player) {
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share feature coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // YouTube Player
                      if (videoId != null)
                        player
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

  Widget _buildVideoInfo(BuildContext context, FeedItem item, VideoContent? content, ColorScheme colorScheme) {
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
                label: '${content?.durationMinutes ?? 15} mins',
              ),
              const InfoChip(
                icon: Icons.visibility,
                label: '2.3k views',
              ),
              const InfoChip(
                icon: Icons.thumb_up,
                label: '324 likes',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          // Description
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content?.description ?? item.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurfaceVariant,
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

  Widget _buildPlaceholder(FeedItem item) {
    return Container(
      width: double.infinity,
      height: 220,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.emoji,
              style: const TextStyle(fontSize: 72),
            ),
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
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
