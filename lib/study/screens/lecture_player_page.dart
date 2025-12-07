import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';

class LecturePlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;

  const LecturePlayerPage({
    Key? key,
    required this.videoUrl,
    required this.title,
    this.description = '',
  }) : super(key: key);

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
        final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
        if (videoId != null) {
          _isYoutube = true;
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
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
    } else if (_isYoutube) {
      playerWidget = _youtubeController != null 
          ? YoutubePlayer(controller: _youtubeController!) 
          : const CircularProgressIndicator(color: Colors.white);
    } else {
      playerWidget = _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const CircularProgressIndicator(color: Colors.white);
    }

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
