import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';

class PromoBatchResult {
  final Course course;
  final Batch batch;
  final String promoKey;

  PromoBatchResult({
    required this.course,
    required this.batch,
    required this.promoKey,
  });
}

class NewBatchPromotionService {
  static bool _isChecking = false;

  /// Pure query logic that runs business rules to find the newest eligible promo.
  /// Decoupled from BuildContext, making it fully unit-testable!
  Future<PromoBatchResult?> getEligiblePromotion() async {
    if (_isChecking) return null;
    _isChecking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // 1. Get student's enrolled batch IDs directly from Firestore for accuracy
      final enrolledCoursesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrolledCourses')
          .get();

      final enrolledBatchIds = enrolledCoursesSnap.docs
          .map((doc) => doc.data()['batchId'] as String?)
          .whereType<String>()
          .toSet();

      // 2. Fetch active batches via collectionGroup with server-side sort.
      // Requires the composite index in firestore.indexes.json:
      //   collectionGroup: "batches", queryScope: COLLECTION_GROUP
      //   fields: isActive ASC, startDate DESC
      // Deploy with: firebase deploy --only firestore:indexes
      final batchesSnap = await FirebaseFirestore.instance
          .collectionGroup('batches')
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .limit(50)
          .get();

      final eligibleBatchDocs = batchesSnap.docs
          .where((doc) => !enrolledBatchIds.contains(doc.id))
          .toList();

      if (eligibleBatchDocs.isEmpty) return null;

      // Results are already sorted by startDate DESC from Firestore.

      // 4. Find the first eligible batch that has not been dismissed and belongs to a published course
      final prefs = await SharedPreferences.getInstance();

      for (final batchDoc in eligibleBatchDocs) {
        final batchId = batchDoc.id;
        final promoKey = 'shown_promo_batch_$batchId';
        final hasBeenShown = prefs.getBool(promoKey) ?? false;
        if (hasBeenShown) continue;

        // Fetch parent course to verify visibility and get course details
        final courseRef = batchDoc.reference.parent.parent;
        if (courseRef == null) continue;

        final courseSnap = await courseRef.get();
        if (!courseSnap.exists) continue;

        final courseData = courseSnap.data();
        if (courseData == null || courseData['visibility'] != 'published') continue;

        // Parse Course
        List<Color> gradientColors;
        if (courseData['gradientColors'] != null) {
          gradientColors = (courseData['gradientColors'] as List<dynamic>)
              .map((c) => Color(c as int))
              .toList();
        } else {
          gradientColors = [Colors.blue, Colors.blueAccent];
        }

        final course = Course(
          id: courseSnap.id,
          title: courseData['title'] ?? '',
          subtitle: courseData['subtitle'] ?? '',
          description: courseData['description'] ?? '',
          emoji: courseData['emoji'] ?? '📚',
          gradientColors: gradientColors,
          thumbnailUrl: courseData['thumbnailUrl'] ?? '',
          priceDefault: (courseData['priceDefault'] as num?)?.toDouble() ?? 0.0,
          batches: [], // Scoped promotion does not require sibling batches
        );

        // Parse Batch
        final b = batchDoc.data();
        final batch = Batch(
          id: batchId,
          name: b['name'] ?? 'Default Batch',
          startDate: (b['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          realPrice: (b['realPrice'] as num?)?.toDouble() ??
              (b['price'] as num?)?.toDouble() ??
              course.priceDefault,
          finalPrice: (b['finalPrice'] as num?)?.toDouble() ??
              (b['price'] as num?)?.toDouble() ??
              course.priceDefault,
          seatsLeft: b['seatsLeft'] ?? 0,
          duration: _calculateDuration(
            (b['startDate'] as Timestamp?)?.toDate(),
            (b['endDate'] as Timestamp?)?.toDate(),
          ),
          thumbnailUrl: b['thumbnailUrl'] ?? '',
          isEnrolled: false,
          isCourseBatch: b['isCourseBatch'] ?? false,
        );

        return PromoBatchResult(course: course, batch: batch, promoKey: promoKey);
      }

      return null;
    } catch (e, stack) {
      debugPrint('NewBatchPromotionService error: $e\n$stack');
      return null;
    } finally {
      _isChecking = false;
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

  /// Separated Presentation Helper to trigger the premium promotional dialog UI
  Future<void> showPromoDialog(
    BuildContext context,
    PromoBatchResult result,
  ) async {
    final course = result.course;
    final batch = result.batch;
    final promoKey = result.promoKey;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'New Batch Promotion',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
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
                  final navigator = Navigator.of(dialogContext);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(promoKey, true);
                  if (navigator.mounted) {
                    await navigator.maybePop();
                  }
                },
                onExplore: () async {
                  final navigator = Navigator.of(dialogContext);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(promoKey, true);
                  if (navigator.mounted) {
                    await navigator.maybePop();
                    if (navigator.mounted) {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (context) => CourseDetailPage(course: course),
                        ),
                      );
                    }
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

class _PromoDialogContent extends StatefulWidget {
  final Course course;
  final Batch batch;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onExplore;

  const _PromoDialogContent({
    required this.course,
    required this.batch,
    required this.onDismiss,
    required this.onExplore,
  });

  @override
  State<_PromoDialogContent> createState() => _PromoDialogContentState();
}

class _PromoDialogContentState extends State<_PromoDialogContent> {
  bool _isDismissing = false;
  bool _isExploring = false;
  bool get _isProcessing => _isDismissing || _isExploring;

  Future<void> _handleAction(Future<void> Function() action, {required bool isExplore}) async {
    if (_isProcessing) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      if (isExplore) {
        _isExploring = true;
      } else {
        _isDismissing = true;
      }
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDismissing = false;
          _isExploring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.course.gradientColors.isNotEmpty
        ? widget.course.gradientColors.first
        : Colors.indigo;

    return PopScope(
      canPop: !_isProcessing,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium Header with Course Gradient and Emoji
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.course.gradientColors.isNotEmpty
                    ? widget.course.gradientColors
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                  widget.course.emoji,
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 12),
                // Course Title
                Text(
                  widget.course.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.course.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.course.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
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
                        widget.batch.name,
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
                _buildHighlightRow(Icons.calendar_today, 'Starts: ${widget.batch.startDate.day}/${widget.batch.startDate.month}/${widget.batch.startDate.year}'),
                const SizedBox(height: 8),
                _buildHighlightRow(Icons.hourglass_bottom, 'Duration: ${widget.batch.duration}'),
                const SizedBox(height: 8),
                _buildHighlightRow(Icons.event_seat, 'Limited Seats Left: ${widget.batch.seatsLeft}'),
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
                        if (widget.batch.realPrice > widget.batch.finalPrice)
                          Text(
                            '₹${widget.batch.realPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          '₹${widget.batch.finalPrice.toStringAsFixed(0)}',
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
                        onPressed: _isProcessing
                            ? null
                            : () => _handleAction(widget.onDismiss, isExplore: false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isDismissing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Dismiss',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleAction(widget.onExplore, isExplore: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isExploring
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Explore Batch'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
