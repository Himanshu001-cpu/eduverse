import 'package:flutter/material.dart';
import '../models/admin_models.dart';

class CourseCard extends StatelessWidget {
  final AdminCourse course;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CourseCard({Key? key, required this.course, required this.onTap, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: course.thumbnailUrl.isNotEmpty 
            ? Image.network(course.thumbnailUrl, width: 50, fit: BoxFit.cover)
            : const Icon(Icons.image),
        title: Text(course.title),
        subtitle: Text('${course.visibility.toUpperCase()} • ${course.language}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onTap),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
