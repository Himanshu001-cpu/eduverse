import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
import 'package:eduverse/common/widgets/video_skip_overlay.dart';

class LecturePlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;

  final bool isLiveStream;

  const LecturePlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.description = '',
    this.isLiveStream = false,
  });

  @override
  State<LecturePlayerPage> createState() => _LecturePlayerPageState();
}

class _LecturePlayerPageState extends State<LecturePlayerPage> {
  // Video Player / Chewie
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  // YouTube Player
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;
  
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
        // Try standard converter first, then fall back to our custom extractor
        var videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
        if (videoId == null) {
          // Fallback to custom extractor for /live/ URLs
          videoId = YouTubeUtils.extractVideoId(widget.videoUrl);
        }
        
        if (videoId != null) {
          _isYoutube = true;
          // Pass isLive: widget.isLiveStream - required for playing live streams on Web
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              isLive: widget.isLiveStream,
            ),
          );
        } else {
          _isYoutube = false;
          _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
          await _videoPlayerController!.initialize();
          
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            aspectRatio: 16 / 9,
            allowFullScreen: true,
            allowMuting: true,
            deviceOrientationsOnEnterFullScreen: [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            deviceOrientationsAfterFullScreen: [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
          );
        }
        setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the player widget
    Widget playerWidget;
    if (_isError) {
      playerWidget = const Center(child: Text('Could not load video', style: TextStyle(color: Colors.white)));
    } else if (_isYoutube && _youtubeController != null) {
      // Use YoutubePlayerBuilder for proper fullscreen handling
      return YoutubePlayerBuilder(
        onEnterFullScreen: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        },
        onExitFullScreen: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        },
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: false,
        ),
        builder: (context, player) {
          final playerWithOverlay = VideoSkipOverlay(
            onSeek: (pos) => _youtubeController!.seekTo(pos),
            getCurrentPosition: () => _youtubeController!.value.position,
            getTotalDuration: () => _youtubeController!.metadata.duration,
            getIsPlaying: () => _youtubeController!.value.isPlaying,
            onPlay: () => _youtubeController!.play(),
            onPause: () => _youtubeController!.pause(),
            onToggleFullScreen: () => _youtubeController!.toggleFullScreenMode(),
            controllerListenable: _youtubeController!,
            child: player,
          );
          return _buildScaffold(context, playerWithOverlay);
        },
      );
    } else if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      playerWidget = Chewie(controller: _chewieController!);
    } else {
      playerWidget = const CircularProgressIndicator(color: Colors.white);
    }

    return _buildScaffold(context, playerWidget);
  }

  Widget _buildScaffold(BuildContext context, Widget playerWidget) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(child: playerWidget),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.description.isNotEmpty 
                            ? widget.description 
                            : 'No description available.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
