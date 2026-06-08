// file: lib/store/see_all_courses_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/store/widgets/course_list_card.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/store/services/store_repository.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';

class SeeAllCoursesPage extends StatelessWidget {
  final String title;

  const SeeAllCoursesPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<Course>>(
        stream: StoreRepository().getCourses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!;

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No courses available',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseListCard(
                course: course,
                onTap: () {
                  if (course.batches.length == 1) {
                    final batch = course.batches.first;
                    final cartItem = CartItem(
                      courseId: course.id,
                      batchId: batch.id,
                      title: '${course.title} - ${batch.name}',
                      price: batch.finalPrice,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PurchaseCartPage(initialItems: [cartItem]),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailPage(course: course),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

