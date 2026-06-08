// file: lib/store/widgets/banner_slider.dart
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A responsive banner slider that shows courses with most recently added batches
class BannerSlider extends StatelessWidget {
  const BannerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive viewport fraction
    final double viewportFraction = screenWidth > 900 ? 0.6 : (screenWidth > 600 ? 0.8 : 0.9);
    // 16:9 aspect ratio based on visible card width
    final double cardWidth = screenWidth * viewportFraction;
    final double bannerHeight = cardWidth * 9 / 16;

    return FutureBuilder<List<_BannerData>>(
      future: _getCoursesWithRecentBatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: bannerHeight,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: bannerHeight,
            child: const Center(child: Text('No courses available')),
          );
        }

        final banners = snapshot.data!;

        return carousel.CarouselSlider(
          options: carousel.CarouselOptions(
            height: bannerHeight,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            viewportFraction: viewportFraction,
            aspectRatio: 2.0,
          ),
          items: banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to course detail page with full course data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailPage(course: banner.course),
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: banner.colors.first.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background: Thumbnail or Gradient
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: banner.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    banner.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildGradientBackground(banner, screenWidth),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return _buildGradientBackground(banner, screenWidth, showLoader: true);
                                    },
                                  )
                                : _buildGradientBackground(banner, screenWidth),
                          ),
                        ),
                        // Dark overlay for text readability when using thumbnail
                        if (banner.thumbnailUrl.isNotEmpty)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Content
                        Padding(
                          padding: EdgeInsets.all(screenWidth > 600 ? 24.0 : 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // New course badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'NEW COURSE LAUNCH',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 11 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Course title
                              Text(
                                banner.courseTitle,
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // Full Access and pricing row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Full Access',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '₹${banner.lowestPrice.toInt()}',
                                      style: TextStyle(
                                        color: banner.colors.first,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// Fetch courses, sorted by start date
  Future<List<_BannerData>> _getCoursesWithRecentBatches() async {
    final List<_BannerData> banners = [];

    try {
      final user = FirebaseAuth.instance.currentUser;
      final List<String> enrolledCourseIds = [];
      if (user != null) {
        try {
          final enrollsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('enrolledCourses')
              .get();
          for (final doc in enrollsSnapshot.docs) {
            final data = doc.data();
            final courseId = data['courseId'] as String? ?? doc.id.split('_')[0];
            if (courseId.isNotEmpty) {
              enrolledCourseIds.add(courseId);
            }
          }
        } catch (e) {
          debugPrint('Failed to fetch user enrollments for banner: $e');
        }
      }

      // Get all published active courses
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('visibility', isEqualTo: 'published')
          .where('isActive', isEqualTo: true)
          .get();

      for (final courseDoc in courseSnapshot.docs) {
        final courseData = courseDoc.data();
        final courseId = courseDoc.id;

        // Parse gradient colors
        List<Color> gradientColors = [Colors.blue, Colors.blueAccent];
        if (courseData['gradientColors'] != null) {
          gradientColors = (courseData['gradientColors'] as List<dynamic>)
              .map((c) => Color(c as int))
              .toList();
        }

        final isEnrolled = enrolledCourseIds.contains(courseId);

        // Skip if already enrolled
        if (isEnrolled) continue;

        final realPrice = (courseData['realPrice'] as num?)?.toDouble() ?? 0.0;
        final finalPrice = (courseData['finalPrice'] as num?)?.toDouble() ?? 0.0;

        final course = Course(
          id: courseId,
          title: courseData['title'] ?? '',
          subtitle: courseData['subtitle'] ?? '',
          description: courseData['description'] ?? '',
          emoji: courseData['emoji'] ?? '📚',
          gradientColors: gradientColors.length >= 2 ? gradientColors : [Colors.blue, Colors.blueAccent],
          thumbnailUrl: courseData['thumbnailUrl'] ?? '',
          priceDefault: (courseData['priceDefault'] as num?)?.toDouble() ?? 0.0,
          realPrice: realPrice,
          finalPrice: finalPrice,
          startDate: courseData['startDate'] != null
              ? (courseData['startDate'] is Timestamp
                  ? (courseData['startDate'] as Timestamp).toDate()
                  : DateTime.tryParse(courseData['startDate'].toString()))
              : null,
          endDate: courseData['endDate'] != null
              ? (courseData['endDate'] is Timestamp
                  ? (courseData['endDate'] as Timestamp).toDate()
                  : DateTime.tryParse(courseData['endDate'].toString()))
              : null,
          seatsTotal: courseData['seatsTotal'] ?? 0,
          seatsLeft: courseData['seatsLeft'] ?? 0,
          duration: courseData['duration'] ?? '',
          isActive: courseData['isActive'] ?? true,
          isEnrolled: isEnrolled,
        );

        banners.add(_BannerData(
          courseTitle: course.title,
          latestBatchName: 'Active Course',
          emoji: course.emoji,
          colors: course.gradientColors,
          thumbnailUrl: course.thumbnailUrl,
          mostRecentBatchDate: course.startDate ?? DateTime.now(),
          lowestPrice: course.finalPrice,
          batchCount: 1,
          course: course,
        ));
      }

      // Sort by start date (newest first)
      banners.sort((a, b) => b.mostRecentBatchDate.compareTo(a.mostRecentBatchDate));
      
      return banners.take(5).toList();
    } catch (e) {
      debugPrint('Error fetching courses for banners: $e');
      return [];
    }
  }

  Widget _buildGradientBackground(_BannerData banner, double screenWidth, {bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background emoji
          Positioned(
            right: -20,
            bottom: -20,
            child: Text(
              banner.emoji,
              style: TextStyle(
                fontSize: screenWidth > 600 ? 120 : 100,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          if (showLoader)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

/// Internal data class for banner display
class _BannerData {
  final String courseTitle;
  final String latestBatchName;
  final String emoji;
  final List<Color> colors;
  final String thumbnailUrl;
  final DateTime mostRecentBatchDate;
  final double lowestPrice;
  final int batchCount;
  final Course course;

  _BannerData({
    required this.courseTitle,
    required this.latestBatchName,
    required this.emoji,
    required this.colors,
    this.thumbnailUrl = '',
    required this.mostRecentBatchDate,
    required this.lowestPrice,
    required this.batchCount,
    required this.course,
  });
}
