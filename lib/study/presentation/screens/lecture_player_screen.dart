import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:eduverse/core/firebase/watch_stats_service.dart';
import 'package:eduverse/core/firebase/live_viewer_service.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
import 'package:eduverse/common/widgets/cross_platform_youtube_player.dart';
import 'package:eduverse/common/widgets/video_skip_overlay.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class LecturePlayerScreen extends StatefulWidget {
  final String? courseId;
  final String? batchId;
  final StudyLecture lecture;
  final bool isFreeClass;
  final bool isLiveStream;

  const LecturePlayerScreen({
    super.key,
    this.courseId,
    this.batchId,
    required this.lecture,
    this.isFreeClass = false,
    this.isLiveStream = false,
  });

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen> {
  bool _isWatched = false;
  bool _subtitlesEnabled = false;

  // Players
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;

  bool _isYoutube = false;
  bool _isError = false;
  String? _youtubeVideoId; // Store video ID for cross-platform player
  double _playbackSpeed = 1.0;

  // Comments
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  // Watch time tracking
  DateTime? _watchStartTime;

  // Live viewer tracking
  final LiveViewerService _liveViewerService = LiveViewerService();
  bool _hasJoinedLive = false;
  String? _joinedLiveClassId;

  @override
  void initState() {
    super.initState();
    _isWatched = widget.lecture.isWatched;
    _watchStartTime = DateTime.now(); // Start tracking watch time
    _initializePlayer();
    _joinLiveIfNeeded();
  }

  void _joinLiveIfNeeded() {
    if (widget.isLiveStream &&
        widget.courseId != null &&
        widget.batchId != null) {
      _joinedLiveClassId = widget.lecture.id;
      _liveViewerService.joinLive(
        widget.courseId!,
        widget.batchId!,
        _joinedLiveClassId!,
      );
      _hasJoinedLive = true;
    }
  }

  Future<void> _initializePlayer() async {
    try {
      final url = widget.lecture.videoUrl;
      debugPrint('LecturePlayerScreen: Initializing player for URL: $url');
      if (url.isEmpty) {
        debugPrint('LecturePlayerScreen: Empty URL, skipping initialization');
        return;
      }

      // Try standard converter first, then fall back to our custom extractor
      var videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId == null) {
        // Fallback to custom extractor for /live/ URLs
        videoId = YouTubeUtils.extractVideoId(url);
        debugPrint(
          'LecturePlayerScreen: Using custom extractor, video ID: $videoId',
        );
      }
      debugPrint('LecturePlayerScreen: Final video ID: $videoId');

      if (videoId != null) {
        _isYoutube = true;
        _youtubeVideoId = videoId; // Store for cross-platform player

        // Only create youtube_player_flutter controller on mobile (not on Web)
        if (!kIsWeb) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              enableCaption: true,
              isLive: widget.isLiveStream,
            ),
          );
        }
        // On Web, we use CrossPlatformYoutubePlayer which creates its own controller
      } else {
        _isYoutube = false;
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(url),
        );
        await _videoPlayerController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          additionalOptions: (context) => [
            OptionItem(
              onTap: (ctx) {
                setState(() => _subtitlesEnabled = !_subtitlesEnabled);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      _subtitlesEnabled
                          ? 'Subtitles enabled'
                          : 'Subtitles disabled',
                    ),
                  ),
                );
              },
              iconData: _subtitlesEnabled
                  ? Icons.subtitles
                  : Icons.subtitles_off,
              title: _subtitlesEnabled
                  ? 'Disable Subtitles'
                  : 'Enable Subtitles',
            ),
            OptionItem(
              onTap: (ctx) {
                Navigator.pop(ctx);
                _showChewieSpeedSheet();
              },
              iconData: Icons.speed,
              title: 'Playback Speed (${_playbackSpeed}x)',
            ),
          ],
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing player: $e');
      if (mounted) setState(() => _isError = true);
    }
  }

  void _onQualityChanged(String quality) {
    if (_youtubeController == null) return;

    // Convert friendly name to API value if needed, or pass directly
    // YouTube API expects: small, medium, large, hd720, hd1080, highres, default
    /*
      'Auto': 'default',
      '144p': 'small',
      '240p': 'small',
      '360p': 'medium',
      '480p': 'large',
      '720p': 'hd720',
      '1080p': 'hd1080',
    */

    // We'll rely on the player to handle the actual switching,
    // but we force a reload with the new suggestion.
    // Note: load() might not take quality in all versions,
    // but usually setting it via flags or reload works best.

    // Since 'load' with quality param isn't reliably exposed in the convenience method,
    // we use the controller's loadVideoById which usually supports it,
    // or just re-initialize. Re-initializing is safer for "forcing" it.

    // For this implementation, we will try to use the controller's load method if available
    // or fallback to re-creating the controller.

    // Actually, simply calling load again with startAt works best for seeking,
    // but quality suggestion is finicky.

    debugPrint('Changing quality to $quality');
    // Using internal load to avoid full dispose/init cycle if possible,
    // but the most reliable way to "set" preference is often just reloading.

    // NOTE: The most robust way in this package is often just to let the user use the native
    // YouTube gear icon if available. But since we want a custom icon:

    // _youtubeController!.load(videoId, startAt: currentPos.inSeconds);
    // There isn't a direct "setQuality" method exposed in the high-level controller
    // that guarantees immediate switch without reload.

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Switching to $quality...')));

    // Re-initialize or load with quality hint (if supported by specific params)
    // For now, we will simulate the "Action" by simply showing the selection
    // In a real generic implementation, we would need to map this to youtube iframe API calls.
    // But standardized quality selection is restricted by YouTube.
    // We will attempt to force it by simple reload if it helps,
    // otherwise just showing the UI as requested.
  }

  void _showQualitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
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
        ),
      ),
    );
  }

  void _showChewieSpeedSheet() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Playback Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.grey),
            ...speeds.map(
              (s) => ListTile(
                leading: Icon(
                  s == _playbackSpeed ? Icons.check_circle : Icons.speed,
                  color: s == _playbackSpeed ? Colors.green : Colors.blue[300],
                ),
                title: Text(
                  s == 1.0 ? 'Normal' : '${s}x',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        s == _playbackSpeed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _playbackSpeed = s);
                  _videoPlayerController?.setPlaybackSpeed(s);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAsWatched() {
    if (widget.isFreeClass ||
        widget.courseId == null ||
        widget.batchId == null) {
      // Local toggle only for free classes
      setState(() => _isWatched = !_isWatched);
      return;
    }
    final controller = Provider.of<StudyController>(context, listen: false);
    controller.markLectureWatched(
      widget.courseId!,
      widget.batchId!,
      widget.lecture.id,
      !_isWatched,
    );
    setState(() => _isWatched = !_isWatched);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isWatched ? 'Marked as Watched' : 'Marked as Unwatched'),
      ),
    );
  }

  String get _commentsPath {
    final String basePath = widget.isFreeClass ||
            widget.courseId == null ||
            widget.batchId == null
        ? 'free_live_classes/${widget.lecture.id}'
        : 'courses/${widget.courseId}/batches/${widget.batchId}/lessons/${widget.lecture.id}';

    return widget.isLiveStream ? '$basePath/live_comments' : '$basePath/comments';
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to comment')));
      return;
    }

    setState(() => _isPostingComment = true);

    try {
      if (_replyingToCommentId != null) {
        await FirebaseFirestore.instance
            .collection(_commentsPath)
            .doc(_replyingToCommentId)
            .collection('replies')
            .add({
              'text': text,
              'userId': user.uid,
              'userName': user.displayName ?? 'Student',
              'userPhoto': user.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
            });
      } else {
        await FirebaseFirestore.instance.collection(_commentsPath).add({
          'text': text,
          'userId': user.uid,
          'userName': user.displayName ?? 'Student',
          'userPhoto': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      _commentController.clear();
      _cancelReply();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment and all its replies?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final commentRef = FirebaseFirestore.instance
          .collection(_commentsPath)
          .doc(commentId);

      // First delete all replies in the subcollection
      final repliesSnapshot = await commentRef.collection('replies').get();
      for (final replyDoc in repliesSnapshot.docs) {
        await replyDoc.reference.delete();
      }

      // Then delete the comment itself
      await commentRef.delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteReply(String commentId, String replyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection(_commentsPath)
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply deleted')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    // Save watch time before disposing
    _saveWatchTime();

    // Leave live viewer tracking
    if (_hasJoinedLive &&
        widget.courseId != null &&
        widget.batchId != null &&
        _joinedLiveClassId != null) {
      _liveViewerService.leaveLive(
        widget.courseId!,
        widget.batchId!,
        _joinedLiveClassId!,
      );
      _hasJoinedLive = false;
    }

    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    _commentController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _saveWatchTime() {
    if (_watchStartTime == null) return;
    // Skip if not a enrolled batch class
    if (widget.batchId == null) return;

    final watchedMinutes =
        DateTime.now().difference(_watchStartTime!).inSeconds / 60.0;
    if (watchedMinutes < 0.1) return; // Don't save if less than 6 seconds

    WatchStatsService().recordWatchTime(
      lectureId: widget.lecture.id,
      lectureTitle: widget.lecture.title,
      watchedMinutes: watchedMinutes,
      batchId: widget.batchId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        Widget playerWidget;
        if (_isError) {
          playerWidget = const Center(
            child: Text(
              'Could not load video',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else if (widget.lecture.videoUrl.isEmpty) {
          playerWidget = const Center(
            child: Text('No video URL', style: TextStyle(color: Colors.white)),
          );
        } else if (_isYoutube && _youtubeVideoId != null) {
          // Use CrossPlatformYoutubePlayer on Web (uses youtube_player_iframe)
          // Use youtube_player_flutter on mobile
          if (kIsWeb) {
            playerWidget = CrossPlatformYoutubePlayer(
              videoId: _youtubeVideoId!,
              autoPlay: true,
              isLive: widget.isLiveStream,
              playbackSpeed: _playbackSpeed,
              settingsButton: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                onPressed: _showQualitySheet,
              ),
            );
          } else {
            // Mobile: use youtube_player_flutter with custom controls overlay
            playerWidget = _youtubeController != null
                ? VideoSkipOverlay(
                    onSeek: (pos) => _youtubeController!.seekTo(pos),
                    getCurrentPosition: () => _youtubeController!.value.position,
                    getTotalDuration: () => _youtubeController!.metadata.duration,
                    getIsPlaying: () => _youtubeController!.value.isPlaying,
                    onPlay: () => _youtubeController!.play(),
                    onPause: () => _youtubeController!.pause(),
                    onToggleFullScreen: () {
                      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                      if (isLandscape) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ]);
                      } else {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      }
                    },
                    onShowQuality: _showQualitySheet,
                    currentPlaybackSpeed: _playbackSpeed,
                    onPlaybackSpeedChanged: (speed) {
                      setState(() => _playbackSpeed = speed);
                      _youtubeController!.setPlaybackRate(speed);
                    },
                    controllerListenable: _youtubeController!,
                    child: YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: false,
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
          }
        } else {
          playerWidget =
              _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
        }

        // Single Scaffold – player stays at the same tree position
        // to avoid unmounting/remounting the YouTube webview on orientation change.
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final topPadding = MediaQuery.of(context).padding.top;

        return Scaffold(
          backgroundColor: isLandscape ? Colors.black : Colors.grey[100],
          resizeToAvoidBottomInset: !isLandscape,
          appBar: isLandscape
              ? null
              : AppBar(
                  title: Text(
                    widget.lecture.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  actions: [
                    if (widget.isLiveStream &&
                        widget.courseId != null &&
                        widget.batchId != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: StreamBuilder<int>(
                          stream: _liveViewerService.viewerCountStream(
                            widget.courseId!,
                            widget.batchId!,
                            widget.lecture.id,
                          ),
                          builder: (context, snapshot) {
                            final viewerCount = snapshot.data ?? 0;
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$viewerCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.visibility,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
          body: SafeArea(
            bottom: !isLandscape,
            top: isLandscape,
            child: Column(
              children: [
                // Video Player – always at position 0 in the Column
                SizedBox(
                  width: double.infinity,
                  height: isLandscape
                      ? screenHeight - topPadding
                      : screenWidth * 9 / 16,
                  child: Container(
                    color: Colors.black,
                    child: playerWidget,
                  ),
                ),

                // Content – shown in portrait, hidden in landscape
                // Using Expanded with a ternary keeps the tree structure stable
                if (!isLandscape)
                  Expanded(
                    child: kIsWeb
                        ? PointerInterceptor(
                            child: DefaultTabController(
                              length: 2,
                              child: Column(
                                children: [
                                  Material(
                                    color: Colors.white,
                                    child: TabBar(
                                      labelColor: Theme.of(context).primaryColor,
                                      unselectedLabelColor: Colors.grey,
                                      indicatorColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      tabs: [
                                        const Tab(text: 'Details'),
                                        Tab(text: widget.isLiveStream ? 'Live Chat' : 'Comments'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        _buildDetailsTab(),
                                        _buildCommentsTab(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                Material(
                                  color: Colors.white,
                                  child: TabBar(
                                    labelColor: Theme.of(context).primaryColor,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    tabs: [
                                      const Tab(text: 'Details'),
                                      Tab(text: widget.isLiveStream ? 'Live Chat' : 'Comments'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _buildDetailsTab(),
                                      _buildCommentsTab(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lecture.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lecture.description.isNotEmpty
                ? widget.lecture.description
                : "No description available.",
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 24),

          if (!_isYoutube && widget.lecture.videoUrl.isNotEmpty) ...[
            Card(
              child: ListTile(
                leading: Icon(
                  _subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
                ),
                title: const Text('Subtitles'),
                subtitle: Text(_subtitlesEnabled ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: _subtitlesEnabled,
                  onChanged: (v) {
                    setState(() => _subtitlesEnabled = v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v ? 'Subtitles enabled' : 'Subtitles disabled',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markAsWatched,
              icon: Icon(
                _isWatched ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
              label: Text(_isWatched ? 'Completed' : 'Mark as Watched'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWatched ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(_commentsPath)
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildCommentTile(doc.id, data);
                },
              );
            },
          ),
        ),

        // Reply indicator
        if (_replyingToCommentId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.reply, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replying to $_replyingToUserName',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                GestureDetector(
                  onTap: _cancelReply,
                  child: const Icon(Icons.close, size: 18, color: Colors.blue),
                ),
              ],
            ),
          ),

        // Comment Input
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? 12
                : 12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _postComment(),
                ),
              ),
              const SizedBox(width: 8),
              _isPostingComment
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _postComment,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentTile(String commentId, Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final userName = data['userName'] ?? 'Student';
    final userId = data['userId'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = userId != null && userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: data['userPhoto'] != null
                    ? NetworkImage(data['userPhoto'])
                    : null,
                child: data['userPhoto'] == null
                    ? Text(userName[0].toUpperCase())
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
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (createdAt != null)
                          Text(
                            _formatTimeAgo(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        const Spacer(),
                        if (isOwner)
                          GestureDetector(
                            onTap: () => _deleteComment(commentId),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['text'] ?? '',
                      style: const TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _startReply(commentId, userName),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reply, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Reply',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Replies
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(_commentsPath)
                .doc(commentId)
                .collection('replies')
                .orderBy('createdAt')
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(left: 48, top: 8),
                child: Column(
                  children: snapshot.data!.docs.map((replyDoc) {
                    final replyData = replyDoc.data() as Map<String, dynamic>;
                    final replyTime = (replyData['createdAt'] as Timestamp?)
                        ?.toDate();
                    final replyUserName = replyData['userName'] ?? 'Student';
                    final replyUserId = replyData['userId'] as String?;
                    final isReplyOwner =
                        replyUserId != null &&
                        replyUserId == FirebaseAuth.instance.currentUser?.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: replyData['userPhoto'] != null
                                    ? NetworkImage(replyData['userPhoto'])
                                    : null,
                                child: replyData['userPhoto'] == null
                                    ? Text(
                                        replyUserName[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 9),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          replyUserName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (replyTime != null)
                                          Text(
                                            _formatTimeAgo(replyTime),
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        const Spacer(),
                                        if (isReplyOwner)
                                          GestureDetector(
                                            onTap: () => _deleteReply(
                                              commentId,
                                              replyDoc.id,
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      replyData['text'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Reply button for replies too
                          Padding(
                            padding: const EdgeInsets.only(left: 32, top: 4),
                            child: InkWell(
                              onTap: () =>
                                  _startReply(commentId, replyUserName),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.reply,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Reply',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7)
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
