// file: lib/store/screens/course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/widgets/batch_badge.dart';
import 'package:eduverse/study/screens/batch_section_page.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';
import 'package:eduverse/study/models/study_models.dart'; // For StudyCourseModel conversion

class CourseDetailPage extends StatefulWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late List<Batch> _batches;
  bool _isLoadingBatches = false;

  @override
  void initState() {
    super.initState();
    _batches = List.from(widget.course.batches);
    // If no batches were passed, fetch from Firebase
    if (_batches.isEmpty) {
      _fetchBatches();
    }
  }

  Future<void> _fetchBatches() async {
    setState(() => _isLoadingBatches = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .collection('batches')
          .get();

      final fetched = snapshot.docs
          .where((doc) => doc.data()['isActive'] ?? true)
          .map((doc) {
            final b = doc.data();
            return Batch(
              id: doc.id,
              name: b['name'] ?? 'Default Batch',
              startDate:
                  (b['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              price:
                  (b['price'] as num?)?.toDouble() ??
                  widget.course.priceDefault,
              seatsLeft: b['seatsLeft'] ?? 0,
              duration: _calculateDuration(
                (b['startDate'] as Timestamp?)?.toDate(),
                (b['endDate'] as Timestamp?)?.toDate(),
              ),
              thumbnailUrl: b['thumbnailUrl'] ?? '',
            );
          })
          .toList();

      if (mounted) {
        setState(() {
          _batches = fetched;
          _isLoadingBatches = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching batches: $e');
      if (mounted) {
        setState(() => _isLoadingBatches = false);
      }
    }
  }

  String _calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Flexible';
    final days = end.difference(start).inDays;
    if (days >= 365) return '${(days / 365).round()} year(s)';
    if (days >= 30) return '${(days / 30).round()} month(s)';
    return '$days days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.course.title,
                style: const TextStyle(fontSize: 16),
              ),
              background: widget.course.thumbnailUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.course.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildGradientBackground(),
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
                                Colors.black.withValues(alpha: 0.6),
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
                    widget.course.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  if (widget.course.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.course.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Available Batches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingBatches)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_batches.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No batches available yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._batches.map((batch) => _buildBatchCard(context, batch)),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isEnrolled)
                  const BatchBadge(text: 'ENROLLED', color: Colors.green)
                else if (batch.seatsLeft < 10)
                  BatchBadge(
                    text: '${batch.seatsLeft} SEATS LEFT',
                    color: Colors.red,
                  )
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
      id: widget.course.id,
      title: widget.course.title,
      subtitle: widget.course.subtitle,
      emoji: widget.course.emoji,
      gradientColors: widget.course.gradientColors,
      lessonCount: 0, // Mock
      progress: 0.0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BatchSectionPage(course: studyCourse, batchId: batch.id),
      ),
    );
  }

  void _addToCartAndCheckout(BuildContext context, Batch batch) {
    final cartItem = CartItem(
      courseId: widget.course.id,
      batchId: batch.id,
      title: '${widget.course.title} - ${batch.name}',
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
          colors: widget.course.gradientColors.isNotEmpty
              ? widget.course.gradientColors
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
            : Text(widget.course.emoji, style: const TextStyle(fontSize: 64)),
      ),
    );
  }
}
