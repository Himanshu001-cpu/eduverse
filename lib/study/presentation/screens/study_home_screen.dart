import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudyHomeScreen extends StatelessWidget {
  const StudyHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access controller provided by parent or higher up
    // In this clean architecture, we consume the controller.
    // Ensure ChangeNotifierProvider<StudyController> is up in the tree.
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Learning'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Consumer<StudyController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${controller.error}'),
                  ElevatedButton(
                    onPressed: () { 
                       // Trigger refresh if we add a refresh method
                    },
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          final courses = controller.enrolledCourses;

          if (courses.isEmpty) {
            return const Center(
              child: Text(
                'No enrolled courses yet.\nVisit the Store to enroll!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseCard(context: context, course: course);
            },
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final BuildContext context;
  final StudyCourse course;

  const _CourseCard({
    required this.context,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(course: course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Emoji / Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: course.gradientColors.isNotEmpty 
                        ? course.gradientColors 
                        : [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    course.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: course.progress,
                            backgroundColor: Colors.grey[200],
                            color: Colors.green, // Done color
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(course.progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
