// file: lib/store/widgets/banner_slider.dart
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/store/models/store_models.dart';

/// A responsive banner slider that shows courses with most recently added batches
class BannerSlider extends StatelessWidget {
  const BannerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive height based on screen width
    final double bannerHeight = screenWidth > 600 ? 220.0 : 180.0;
    final double viewportFraction = screenWidth > 900 ? 0.6 : (screenWidth > 600 ? 0.8 : 0.9);

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
                    // Navigate to course detail page with full course data including batches
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
                          color: banner.colors.first.withOpacity(0.3),
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
                                    Colors.black.withOpacity(0.7),
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
                              // New batch badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'NEW BATCH ADDED',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 11 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Course title
                              Text(
                                banner.courseTitle,
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Latest batch name
                              Text(
                                banner.latestBatchName,
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 16 : 14,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // Batch count and price row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.groups, color: Colors.white, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${banner.batchCount} ${banner.batchCount == 1 ? 'Batch' : 'Batches'}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
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
                                    ),
                                    child: Text(
                                      'From ₹${banner.lowestPrice.toInt()}',
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

  /// Fetch courses with their batches, sorted by most recently added batch
  Future<List<_BannerData>> _getCoursesWithRecentBatches() async {
    final List<_BannerData> banners = [];

    try {
      // Get all published courses
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('visibility', isEqualTo: 'published')
          .get();

      for (final courseDoc in courseSnapshot.docs) {
        final courseData = courseDoc.data();
        
        // Parse gradient colors
        List<Color> gradientColors = [Colors.blue, Colors.blueAccent];
        if (courseData['gradientColors'] != null) {
          gradientColors = (courseData['gradientColors'] as List<dynamic>)
              .map((c) => Color(c as int))
              .toList();
        }

        // Fetch all batches for this course
        List<Batch> batches = [];
        DateTime? mostRecentBatchDate;
        String latestBatchName = '';

        // Fetch from subcollection (Admin-created)
        try {
          final batchSnapshot = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseDoc.id)
              .collection('batches')
              .where('isActive', isEqualTo: true)
              .get();

          for (final batchDoc in batchSnapshot.docs) {
            final b = batchDoc.data();
            final startDate = (b['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
            final createdAt = (b['createdAt'] as Timestamp?)?.toDate() ?? startDate;
            
            batches.add(Batch(
              id: batchDoc.id,
              name: b['name'] ?? 'Batch',
              startDate: startDate,
              price: (b['price'] as num?)?.toDouble() ?? (courseData['priceDefault'] as num?)?.toDouble() ?? 0.0,
              seatsLeft: b['seatsLeft'] ?? 0,
              duration: _calculateDuration(
                startDate,
                (b['endDate'] as Timestamp?)?.toDate(),
              ),
              isEnrolled: false,
            ));

            // Track most recently created batch
            if (mostRecentBatchDate == null || createdAt.isAfter(mostRecentBatchDate)) {
              mostRecentBatchDate = createdAt;
              latestBatchName = b['name'] ?? 'New Batch';
            }
          }
        } catch (e) {
          debugPrint('Error fetching batches for ${courseDoc.id}: $e');
        }

        // Also check embedded batches array (legacy support)
        if (courseData['batches'] != null && (courseData['batches'] as List).isNotEmpty) {
          final embeddedBatches = courseData['batches'] as List<dynamic>;
          for (final b in embeddedBatches) {
            final batchId = b['id'] ?? '';
            // Avoid duplicates
            if (!batches.any((batch) => batch.id == batchId)) {
              final startDate = b['startDate'] != null 
                  ? DateTime.tryParse(b['startDate']) ?? DateTime.now() 
                  : DateTime.now();
              
              batches.add(Batch(
                id: batchId,
                name: b['name'] ?? 'Batch',
                startDate: startDate,
                price: (b['price'] as num?)?.toDouble() ?? (courseData['priceDefault'] as num?)?.toDouble() ?? 0.0,
                seatsLeft: b['seatsLeft'] ?? 0,
                duration: b['duration'] ?? '3 months',
                isEnrolled: b['isEnrolled'] ?? false,
              ));

              // Use embedded batch date if no subcollection batches
              if (mostRecentBatchDate == null) {
                mostRecentBatchDate = startDate;
                latestBatchName = b['name'] ?? 'Batch';
              }
            }
          }
        }

        // Skip courses with no batches
        if (batches.isEmpty) continue;

        // Find lowest price among all batches
        final lowestPrice = batches.map((b) => b.price).reduce((a, b) => a < b ? a : b);

        final course = Course(
          id: courseDoc.id,
          title: courseData['title'] ?? '',
          subtitle: courseData['subtitle'] ?? '',
          emoji: courseData['emoji'] ?? '📚',
          gradientColors: gradientColors.length >= 2 ? gradientColors : [Colors.blue, Colors.blueAccent],
          thumbnailUrl: courseData['thumbnailUrl'] ?? '',
          priceDefault: (courseData['priceDefault'] as num?)?.toDouble() ?? 0.0,
          batches: batches, // Include all batches!
        );

        banners.add(_BannerData(
          courseTitle: courseData['title'] ?? 'Course',
          latestBatchName: latestBatchName,
          emoji: courseData['emoji'] ?? '📚',
          colors: gradientColors.length >= 2 ? gradientColors : [Colors.blue, Colors.blueAccent],
          thumbnailUrl: courseData['thumbnailUrl'] ?? '',
          mostRecentBatchDate: mostRecentBatchDate ?? DateTime.now(),
          lowestPrice: lowestPrice,
          batchCount: batches.length,
          course: course,
        ));
      }

      // Sort by most recently added batch (newest first)
      banners.sort((a, b) => b.mostRecentBatchDate.compareTo(a.mostRecentBatchDate));
      
      // Limit to 5 courses
      return banners.take(5).toList();
    } catch (e) {
      debugPrint('Error fetching courses with batches: $e');
      return [];
    }
  }

  String _calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '3 months';
    final days = end.difference(start).inDays;
    if (days > 30) {
      return '${(days / 30).round()} months';
    }
    return '$days days';
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
                color: Colors.white.withOpacity(0.2),
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
