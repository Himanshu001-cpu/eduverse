import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/course_card.dart';

class CoursesListScreen extends StatelessWidget {
  const CoursesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    return AdminScaffold(
      title: 'Courses',
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/course_editor'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<AdminCourse>>(
        stream: service.getCourses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final courses = snapshot.data!;
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseCard(
                course: course,
                onTap: () => Navigator.pushNamed(context, '/course_editor', arguments: course),
                onDelete: () => service.deleteCourse(course.id),
              );
            },
          );
        },
      ),
    );
  }
}
