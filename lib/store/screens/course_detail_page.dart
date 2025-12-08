// file: lib/store/screens/course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/widgets/batch_badge.dart';
import 'package:eduverse/study/screens/batch_section_page.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';
import 'package:eduverse/study/models/study_models.dart'; // For StudyCourseModel conversion

class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course.title, style: const TextStyle(fontSize: 16)),
              background: course.thumbnailUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          course.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildGradientBackground(showLoader: true);
                          },
                        ),
                        // Dark overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildGradientBackground(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Available Batches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...course.batches.map((batch) => _buildBatchCard(context, batch)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(BuildContext context, Batch batch) {
    final isEnrolled = batch.isEnrolled;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    batch.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isEnrolled)
                  const BatchBadge(text: 'ENROLLED', color: Colors.green)
                else if (batch.seatsLeft < 10)
                  BatchBadge(text: '${batch.seatsLeft} SEATS LEFT', color: Colors.red)
                else
                  BatchBadge(text: 'OPEN', color: Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            Text('Starts: ${DateFormat('MMM d, y').format(batch.startDate)}'),
            Text('Duration: ${batch.duration}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '₹${batch.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                if (isEnrolled)
                  ElevatedButton(
                    onPressed: () {
                      _navigateToBatch(context, batch);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go to Lessons'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      if (batch.seatsLeft <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Batch is full!')),
                        );
                        return;
                      }
                      _addToCartAndCheckout(context, batch);
                    },
                    child: const Text('Enroll Now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBatch(BuildContext context, Batch batch) {
    // Convert store Course to study CourseModel for compatibility
    final studyCourse = StudyCourseModel(
      id: course.id,
      title: course.title,
      subtitle: course.subtitle,
      emoji: course.emoji,
      gradientColors: course.gradientColors,
      lessonCount: 0, // Mock
      progress: 0.0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchSectionPage(
          course: studyCourse,
          batchId: batch.id,
        ),
      ),
    );
  }

  void _addToCartAndCheckout(BuildContext context, Batch batch) {
    final cartItem = CartItem(
      courseId: course.id,
      batchId: batch.id,
      title: '${course.title} - ${batch.name}',
      price: batch.price,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseCartPage(initialItems: [cartItem]),
      ),
    );
  }

  Widget _buildGradientBackground({bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: course.gradientColors.isNotEmpty
              ? course.gradientColors
              : [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: showLoader
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              )
            : Text(
                course.emoji,
                style: const TextStyle(fontSize: 64),
              ),
      ),
    );
  }
}
