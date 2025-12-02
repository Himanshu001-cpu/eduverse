import 'package:flutter/material.dart';
import 'models/store_models.dart';

class SeeAllCoursesPage extends StatefulWidget {
  final String title;
  final List<Course> courses;

  const SeeAllCoursesPage({
    Key? key,
    required this.title,
    required this.courses,
  }) : super(key: key);

  @override
  State<SeeAllCoursesPage> createState() => _SeeAllCoursesPageState();
}

class _SeeAllCoursesPageState extends State<SeeAllCoursesPage> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses.where((course) {
      final q = query.toLowerCase();
      return course.title.toLowerCase().contains(q) ||
          course.batchInfo.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => query = val),
              decoration: InputDecoration(
                hintText: "Search for Courses",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Course list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return CourseListCard(course: filtered[index]);
              },
            ),
          )
        ],
      ),
    );
  }
}


// ===================================================================
// COURSE LIST CARD WIDGET
// ===================================================================
class CourseListCard extends StatelessWidget {
  final Course course;

  const CourseListCard({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Banner Section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: course.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    course.emoji,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            ),

            // Text Section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    course.batchInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course.metadata,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Prices will increase after 22nd Nov",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
