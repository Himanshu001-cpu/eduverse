import 'package:flutter/material.dart';
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

class LecturePlayerScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final StudyLecture lecture;

  const LecturePlayerScreen({
    super.key,
    required this.courseId,
    required this.batchId,
    required this.lecture,
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
  
  // Comments
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  
  // Watch time tracking
  DateTime? _watchStartTime;

  @override
  void initState() {
    super.initState();
    _isWatched = widget.lecture.isWatched;
    _watchStartTime = DateTime.now(); // Start tracking watch time
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
            enableCaption: true,
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
          showControls: true,
          additionalOptions: (context) => [
            OptionItem(
              onTap: (ctx) {
                setState(() => _subtitlesEnabled = !_subtitlesEnabled);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(_subtitlesEnabled ? 'Subtitles enabled' : 'Subtitles disabled')),
                );
              },
              iconData: _subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
              title: _subtitlesEnabled ? 'Disable Subtitles' : 'Enable Subtitles',
            ),
          ],
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text('Error: $errorMessage', style: const TextStyle(color: Colors.white)),
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
    controller.markLectureWatched(widget.courseId, widget.batchId, widget.lecture.id, !_isWatched);
    setState(() => _isWatched = !_isWatched);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isWatched ? 'Marked as Watched' : 'Marked as Unwatched')),
    );
  }

  String get _commentsPath => 
    'courses/${widget.courseId}/batches/${widget.batchId}/lessons/${widget.lecture.id}/comments';

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to comment')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        content: const Text('Are you sure you want to delete this comment and all its replies?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final commentRef = FirebaseFirestore.instance.collection(_commentsPath).doc(commentId);
      
      // First delete all replies in the subcollection
      final repliesSnapshot = await commentRef.collection('replies').get();
      for (final replyDoc in repliesSnapshot.docs) {
        await replyDoc.reference.delete();
      }
      
      // Then delete the comment itself
      await commentRef.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply deleted')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    // Save watch time before disposing
    _saveWatchTime();
    
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    _commentController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
  
  void _saveWatchTime() {
    if (_watchStartTime == null) return;
    
    final watchedMinutes = DateTime.now().difference(_watchStartTime!).inSeconds / 60.0;
    if (watchedMinutes < 0.1) return; // Don't save if less than 6 seconds
    
    WatchStatsService().recordWatchTime(
      lectureId: widget.lecture.id,
      lectureTitle: widget.lecture.title,
      watchedMinutes: watchedMinutes,
      batchId: widget.batchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        
        Widget playerWidget;
        if (_isError) {
          playerWidget = const Center(child: Text('Could not load video', style: TextStyle(color: Colors.white)));
        } else if (widget.lecture.videoUrl.isEmpty) {
          playerWidget = const Center(child: Text('No video URL', style: TextStyle(color: Colors.white)));
        } else if (_isYoutube) {
          playerWidget = _youtubeController != null 
              ? YoutubePlayer(controller: _youtubeController!, showVideoProgressIndicator: true) 
              : const Center(child: CircularProgressIndicator(color: Colors.white));
        } else {
          playerWidget = _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        // Fullscreen mode for landscape
        if (isLandscape) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: playerWidget,
            ),
          );
        }

        // Portrait mode with details
        return Scaffold(
          backgroundColor: Colors.grey[100],
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(widget.lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                // Video Player - fixed height
                Container(
                  color: Colors.black,
                  height: MediaQuery.of(context).size.width * 9 / 16,
                  child: playerWidget,
                ),
                
                // Content - takes remaining space
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Material(
                          color: Colors.white,
                          child: TabBar(
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Theme.of(context).primaryColor,
                            tabs: const [
                              Tab(text: 'Details'),
                              Tab(text: 'Comments'),
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
          Text(widget.lecture.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            widget.lecture.description.isNotEmpty ? widget.lecture.description : "No description available.",
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 24),
          
          if (!_isYoutube && widget.lecture.videoUrl.isNotEmpty) ...[
            Card(
              child: ListTile(
                leading: Icon(_subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off),
                title: const Text('Subtitles'),
                subtitle: Text(_subtitlesEnabled ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: _subtitlesEnabled,
                  onChanged: (v) {
                    setState(() => _subtitlesEnabled = v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(v ? 'Subtitles enabled' : 'Subtitles disabled')),
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
              icon: Icon(_isWatched ? Icons.check_circle : Icons.radio_button_unchecked),
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
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No comments yet', style: TextStyle(color: Colors.grey)),
                      Text('Be the first to comment!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.builder(
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
                Expanded(child: Text('Replying to $_replyingToUserName', style: const TextStyle(color: Colors.blue))),
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
            left: 12, right: 12, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 12 + MediaQuery.of(context).padding.bottom,
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
                    hintText: _replyingToCommentId != null ? 'Write a reply...' : 'Add a comment...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _postComment(),
                ),
              ),
              const SizedBox(width: 8),
              _isPostingComment
                  ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _postComment),
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
                backgroundImage: data['userPhoto'] != null ? NetworkImage(data['userPhoto']) : null,
                child: data['userPhoto'] == null ? Text(userName[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        if (createdAt != null)
                          Text(_formatTimeAgo(createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const Spacer(),
                        if (isOwner)
                          GestureDetector(
                            onTap: () => _deleteComment(commentId),
                            child: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(data['text'] ?? '', style: const TextStyle(height: 1.4)),
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
                            Text('Reply', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                    final replyTime = (replyData['createdAt'] as Timestamp?)?.toDate();
                    final replyUserName = replyData['userName'] ?? 'Student';
                    final replyUserId = replyData['userId'] as String?;
                    final isReplyOwner = replyUserId != null && replyUserId == FirebaseAuth.instance.currentUser?.uid;
                    
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
                                backgroundImage: replyData['userPhoto'] != null ? NetworkImage(replyData['userPhoto']) : null,
                                child: replyData['userPhoto'] == null 
                                    ? Text(replyUserName[0].toUpperCase(), style: const TextStyle(fontSize: 9))
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(replyUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        const SizedBox(width: 6),
                                        if (replyTime != null)
                                          Text(_formatTimeAgo(replyTime), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                                        const Spacer(),
                                        if (isReplyOwner)
                                          GestureDetector(
                                            onTap: () => _deleteReply(commentId, replyDoc.id),
                                            child: const Icon(Icons.delete_outline, size: 14, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(replyData['text'] ?? '', style: const TextStyle(fontSize: 12, height: 1.3)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Reply button for replies too
                          Padding(
                            padding: const EdgeInsets.only(left: 32, top: 4),
                            child: InkWell(
                              onTap: () => _startReply(commentId, replyUserName),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.reply, size: 12, color: Colors.grey),
                                  SizedBox(width: 2),
                                  Text('Reply', style: TextStyle(color: Colors.grey, fontSize: 10)),
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
    if (diff.inDays > 7) return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
