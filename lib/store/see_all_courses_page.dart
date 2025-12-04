// file: lib/store/see_all_courses_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/store/store_data.dart';
import 'package:eduverse/store/widgets/course_list_card.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';

class SeeAllCoursesPage extends StatelessWidget {
  final String title;

  const SeeAllCoursesPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: StoreData.courses.length,
        itemBuilder: (context, index) {
          final course = StoreData.courses[index];
          return CourseListCard(
            course: course,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailPage(course: course),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
