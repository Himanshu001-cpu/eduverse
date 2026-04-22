import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/store/services/test_series_repository.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';

/// Store tab content showing published test series for purchase.
/// Groups test series by Exam Name (title).
class StoreTestSeriesContent extends StatelessWidget {
  const StoreTestSeriesContent({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TestSeriesRepository();

    return StreamBuilder<List<TestSeriesItem>>(
      stream: repo.getPublishedTestSeries(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSeries = snapshot.data!;
        if (allSeries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No test series available yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new test series!',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Group by Exam Name (title)
        final Map<String, List<TestSeriesItem>> grouped = {};
        for (final ts in allSeries) {
          final key = ts.title.isEmpty ? 'Other' : ts.title;
          grouped.putIfAbsent(key, () => []).add(ts);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              ...grouped.entries.map(
                (entry) =>
                    _buildExamSection(context, entry.key, entry.value),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamSection(
    BuildContext context,
    String examName,
    List<TestSeriesItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            examName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _TestSeriesCard(
                item: items[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _TestSeriesDetailPage(testSeries: items[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TestSeriesCard extends StatelessWidget {
  final TestSeriesItem item;
  final VoidCallback onTap;

  const _TestSeriesCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          item.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallback(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildFallback(showLoader: true);
                          },
                        )
                      : _buildFallback(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${item.totalTests} tests • ${item.price > 0 ? '₹${item.price.toInt()}' : 'FREE'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback({bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            )
          : Text(
              item.emoji,
              style: const TextStyle(fontSize: 40),
            ),
    );
  }
}

/// Category display config.
const Map<String, (String, IconData)> _categoryConfig = {
  'Full Length': ('🏆 Full Length Tests', Icons.emoji_events),
  'Topic Wise': ('📚 Topic Wise Tests', Icons.menu_book),
  'Sectional': ('🧩 Sectional Tests', Icons.extension),
};

/// Detail page for a test series (store view).
/// Groups tests by category (Full Length / Topic Wise / Sectional).
class _TestSeriesDetailPage extends StatelessWidget {
  final TestSeriesItem testSeries;

  const _TestSeriesDetailPage({required this.testSeries});

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
                testSeries.title,
                style: const TextStyle(fontSize: 16),
              ),
              background: testSeries.thumbnailUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          testSeries.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: testSeries.gradientColors,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                testSeries.emoji,
                                style: const TextStyle(fontSize: 64),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: testSeries.gradientColors,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          testSeries.emoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.quiz, '${testSeries.totalTests} Tests'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (testSeries.description.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      testSeries.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tests Preview – grouped by category
                  const Text(
                    'Included Tests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('test_series')
                        .doc(testSeries.id)
                        .collection('tests')
                        .orderBy('order')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final tests = snapshot.data!.docs;
                      if (tests.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tests will be available soon.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Group tests by category
                      final Map<String, List<(int, Map<String, dynamic>)>>
                          grouped = {};
                      for (var i = 0; i < tests.length; i++) {
                        final data =
                            tests[i].data() as Map<String, dynamic>;
                        final cat = (data['category'] as String?)
                                    ?.isNotEmpty ==
                                true
                            ? data['category'] as String
                            : 'General';
                        grouped.putIfAbsent(cat, () => []).add((i, data));
                      }

                      // Order: Full Length, Topic Wise, Sectional, then others
                      final orderedKeys = <String>[
                        if (grouped.containsKey('Full Length')) 'Full Length',
                        if (grouped.containsKey('Topic Wise')) 'Topic Wise',
                        if (grouped.containsKey('Sectional')) 'Sectional',
                        ...grouped.keys.where((k) =>
                            k != 'Full Length' &&
                            k != 'Topic Wise' &&
                            k != 'Sectional'),
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: orderedKeys.map((category) {
                          final items = grouped[category]!;
                          final config = _categoryConfig[category];
                          final label =
                              config?.$1 ?? '📋 $category';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...items.map((entry) {
                                final (idx, data) = entry;
                                final subject =
                                    data['subject'] as String? ?? '';
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: testSeries
                                        .gradientColors.first
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        color:
                                            testSeries.gradientColors.first,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                      data['title'] ?? 'Test ${idx + 1}'),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        '${data['totalQuestions'] ?? 0} questions',
                                      ),
                                      if (subject.isNotEmpty) ...[
                                        const Text(' • '),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                                .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            subject,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Price and CTA
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Price',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                testSeries.price > 0
                                    ? '₹${testSeries.price.toInt()}'
                                    : 'FREE',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () {
                              _addToCart(context);
                            },
                            icon: Icon(
                              testSeries.price > 0
                                  ? Icons.shopping_cart
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              testSeries.price > 0
                                  ? 'Add to Cart'
                                  : 'Start Now',
                            ),
                          ),
                        ],
                      ),
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

  void _addToCart(BuildContext context) {
    if (testSeries.price <= 0) {
      // Free test series — directly add to purchased
      _purchaseFree(context);
      return;
    }

    // Add to cart using courseId field for test series ID
    final cartItem = CartItem(
      courseId: testSeries.id,
      batchId: 'test_series', // marker to distinguish from course purchases
      testSeriesId: testSeries.id,
      title: testSeries.title,
      price: testSeries.price,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseCartPage(initialItems: [cartItem]),
      ),
    );
  }

  Future<void> _purchaseFree(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'purchasedTestSeries': FieldValue.arrayUnion([testSeries.id]),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test series added to your study section!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
