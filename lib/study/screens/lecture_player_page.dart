import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
import 'package:eduverse/common/widgets/cross_platform_youtube_player.dart';
import 'package:eduverse/common/widgets/video_skip_overlay.dart';

class LecturePlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final bool isLiveStream;
  final String subject;
  final String chapter;
  final int? lectureNo;
  final List<String> linkedNoteIds;
  final String? courseId;
  final String? batchId;

  const LecturePlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.description = '',
    this.isLiveStream = false,
    this.subject = '',
    this.chapter = '',
    this.lectureNo,
    this.linkedNoteIds = const [],
    this.courseId,
    this.batchId,
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
  String? _youtubeVideoId;
  
  bool _isError = false;
  double _playbackSpeed = 1.0;

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
          _youtubeVideoId = videoId;
          // Only create youtube_player_flutter controller on mobile;
          // on Web, CrossPlatformYoutubePlayer (youtube_player_iframe) is used instead.
          if (!kIsWeb) {
            _youtubeController = YoutubePlayerController(
              initialVideoId: videoId,
              flags: YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
                isLive: widget.isLiveStream,
              ),
            );
          }
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
            additionalOptions: (context) => [
              OptionItem(
                onTap: (ctx) {
                  Navigator.pop(ctx);
                  _showChewieSpeedSheet();
                },
                iconData: Icons.speed,
                title: 'Playback Speed (${_playbackSpeed}x)',
              ),
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

  @override
  Widget build(BuildContext context) {
    // Determine the player widget
    Widget playerWidget;
    if (_isError) {
      playerWidget = const Center(child: Text('Could not load video', style: TextStyle(color: Colors.white)));
    } else if (_isYoutube && _youtubeVideoId != null && kIsWeb) {
      // Web: use CrossPlatformYoutubePlayer (youtube_player_iframe)
      playerWidget = CrossPlatformYoutubePlayer(
        videoId: _youtubeVideoId!,
        autoPlay: true,
        isLive: widget.isLiveStream,
        playbackSpeed: _playbackSpeed,
      );
    } else if (_isYoutube && _youtubeController != null) {
      // Mobile: use YoutubePlayerBuilder for proper fullscreen handling
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
            currentPlaybackSpeed: _playbackSpeed,
            onPlaybackSpeedChanged: (speed) {
              setState(() => _playbackSpeed = speed);
              _youtubeController!.setPlaybackRate(speed);
            },
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
                      // Metadata chips
                      if (widget.subject.isNotEmpty || widget.chapter.isNotEmpty || widget.lectureNo != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (widget.subject.isNotEmpty)
                              Chip(
                                avatar: const Icon(Icons.subject, size: 16),
                                label: Text(widget.subject, style: const TextStyle(fontSize: 13)),
                                backgroundColor: Colors.blue.shade50,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            if (widget.chapter.isNotEmpty)
                              Chip(
                                avatar: const Icon(Icons.menu_book, size: 16),
                                label: Text(widget.chapter, style: const TextStyle(fontSize: 13)),
                                backgroundColor: Colors.green.shade50,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            if (widget.lectureNo != null)
                              Chip(
                                avatar: const Icon(Icons.format_list_numbered, size: 16),
                                label: Text('Lecture ${widget.lectureNo}', style: const TextStyle(fontSize: 13)),
                                backgroundColor: Colors.purple.shade50,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
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
                      // Linked Notes Section
                      if (widget.linkedNoteIds.isNotEmpty && widget.courseId != null && widget.batchId != null) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.attach_file, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Linked Notes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLinkedNotes(),
                      ],
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

  Widget _buildLinkedNotes() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchLinkedNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Notes not found.', style: TextStyle(color: Colors.grey)),
          );
        }
        return Column(
          children: notes.map((note) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(note['title'] ?? 'Untitled Note'),
                subtitle: note['subtitle'] != null && (note['subtitle'] as String).isNotEmpty
                    ? Text(note['subtitle'])
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final url = note['pdfUrl'] as String?;
                    if (url != null && url.isNotEmpty) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open PDF')),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLinkedNotes() async {
    if (widget.courseId == null || widget.batchId == null) return [];
    final db = FirebaseFirestore.instance;
    final List<Map<String, dynamic>> results = [];
    for (final noteId in widget.linkedNoteIds) {
      try {
        final doc = await db
            .collection('courses')
            .doc(widget.courseId)
            .collection('batches')
            .doc(widget.batchId)
            .collection('notes')
            .doc(noteId)
            .get();
        if (doc.exists) {
          results.add({'id': doc.id, ...doc.data()!});
        }
      } catch (e) {
        debugPrint('Error fetching note $noteId: $e');
      }
    }
    return results;
  }
}
