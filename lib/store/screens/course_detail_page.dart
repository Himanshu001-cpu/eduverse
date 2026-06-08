import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/study/screens/course_section_page.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';
import 'package:eduverse/study/models/study_models.dart'; // For StudyCourseModel conversion

class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnrolled = course.isEnrolled;
    final discountPercent = course.realPrice > 0 && course.realPrice > course.finalPrice
        ? ((course.realPrice - course.finalPrice) / course.realPrice * 100).toStringAsFixed(0)
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                course.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: course.thumbnailUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          course.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildGradientBackground(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildGradientBackground(showLoader: true);
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle
                  Text(
                    course.subtitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Details Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            Icons.calendar_today_outlined,
                            'Start Date',
                            course.startDate != null
                                ? DateFormat('MMMM d, yyyy').format(course.startDate!)
                                : 'Immediate Access',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            context,
                            Icons.hourglass_empty_outlined,
                            'Duration',
                            course.duration.isNotEmpty ? course.duration : 'Self-paced',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            context,
                            Icons.event_seat_outlined,
                            'Seating Capacity',
                            course.seatsTotal > 0
                                ? '${course.seatsLeft} of ${course.seatsTotal} seats remaining'
                                : 'Unlimited Access',
                            valueColor: course.seatsLeft < 10 && course.seatsTotal > 0
                                ? Colors.red.shade700
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Description
                  if (course.description.isNotEmpty) ...[
                    const Text(
                      'About This Course',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      course.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Curated Purchase / Access Block
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price Summary',
                                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${course.finalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    if (course.realPrice > course.finalPrice) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${course.realPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (discountPercent != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: isEnrolled
                              ? ElevatedButton.icon(
                                  onPressed: () => _navigateToStudy(context),
                                  icon: const Icon(Icons.school),
                                  label: const Text('Go to Lessons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _addToCartAndCheckout(context),
                                  icon: const Icon(Icons.shopping_cart),
                                  label: const Text('Enroll Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToStudy(BuildContext context) {
    final studyCourse = StudyCourseModel(
      id: course.id,
      title: course.title,
      subtitle: course.subtitle,
      emoji: course.emoji,
      gradientColors: course.gradientColors,
      lessonCount: 0,
      progress: 0.0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseSectionPage(course: studyCourse, batchId: ''),
      ),
    );
  }

  void _addToCartAndCheckout(BuildContext context) {
    final cartItem = CartItem(
      courseId: course.id,
      batchId: '',
      title: course.title,
      price: course.finalPrice,
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
            : Text(course.emoji, style: const TextStyle(fontSize: 64)),
      ),
    );
  }
}
