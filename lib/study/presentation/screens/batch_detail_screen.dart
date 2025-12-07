import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';

class BatchDetailScreen extends StatefulWidget {
  final StudyBatch batch;

  const BatchDetailScreen({Key? key, required this.batch}) : super(key: key);

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  late Future<List<StudyLecture>> _lecturesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch lectures when screen loads
    _lecturesFuture = Provider.of<StudyController>(context, listen: false)
        .getLectures(widget.batch.courseId, widget.batch.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
         title: Text(widget.batch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
         backgroundColor: Colors.white,
         foregroundColor: Colors.black,
         elevation: 0,
         centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Banner
            Container(
              width: double.infinity,
              height: 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: widget.batch.gradientColors.isNotEmpty
                      ? widget.batch.gradientColors
                      : [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.batch.gradientColors.isNotEmpty ? widget.batch.gradientColors.first : Colors.blue).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                   Center(
                     child: Text(
                       widget.batch.emoji,
                       style: const TextStyle(fontSize: 80),
                     ),
                   ),
                   Positioned(
                     bottom: 20,
                     left: 20,
                     right: 20,
                     child: Text(
                       widget.batch.courseName,
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                       ),
                       textAlign: TextAlign.center,
                     ),
                   )
                ],
              ),
            ),
            
            // Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Your Progress",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${(widget.batch.progress * 100).toInt()}% Completed",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.batch.progress,
                      backgroundColor: Colors.grey[100],
                      color: Colors.green,
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 16),

            // Lectures ListHeader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Text("Batch Content", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<StudyLecture>>(
              future: _lecturesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                final lectures = snapshot.data ?? [];
                if (lectures.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No lectures available.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: lectures.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lecture = lectures[index];
                    return InkWell(
                      onTap: () async {
                        final studyController = Provider.of<StudyController>(context, listen: false);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider.value(
                              value: studyController,
                              child: LecturePlayerScreen(
                                courseId: widget.batch.courseId,
                                batchId: widget.batch.id,
                                lecture: lecture,
                              ),
                            ),
                          ),
                        );
                        // Refresh lectures on return to update watched status
                        setState(() {
                           _lecturesFuture = Provider.of<StudyController>(context, listen: false)
                              .getLectures(widget.batch.courseId, widget.batch.id);
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: lecture.isWatched ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                lecture.isWatched ? Icons.check_circle : Icons.play_arrow_rounded,
                                color: lecture.isWatched ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lecture.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Lecture ${lecture.order}",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
