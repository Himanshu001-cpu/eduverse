import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComboPackDetailPage extends StatefulWidget {
  final CombinationPack pack;

  const ComboPackDetailPage({super.key, required this.pack});

  @override
  State<ComboPackDetailPage> createState() => _ComboPackDetailPageState();
}

class _ComboPackDetailPageState extends State<ComboPackDetailPage> {
  Map<String, String> _courseTitles = {};
  Map<String, String> _testSeriesTitles = {};
  Map<String, String> _ebookTitles = {};
  bool _isLoadingTitles = true;

  @override
  void initState() {
    super.initState();
    _fetchIncludedTitles();
  }

  Future<void> _fetchIncludedTitles() async {
    final pack = widget.pack;
    final courseIds = pack.courses.where((id) => id.isNotEmpty).toSet().toList();
    final tsIds = pack.testSeries.where((id) => id.isNotEmpty).toSet().toList();
    final ebookIds = pack.ebooks.where((id) => id.isNotEmpty).toSet().toList();

    final Map<String, String> coursesMap = {};
    final Map<String, String> tsMap = {};
    final Map<String, String> ebooksMap = {};
    final List<Future> futures = [];

    if (courseIds.isNotEmpty) {
      const chunkSize = 10;
      for (var i = 0; i < courseIds.length; i += chunkSize) {
        final chunk = courseIds.sublist(i, (i + chunkSize).clamp(0, courseIds.length));
        futures.add(
          EduverseFirebase.firestore
              .collection('courses')
              .where(FieldPath.documentId, whereIn: chunk)
              .get()
              .then((snapshot) {
            for (final doc in snapshot.docs) {
              coursesMap[doc.id] = doc.data()['title'] ?? 'Course';
            }
          }),
        );
      }
    }

    if (tsIds.isNotEmpty) {
      const chunkSize = 10;
      for (var i = 0; i < tsIds.length; i += chunkSize) {
        final chunk = tsIds.sublist(i, (i + chunkSize).clamp(0, tsIds.length));
        futures.add(
          EduverseFirebase.firestore
              .collection('test_series')
              .where(FieldPath.documentId, whereIn: chunk)
              .get()
              .then((snapshot) {
            for (final doc in snapshot.docs) {
              tsMap[doc.id] = doc.data()['title'] ?? 'Test Series';
            }
          }),
        );
      }
    }

    if (ebookIds.isNotEmpty) {
      const chunkSize = 10;
      for (var i = 0; i < ebookIds.length; i += chunkSize) {
        final chunk = ebookIds.sublist(i, (i + chunkSize).clamp(0, ebookIds.length));
        futures.add(
          EduverseFirebase.firestore
              .collection('ebooks')
              .where(FieldPath.documentId, whereIn: chunk)
              .get()
              .then((snapshot) {
            for (final doc in snapshot.docs) {
              ebooksMap[doc.id] = doc.data()['title'] ?? 'E-book';
            }
          }),
        );
      }
    }

    if (futures.isNotEmpty) {
      try {
        await Future.wait(futures);
      } catch (e) {
        debugPrint('Error fetching combo titles: $e');
      }
    }

    if (mounted) {
      setState(() {
        _courseTitles = coursesMap;
        _testSeriesTitles = tsMap;
        _ebookTitles = ebooksMap;
        _isLoadingTitles = false;
      });
    }
  }

  void _buyNow(BuildContext context) {
    final pack = widget.pack;
    final cartItem = CartItem(
      courseId: '',
      batchId: '',
      combinationPackId: pack.id,
      title: pack.title,
      price: pack.finalPrice,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseCartPage(initialItems: [cartItem]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final discountPercent = pack.realPrice > 0 && pack.realPrice > pack.finalPrice
        ? ((pack.realPrice - pack.finalPrice) / pack.realPrice * 100).toStringAsFixed(0)
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                pack.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: pack.thumbnailUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          pack.thumbnailUrl,
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
                  // COMBO PACK Tag Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Text(
                      'COMBO PACK BUNDLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                            Icons.school_outlined,
                            'Included Courses',
                            '${pack.courses.length} Course${pack.courses.length == 1 ? '' : 's'}',
                          ),
                          if (pack.testSeries.isNotEmpty) ...[
                            const Divider(height: 20),
                            _buildDetailRow(
                              context,
                              Icons.quiz_outlined,
                              'Included Test Series',
                              '${pack.testSeries.length} Series',
                            ),
                          ],
                          if (pack.ebooks.isNotEmpty) ...[
                            const Divider(height: 20),
                            _buildDetailRow(
                              context,
                              Icons.menu_book_outlined,
                              'Included E-books',
                              '${pack.ebooks.length} E-book${pack.ebooks.length == 1 ? '' : 's'}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Description
                  if (pack.description.isNotEmpty) ...[
                    const Text(
                      'About This Bundle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pack.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // What's Included
                  const Text(
                    "What's Included",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingTitles)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    // Included Courses
                    if (pack.courses.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Included Courses (${pack.courses.length}):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                      ...pack.courses.map((courseId) {
                        final title = _courseTitles[courseId] ?? 'Course';
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Included Test Series
                    if (pack.testSeries.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Included Test Series (${pack.testSeries.length}):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                      ...pack.testSeries.map((tsId) {
                        final title = _testSeriesTitles[tsId] ?? 'Test Series';
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Included E-books
                    if (pack.ebooks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Included E-books (${pack.ebooks.length}):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ),
                      ...pack.ebooks.map((ebookId) {
                        final title = _ebookTitles[ebookId] ?? 'E-book';
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // Price Summary & Buy Button
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
                                      '₹${pack.finalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    if (pack.realPrice > pack.finalPrice) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${pack.realPrice.toStringAsFixed(0)}',
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
                          child: ElevatedButton.icon(
                            onPressed: () => _buyNow(context),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Buy Bundle Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
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
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.deepPurple),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBackground({bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.purple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: showLoader
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              )
            : const Text('🎁', style: TextStyle(fontSize: 64)),
      ),
    );
  }
}
