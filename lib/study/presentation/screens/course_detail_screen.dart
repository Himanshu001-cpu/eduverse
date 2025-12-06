import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final StudyCourse course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<List<StudyLecture>> _lecturesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch lectures when screen loads
    _lecturesFuture = Provider.of<StudyController>(context, listen: false)
        .getLectures(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
         title: Text(widget.course.title),
         backgroundColor: Colors.white,
         foregroundColor: Colors.black,
         elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Banner
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.course.gradientColors.isNotEmpty
                      ? widget.course.gradientColors
                      : [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                   Center(child: Text(widget.course.emoji, style: const TextStyle(fontSize: 80))),
                   Positioned(
                     bottom: 16,
                     left: 16,
                     right: 16,
                     child: Text(
                       widget.course.subtitle,
                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                     ),
                   )
                ],
              ),
            ),
            
            // Progress Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Course Progress", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${(widget.course.progress * 100).toInt()}%"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: widget.course.progress,
                    backgroundColor: Colors.grey[200],
                    color: Colors.green,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),

            // Lectures List
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text("Lectures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            FutureBuilder<List<StudyLecture>>(
              future: _lecturesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final lectures = snapshot.data ?? [];
                if (lectures.isEmpty) {
                  return const Center(child: Text('No lectures available.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = lectures[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: lecture.isWatched ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        child: Icon(
                          lecture.isWatched ? Icons.check : Icons.play_arrow_rounded,
                          color: lecture.isWatched ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text(lecture.title),
                      subtitle: Text("Lecture ${lecture.order}"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LecturePlayerScreen(
                              courseId: widget.course.id,
                              lecture: lecture,
                            ),
                          ),
                        );
                        // Refresh lectures on return to update watched status
                        setState(() {
                           _lecturesFuture = Provider.of<StudyController>(context, listen: false)
                              .getLectures(widget.course.id);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
