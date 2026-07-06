import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
import 'package:eduverse/core/firebase/live_viewer_service.dart';

/// A widget that displays all currently live classes from the student's enrolled batches.
/// Users can click 'JOIN' to directly enter the video player.
class LiveClassesSection extends StatelessWidget {
  const LiveClassesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);
    final liveViewerService = LiveViewerService();

    // Filter classes that are currently live
    final liveClasses = controller.allLiveClasses.where((lc) {
      final isLive = YouTubeUtils.shouldTreatAsLive(
        url: lc.youtubeUrl ?? '',
        status: lc.status,
        startTime: lc.startTime,
        durationMinutes: lc.durationMinutes,
      );
      return isLive;
    }).toList();

    if (liveClasses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.live_tv_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Live Classes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8),
              Card(
                color: Colors.red,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            key: const Key('live_classes_list_view'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: liveClasses.length,
            itemBuilder: (context, index) {
              final liveClass = liveClasses[index];

              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('live_class_card_${liveClass.id}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (liveClass.youtubeUrl != null && liveClass.youtubeUrl!.isNotEmpty) {
                        final lecture = StudyLecture(
                          id: liveClass.id,
                          title: liveClass.title,
                          videoUrl: liveClass.youtubeUrl!,
                          description: liveClass.description,
                          order: 0,
                          duration: Duration(minutes: liveClass.durationMinutes),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider.value(
                              value: controller,
                              child: LecturePlayerScreen(
                                courseId: liveClass.courseId ?? '',
                                batchId: liveClass.batchId ?? '',
                                lecture: lecture,
                                isLiveStream: true,
                              ),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Class link not available yet')),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        liveClass.subject.isNotEmpty ? liveClass.subject.toUpperCase() : 'LIVE CLASS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        liveClass.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.videocam, color: Colors.red, size: 24),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StreamBuilder<int>(
                                  stream: liveViewerService.viewerCountStream(
                                    liveClass.courseId ?? '',
                                    liveClass.batchId ?? '',
                                    liveClass.id,
                                  ),
                                  builder: (context, snapshot) {
                                    final viewerCount = snapshot.data ?? 0;
                                    return Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$viewerCount watching',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'JOIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
