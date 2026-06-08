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

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;
  final SharedPreferences? _prefs;

  NewBatchPromotionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SharedPreferences? prefs,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth,
        _prefs = prefs;

  /// Pure query logic that runs business rules to find the newest eligible promo.
  /// Decoupled from BuildContext, making it fully unit-testable!
  Future<PromoBatchResult?> getEligiblePromotion() async {
    if (_isChecking) return null;
    _isChecking = true;

    try {
      final user = _auth != null ? _auth.currentUser : FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // 1. Get student's enrolled course IDs directly from Firestore for accuracy
      final enrolledCoursesSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('enrolledCourses')
          .get();

      final enrolledCourseIds = enrolledCoursesSnap.docs
          .map((doc) => doc.data()['courseId'] as String? ?? doc.id)
          .whereType<String>()
          .toSet();

      // 2. Fetch active published courses (without orderBy to avoid requiring a composite index)
      final coursesSnap = await _firestore
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .where('visibility', isEqualTo: 'published')
          .get();

      final eligibleCourseDocs = coursesSnap.docs
          .where((doc) => !enrolledCourseIds.contains(doc.id))
          .toList();

      if (eligibleCourseDocs.isEmpty) return null;

      // Sort by startDate descending in memory
      eligibleCourseDocs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        
        final aStart = aData['startDate'] != null
            ? (aData['startDate'] is Timestamp
                ? (aData['startDate'] as Timestamp).toDate()
                : DateTime.tryParse(aData['startDate'].toString()))
            : null;
            
        final bStart = bData['startDate'] != null
            ? (bData['startDate'] is Timestamp
                ? (bData['startDate'] as Timestamp).toDate()
                : DateTime.tryParse(bData['startDate'].toString()))
            : null;

        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return bStart.compareTo(aStart); // descending order
      });

      // 3. Find the first eligible course that has not been dismissed
      final prefs = _prefs ?? await SharedPreferences.getInstance();

      for (final courseDoc in eligibleCourseDocs.take(50)) {
        final courseId = courseDoc.id;
        final promoKey = 'shown_promo_batch_$courseId';
        final hasBeenShown = prefs.getBool(promoKey) ?? false;
        if (hasBeenShown) continue;

        final courseData = courseDoc.data();

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
          id: courseId,
          title: courseData['title'] ?? '',
          subtitle: courseData['subtitle'] ?? '',
          description: courseData['description'] ?? '',
          emoji: courseData['emoji'] ?? '📚',
          gradientColors: gradientColors,
          thumbnailUrl: courseData['thumbnailUrl'] ?? '',
          priceDefault: (courseData['priceDefault'] as num?)?.toDouble() ?? 0.0,
          realPrice: (courseData['realPrice'] as num?)?.toDouble() ?? 0.0,
          finalPrice: (courseData['finalPrice'] as num?)?.toDouble() ?? 0.0,
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
        );

        final batch = course.batches.first;

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
