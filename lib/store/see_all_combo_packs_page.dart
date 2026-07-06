import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/services/store_repository.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';

class SeeAllComboPacksPage extends StatelessWidget {
  const SeeAllComboPacksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combo Packs'),
        elevation: 0,
      ),
      body: StreamBuilder<List<CombinationPack>>(
        stream: StoreRepository().getCombinationPacks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final packs = snapshot.data!;
          if (packs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No Combo Packs Available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for curated bundle offers!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
              final discount = pack.realPrice > 0 && pack.realPrice > pack.finalPrice
                  ? '${((pack.realPrice - pack.finalPrice) / pack.realPrice * 100).toStringAsFixed(0)}% OFF'
                  : null;

              return Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => _showComboPackDetails(context, pack),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            gradient: LinearGradient(
                              colors: [Colors.indigo.shade400, Colors.purple.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (pack.thumbnailUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(pack.thumbnailUrl, fit: BoxFit.cover),
                                ),
                              if (discount != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      discount,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              const Center(
                                child: Text('🎁', style: TextStyle(fontSize: 40)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pack.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pack.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${pack.finalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    if (pack.realPrice > pack.finalPrice)
                                      Text(
                                        '₹${pack.realPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: Colors.grey.shade600,
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
        },
      ),
    );
  }

  void _showComboPackDetails(BuildContext context, CombinationPack pack) {
    final courseIds = pack.batches
        .map((b) => b['courseId'] as String)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final tsIds = pack.testSeries
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    Future<Map<String, Map<String, String>>> prefetchTitles() async {
      final Map<String, String> courseTitles = {};
      final Map<String, String> tsTitles = {};
      final futures = <Future>[];

      if (courseIds.isNotEmpty) {
        const chunkSize = 10;
        for (var i = 0; i < courseIds.length; i += chunkSize) {
          final chunk = courseIds.sublist(i, (i + chunkSize).clamp(0, courseIds.length));
          futures.add(EduverseFirebase.firestore
              .collection('courses')
              .where(FieldPath.documentId, whereIn: chunk)
              .get()
              .then((snapshot) {
                for (final doc in snapshot.docs) {
                  courseTitles[doc.id] = doc.data()['title'] ?? 'Course';
                }
              }));
        }
      }

      if (tsIds.isNotEmpty) {
        const chunkSize = 10;
        for (var i = 0; i < tsIds.length; i += chunkSize) {
          final chunk = tsIds.sublist(i, (i + chunkSize).clamp(0, tsIds.length));
          futures.add(EduverseFirebase.firestore
              .collection('test_series')
              .where(FieldPath.documentId, whereIn: chunk)
              .get()
              .then((snapshot) {
                for (final doc in snapshot.docs) {
                  tsTitles[doc.id] = doc.data()['title'] ?? 'Test Series';
                }
              }));
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      return {
        'courses': courseTitles,
        'test_series': tsTitles,
      };
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<Map<String, Map<String, String>>>(
        future: prefetchTitles(),
        builder: (context, prefetchSnapshot) {
          if (prefetchSnapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final data = prefetchSnapshot.data ?? {'courses': {}, 'test_series': {}};
          final courseTitles = data['courses'] ?? {};
          final tsTitles = data['test_series'] ?? {};

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade400, Colors.purple.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: pack.thumbnailUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(pack.thumbnailUrl, fit: BoxFit.cover),
                              )
                            : const Center(
                                child: Text('🎁', style: TextStyle(fontSize: 40)),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.deepPurple.shade200),
                              ),
                              child: Text(
                                'COMBO PACK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pack.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About this Bundle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pack.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'What\'s Included',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (pack.batches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Included Course Batches:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                    ...pack.batches.map((b) {
                      final courseTitle = courseTitles[b['courseId']] ?? 'Course';
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: const Text('📚', style: TextStyle(fontSize: 20)),
                          title: Text(
                            courseTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Batch: ${b['batchId']}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  if (pack.testSeries.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Included Test Series:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    ...pack.testSeries.map((tsId) {
                      final tsTitle = tsTitles[tsId] ?? 'Test Series';
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: const Text('📝', style: TextStyle(fontSize: 20)),
                          title: Text(
                            tsTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Price',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹${pack.finalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                if (pack.realPrice > pack.finalPrice) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${pack.realPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
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
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close bottom sheet
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
                                builder: (context) => PurchaseCartPage(
                                  initialItems: [cartItem],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Buy Bundle Now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
