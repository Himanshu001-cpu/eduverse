import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/core/services/live_class_notifier_service.dart';

class LiveClassPopup extends StatefulWidget {
  const LiveClassPopup({super.key});

  @override
  State<LiveClassPopup> createState() => _LiveClassPopupState();
}

class _LiveClassPopupState extends State<LiveClassPopup> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  ActiveLiveClass? _currentActive;
  ActiveLiveClass? _pendingUpdate;
  bool _hasPendingCallback = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.2), // Slide in from bottom-left
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 96, // Elevated above bottom navigation bar
      child: Consumer<LiveClassNotifierService>(
        builder: (context, service, child) {
          // Find the first active live class that has not been dismissed
          final activeList = service.activeClasses
              .where((ac) => !service.dismissedClassIds.contains(ac.liveClass.id))
              .toList();

          final nextActive = activeList.isEmpty ? null : activeList.first;

          final shouldUpdate = (_currentActive == null && nextActive != null) ||
              (nextActive?.liveClass.id != _currentActive?.liveClass.id);

          if (shouldUpdate) {
            _pendingUpdate = nextActive;
            if (!_hasPendingCallback) {
              _hasPendingCallback = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _hasPendingCallback = false;
                if (!mounted) return;
                final update = _pendingUpdate;
                setState(() {
                  _currentActive = update;
                });
                if (update == null) {
                  _animController.reverse();
                } else {
                  _animController.forward(from: 0.0);
                }
              });
            }
          }

          if (_currentActive == null) {
            return const SizedBox.shrink();
          }

          return SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildPopupCard(context, service, _currentActive!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopupCard(BuildContext context, LiveClassNotifierService service, ActiveLiveClass active) {
    final liveClass = active.liveClass;
    
    return Container(
      width: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.25),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _joinLiveClass(context, active),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  // Thumbnail Section with pulsing badge
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 57,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                          image: liveClass.thumbnailUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(liveClass.thumbnailUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: liveClass.thumbnailUrl.isEmpty
                            ? const Icon(Icons.videocam, color: Colors.white54, size: 28)
                            : null,
                      ),
                      // pulsing Live indicator
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Text and Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          liveClass.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        if (liveClass.instructorName.isNotEmpty)
                          Text(
                            liveClass.instructorName,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to Join Now',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close Button Column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          service.dismissClass(liveClass.id);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _joinLiveClass(BuildContext context, ActiveLiveClass active) {
    final liveClass = active.liveClass;
    if (liveClass.youtubeUrl != null && liveClass.youtubeUrl!.isNotEmpty) {
      final lecture = StudyLecture(
        id: liveClass.id,
        title: liveClass.title,
        videoUrl: liveClass.youtubeUrl!,
        description: liveClass.description,
        order: 0,
        duration: Duration(minutes: liveClass.durationMinutes),
      );

      StudyController? controller;
      try {
        controller = Provider.of<StudyController>(context, listen: false);
      } catch (_) {}

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) {
            final playerScreen = LecturePlayerScreen(
              courseId: active.courseId,
              batchId: active.batchId,
              lecture: lecture,
              isLiveStream: YouTubeUtils.shouldTreatAsLive(
                url: liveClass.youtubeUrl ?? '',
                status: liveClass.status,
                startTime: liveClass.startTime,
                durationMinutes: liveClass.durationMinutes,
              ),
            );
            if (controller != null) {
              return ChangeNotifierProvider.value(
                value: controller,
                child: playerScreen,
              );
            }
            return playerScreen;
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class link not available yet'),
        ),
      );
    }
  }
}
