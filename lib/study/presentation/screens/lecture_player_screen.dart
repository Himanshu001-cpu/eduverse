import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';

class LecturePlayerScreen extends StatefulWidget {
  final String courseId;
  final StudyLecture lecture;

  const LecturePlayerScreen({
    Key? key,
    required this.courseId,
    required this.lecture,
  }) : super(key: key);

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen> {
  bool _isWatched = false;
  
  // Players
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  
  bool _isYoutube = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _isWatched = widget.lecture.isWatched;
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
      try {
        final url = widget.lecture.videoUrl;
        if (url.isEmpty) return;

        final videoId = YoutubePlayer.convertUrlToId(url);
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
          _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
          await _videoPlayerController!.initialize();
          
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            aspectRatio: 16 / 9,
            allowFullScreen: true,
            allowMuting: true,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text(
                  'Error playing video: $errorMessage',
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

  void _markAsWatched() {
    final controller = Provider.of<StudyController>(context, listen: false);
    controller.markLectureWatched(widget.courseId, widget.lecture.id, !_isWatched);
    
    setState(() {
      _isWatched = !_isWatched;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isWatched ? 'Marked as Watched' : 'Marked as Unwatched')),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget playerWidget;
    if (_isError) {
      playerWidget = const Center(child: Text('Could not load video', style: TextStyle(color: Colors.white)));
    } else if (widget.lecture.videoUrl.isEmpty) {
      playerWidget = const Center(child: Text('No video URL provided', style: TextStyle(color: Colors.white)));
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
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player
            Expanded(
              child: Center(
                child: playerWidget,
              ),
            ),
            
            // Controls
            Container(
              color: Colors.white,
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
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _markAsWatched,
                      icon: Icon(_isWatched ? Icons.check_circle : Icons.radio_button_unchecked),
                      label: Text(_isWatched ? 'Completed' : 'Mark as Watched'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isWatched ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
