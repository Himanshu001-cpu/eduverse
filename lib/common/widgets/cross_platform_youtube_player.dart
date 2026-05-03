
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as iframe;
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// A cross-platform YouTube player widget that works on both mobile and web.
/// Uses youtube_player_iframe for Web compatibility.
///
/// When paused, YouTube's iframe shows a built-in thumbnail/related-videos
/// overlay. To prevent this from obscuring the actual paused frame, this widget
/// tracks the player state and covers the iframe with a play-button scrim
/// whenever the video is paused.
class CrossPlatformYoutubePlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final bool isLive;
  final VoidCallback? onReady;
  final VoidCallback? onEnded;
  final Widget? settingsButton;
  final double playbackSpeed;

  const CrossPlatformYoutubePlayer({
    super.key,
    required this.videoId,
    this.autoPlay = true,
    this.isLive = false,
    this.onReady,
    this.onEnded,
    this.settingsButton,
    this.playbackSpeed = 1.0,
  });

  @override
  State<CrossPlatformYoutubePlayer> createState() =>
      _CrossPlatformYoutubePlayerState();
}

class _CrossPlatformYoutubePlayerState
    extends State<CrossPlatformYoutubePlayer> {
  late iframe.YoutubePlayerController _controller;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = iframe.YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: widget.autoPlay,
      params: const iframe.YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableCaption: true,
        playsInline: true,
        // Limit related videos to same channel only (cannot fully disable per YouTube policy)
        strictRelatedVideos: true,
      ),
    );

    _controller.listen((event) {
      if (event.playerState == iframe.PlayerState.ended) {
        widget.onEnded?.call();
      }
      // Apply playback speed when video starts playing
      if (event.playerState == iframe.PlayerState.playing) {
        _controller.setPlaybackRate(widget.playbackSpeed);
      }

      // Track pause state to overlay YouTube's built-in pause thumbnail
      final paused = event.playerState == iframe.PlayerState.paused;
      if (paused != _isPaused && mounted) {
        setState(() => _isPaused = paused);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CrossPlatformYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackSpeed != widget.playbackSpeed) {
      _controller.setPlaybackRate(widget.playbackSpeed);
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate height based on 16:9 aspect ratio
    final width = MediaQuery.of(context).size.width;
    final height = width * 9 / 16;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          iframe.YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),

          // When paused, cover the entire iframe to hide YouTube's native
          // pause overlay (thumbnail / suggested-videos). The dark scrim lets
          // the paused frame peek through while providing a clear play button.
          if (_isPaused)
            Positioned.fill(
              child: PointerInterceptor(
                child: GestureDetector(
                  onTap: () => _controller.playVideo(),
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // When playing, a transparent overlay to pass scroll events
          if (!_isPaused)
            Positioned.fill(
              child: PointerInterceptor(
                intercepting: false,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Settings button overlay
          if (widget.settingsButton != null)
            Positioned(top: 8, right: 8, child: widget.settingsButton!),
        ],
      ),
    );
  }
}
