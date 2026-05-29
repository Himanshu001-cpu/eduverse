import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/services/store_repository.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';

class NewBatchPromotionService {
  static final NewBatchPromotionService _instance = NewBatchPromotionService._internal();
  factory NewBatchPromotionService() => _instance;
  NewBatchPromotionService._internal();

  bool _isChecking = false;

  Future<void> checkForNewBatchPromotion(BuildContext context) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Get all published courses from StoreRepository
      final courses = await StoreRepository().getCourses().first;
      if (courses.isEmpty) return;

      // 2. Get student's enrolled batch IDs directly from Firestore for accuracy
      final enrolledCoursesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrolledCourses')
          .get();

      final enrolledBatchIds = enrolledCoursesSnap.docs
          .map((doc) => doc.data()['batchId'] as String?)
          .whereType<String>()
          .toSet();

      // 3. Collect all batches that the student is NOT enrolled in
      final List<_PromoBatchItem> eligibleBatches = [];
      for (final course in courses) {
        for (final batch in course.batches) {
          if (!enrolledBatchIds.contains(batch.id)) {
            eligibleBatches.add(_PromoBatchItem(course: course, batch: batch));
          }
        }
      }

      if (eligibleBatches.isEmpty) return;

      // 4. Sort eligible batches by startDate (newest first)
      eligibleBatches.sort((a, b) => b.batch.startDate.compareTo(a.batch.startDate));

      // 5. Select the absolute newest batch
      final newestPromo = eligibleBatches.first;

      // 6. Check if this batch promo has already been shown/dismissed
      final prefs = await SharedPreferences.getInstance();
      final promoKey = 'shown_promo_batch_${newestPromo.batch.id}';
      final hasBeenShown = prefs.getBool(promoKey) ?? false;

      if (hasBeenShown) return;

      // 7. Show the stunning promotional dialog!
      if (context.mounted) {
        await _showPromoDialog(context, newestPromo, promoKey);
      }
    } catch (e) {
      debugPrint('Error checking for new batch promotion: $e');
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _showPromoDialog(
    BuildContext context,
    _PromoBatchItem promo,
    String promoKey,
  ) async {
    final course = promo.course;
    final batch = promo.batch;

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'New Batch Promotion',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curveValue = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curveValue,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: _PromoDialogContent(
                course: course,
                batch: batch,
                onDismiss: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(promoKey, true);
                  if (context.mounted) Navigator.pop(context);
                },
                onExplore: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(promoKey, true);
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailPage(course: course),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PromoBatchItem {
  final Course course;
  final Batch batch;

  _PromoBatchItem({required this.course, required this.batch});
}

class _PromoDialogContent extends StatelessWidget {
  final Course course;
  final Batch batch;
  final VoidCallback onDismiss;
  final VoidCallback onExplore;

  const _PromoDialogContent({
    required this.course,
    required this.batch,
    required this.onDismiss,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = course.gradientColors.isNotEmpty
        ? course.gradientColors.first
        : Colors.indigo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium Header with Course Gradient and Emoji
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: course.gradientColors.isNotEmpty
                  ? course.gradientColors
                  : [Colors.blue, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              // Pulsing launcher badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'NEW LAUNCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Big Emoji
              Text(
                course.emoji,
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 12),
              // Course Title
              Text(
                course.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (course.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  course.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Batch details and price info
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.layers_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      batch.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Highlights list
              _buildHighlightRow(Icons.calendar_today, 'Starts: ${batch.startDate.day}/${batch.startDate.month}/${batch.startDate.year}'),
              const SizedBox(height: 8),
              _buildHighlightRow(Icons.hourglass_bottom, 'Duration: ${batch.duration}'),
              const SizedBox(height: 8),
              _buildHighlightRow(Icons.event_seat, 'Limited Seats Left: ${batch.seatsLeft}'),
              const Divider(height: 32),
              // Pricing Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Special Launch Price:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (batch.realPrice > batch.finalPrice)
                        Text(
                          '₹${batch.realPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        '₹${batch.finalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onExplore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Explore Batch'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
        ),
      ],
    );
  }
}
