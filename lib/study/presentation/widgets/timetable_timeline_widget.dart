import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/study_controller.dart';
import '../../domain/models/study_entities.dart';
import '../screens/lecture_player_screen.dart';

class TimetableTimelineWidget extends StatefulWidget {
  final String? courseId;

  const TimetableTimelineWidget({super.key, this.courseId});

  @override
  State<TimetableTimelineWidget> createState() => _TimetableTimelineWidgetState();
}

class _TimetableTimelineWidgetState extends State<TimetableTimelineWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh countdown timers every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentlyLive(StudyLiveClass item) {
    if (item.status == 'live') return true;
    final now = DateTime.now();
    final endTime = item.startTime.add(Duration(minutes: item.durationMinutes));
    return item.status == 'scheduled' && now.isAfter(item.startTime) && now.isBefore(endTime);
  }

  String _formatCountdown(DateTime startTime) {
    final now = DateTime.now();
    final diff = startTime.difference(now);
    if (diff.isNegative) return '';
    if (diff.inDays > 0) {
      return 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return 'Starts in ${diff.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    StudyController? controller;
    try {
      controller = context.watch<StudyController>();
    } catch (_) {
      // Tolerate missing provider in tests
    }
    
    // 1. Fetch live classes for all enrolled courses
    List<StudyLiveClass> classes = controller?.allLiveClasses ?? [];

    // 2. Filter by courseId if specified
    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      classes = classes.where((c) => c.courseId == widget.courseId).toList();
    }

    if (classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Timetable Timeline for course: ${widget.courseId ?? "All"}'),
              const SizedBox(height: 16),
              const Text('Timeline view placeholder.'),
            ],
          ),
        ),
      );
    }

    // 3. Generate today + next 7 days list (8 days total)
    final now = DateTime.now();
    final days = List.generate(8, (index) {
      final date = now.add(Duration(days: index));
      return DateTime(date.year, date.month, date.day);
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Timetable Timeline for course: ${widget.courseId ?? "All"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          ...days.map((day) {
            final dayClasses = classes.where((c) => _isSameDay(c.startTime, day)).toList();
            // Sort classes chronologically by start time
            dayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

            String dayHeader = '';
            if (_isSameDay(day, now)) {
              dayHeader = 'Today';
            } else if (_isSameDay(day, now.add(const Duration(days: 1)))) {
              dayHeader = 'Tomorrow';
            } else {
              dayHeader = DateFormat('EEEE, MMMM d').format(day);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dayHeader,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                if (dayClasses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: Text(
                      '(No classes)',
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...dayClasses.map((item) {
                    final isLive = _isCurrentlyLive(item);
                    final isCancelled = item.status == 'cancelled';
                    final isCompleted = item.status == 'completed';

                    Color statusColor = Colors.blue;
                    String statusText = 'UPCOMING';
                    if (isLive) {
                      statusColor = Colors.red;
                      statusText = 'LIVE';
                    } else if (isCancelled) {
                      statusColor = Colors.grey;
                      statusText = 'CANCELLED';
                    } else if (isCompleted) {
                      statusColor = Colors.green;
                      statusText = 'COMPLETED';
                    }

                    return Card(
                      elevation: isLive ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isLive ? Colors.red : Colors.grey.shade200,
                          width: isLive ? 2.0 : 1.0,
                        ),
                      ),
                      margin: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                                      color: isCancelled ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  item.instructorName,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${DateFormat('hh:mm a').format(item.startTime)} - ${DateFormat('hh:mm a').format(item.startTime.add(Duration(minutes: item.durationMinutes)))}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (item.subject.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.bookmark_border, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.subject,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                            if (!isCancelled && !isCompleted) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (isLive) ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('JOIN NOW'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (ctx) => LecturePlayerScreen(
                                              courseId: item.courseId,
                                              batchId: item.batchId,
                                              lecture: StudyLecture(
                                                id: item.id,
                                                title: item.title,
                                                videoUrl: item.youtubeUrl ?? '',
                                                subject: item.subject,
                                                chapter: item.chapter,
                                              ),
                                              isLiveStream: true,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ] else ...[
                                    Text(
                                      _formatCountdown(item.startTime),
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          }),
        ],
      ),
    );
  }
}
