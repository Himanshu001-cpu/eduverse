// file: lib/store/store_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/store/store_data.dart';
import 'package:eduverse/store/widgets/banner_slider.dart';
import 'package:eduverse/store/widgets/course_card.dart';
import 'package:eduverse/store/see_all_courses_page.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/store/services/store_repository.dart';
import 'package:eduverse/store/models/store_models.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Image.asset('assets/icon.png', height: 30),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const BannerSlider(),
            const SizedBox(height: 24),
            
            // Featured Courses
            _buildSectionHeader(context, 'Featured Courses', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SeeAllCoursesPage(title: 'Featured Courses'),
                ),
              );
            }),
            SizedBox(
              height: 180,
              child: StreamBuilder<List<Course>>(
                stream: StoreRepository().getCourses(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final courses = snapshot.data!;
                  if (courses.isEmpty) {
                     // Trigger seeding if empty (for demo purposes)
                     StoreRepository().seedInitialData();
                     return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return CourseCard(
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
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Trending
            _buildSectionHeader(context, 'Trending Now', () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SeeAllCoursesPage(title: 'Trending Now'),
                ),
              );
            }),
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: StoreData.courses.reversed.toList().length,
                itemBuilder: (context, index) {
                  final course = StoreData.courses.reversed.toList()[index];
                  return CourseCard(
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
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }
}
