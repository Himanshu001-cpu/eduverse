import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';

class ContinueLearningSection extends StatelessWidget {
  const ContinueLearningSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);
    final box = controller.lectureProgressBox;

    return ValueListenableBuilder<Box<Map>>(
      valueListenable: box.listenable(),
      builder: (context, _, __) => _buildContent(context, controller, box),
    );
  }

  Widget _buildContent(BuildContext context, StudyController controller, Box<Map> box) {
    final inProgressLectures = <Map<String, dynamic>>[];

    // Selected batch details
    StudyBatch? selectedBatch;
    try {
      selectedBatch = controller.enrolledBatches.firstWhere((b) => b.id == controller.selectedBatchId);
    } catch (_) {}

    final allPlayableLectures = <StudyLecture>[];
    allPlayableLectures.addAll(controller.lectures);

    for (final liveClass in controller.allLiveClasses) {
      if (liveClass.youtubeUrl != null && liveClass.youtubeUrl!.isNotEmpty) {
        allPlayableLectures.add(StudyLecture(
          id: liveClass.id,
          title: liveClass.title,
          videoUrl: liveClass.youtubeUrl!,
          description: liveClass.description,
          order: 0,
          duration: Duration(minutes: liveClass.durationMinutes),
          subject: liveClass.subject,
          chapter: liveClass.chapter,
          thumbnailUrl: liveClass.thumbnailUrl,
        ));
      }
    }

    for (final lecture in allPlayableLectures) {
      final progressData = box.get(lecture.id);
      if (progressData != null) {
        try {
          final map = Map<String, dynamic>.from(progressData);
          if (map['progressSeconds'] != null && map['totalDurationSeconds'] != null && map['totalDurationSeconds'] > 0) {
            final double ratio = (map['progressSeconds'] as num).toDouble() / (map['totalDurationSeconds'] as num).toDouble();
            final isCompleted = map['isCompleted'] as bool? ?? false;
            
            if (ratio < 0.95 && !isCompleted) {
              inProgressLectures.add({
                'lecture': lecture,
                'progressSeconds': (map['progressSeconds'] as num).toInt(),
                'totalDurationSeconds': (map['totalDurationSeconds'] as num).toInt(),
                'lastOpened': map['lastOpened'] as String?,
              });
            }
          }
        } catch (_) {}
      }
    }
    // Sort so most recently viewed is first
    inProgressLectures.sort((a, b) {
      final aDate = DateTime.tryParse(a['lastOpened'] ?? '') ?? DateTime(0);
      final bDate = DateTime.tryParse(b['lastOpened'] ?? '') ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    // Always render the section — show header + empty state or header + list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                selectedBatch?.isCombo == true
                    ? 'From all purchased courses'
                    : 'From this course',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        if (inProgressLectures.isEmpty)
          Container(
            key: const Key('continue_learning_empty_placeholder'),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No lectures in progress — start watching to see them here!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else

        SizedBox(
          height: 200,
          child: ListView.builder(
            key: const Key('continue_learning_list_view'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: inProgressLectures.length,
            itemBuilder: (context, index) {
              final item = inProgressLectures[index];
              final StudyLecture lecture = item['lecture'] as StudyLecture;
              final progress = item['progressSeconds'] as int;
              final total = item['totalDurationSeconds'] as int;
              final double pct = progress / total;

              // Find parent batch details for courseId/batchId context
              String? courseId;
              String? batchId;
              StudyBatch? parentBatch;
              try {
                parentBatch = controller.enrolledBatches.firstWhere(
                  (b) => b.courseIds?.contains(lecture.id.split('_')[0]) == true || b.courseId == lecture.id.split('_')[0],
                );
                courseId = parentBatch.courseId;
                batchId = parentBatch.id;
              } catch (_) {
                courseId = lecture.id.split('_')[0];
                batchId = courseId;
              }

              // Compute effective thumbnail URL
              String effectiveThumbnailUrl = '';
              if (lecture.thumbnailUrl.isNotEmpty) {
                effectiveThumbnailUrl = lecture.thumbnailUrl;
              } else {
                final videoId = YouTubeUtils.extractVideoId(lecture.videoUrl);
                if (videoId != null && videoId.isNotEmpty) {
                  effectiveThumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
                } else if (parentBatch != null && parentBatch.thumbnailUrl.isNotEmpty) {
                  effectiveThumbnailUrl = parentBatch.thumbnailUrl;
                }
              }

              return Container(
                width: 230,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('lecture_card_${lecture.id}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: LecturePlayerScreen(
                              courseId: courseId,
                              batchId: batchId,
                              lecture: lecture,
                              startPositionSeconds: progress,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 16:9 Thumbnail section
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: Colors.grey.shade100,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (effectiveThumbnailUrl.isNotEmpty)
                                    Image.network(
                                      effectiveThumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.blue.shade900,
                                        child: Center(
                                          child: Icon(
                                            Icons.play_circle_fill_rounded,
                                            color: Colors.white70,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      color: Colors.blue.shade900,
                                    ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.3),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.4),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lecture.subject.isNotEmpty ? lecture.subject : 'LECTURE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Details section
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lecture.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Progress: ${(pct * 100).toInt()}%',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '${(progress / 60).floor()}m / ${(total / 60).floor()}m',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          key: Key('progress_bar_${lecture.id}'),
                                          value: pct,
                                          backgroundColor: Colors.grey.shade100,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

