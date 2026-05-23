// file: lib/store/store_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/store/widgets/banner_slider.dart';
import 'package:eduverse/store/widgets/course_card.dart';
import 'package:eduverse/store/see_all_courses_page.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/store/services/store_repository.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/widgets/store_test_series_content.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';
import '../../common/search/global_search_delegate.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'The Eduverse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: GlobalSearchDelegate());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Courses'),
                Tab(text: 'Test Series'),
                Tab(text: 'Combo Packs'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Courses (existing content)
          _CoursesContent(tabController: _tabController),
          // Tab 2: Test Series
          const StoreTestSeriesContent(),
          // Tab 3: Combo Packs
          const _ComboPacksContent(),
        ],
      ),
    );
  }
}

/// The original store courses content, extracted into its own widget.
class _CoursesContent extends StatelessWidget {
  final TabController tabController;

  const _CoursesContent({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const BannerSlider(),
          const SizedBox(height: 24),

          // Glassmorphic Combo Packs Slider
          StreamBuilder<List<CombinationPack>>(
            stream: StoreRepository().getCombinationPacks(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final packs = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Super Bundles (Combo Packs)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            tabController.animateTo(2);
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: packs.length,
                      itemBuilder: (context, index) {
                        final pack = packs[index];
                        return _GlassmorphicComboPackCard(
                          pack: pack,
                          onTap: () => _showComboPackDetails(context, pack),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // Trending
          _buildSectionHeader(context, 'Trending Now', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const SeeAllCoursesPage(title: 'Trending Now'),
              ),
            );
          }),
          SizedBox(
            height: 180,
            child: StreamBuilder<List<Course>>(
              stream: StoreRepository().getCourses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final courses = snapshot.data!.reversed.toList();
                if (courses.isEmpty) {
                  return const Center(child: Text('No trending courses'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return CourseCard(
                      course: course,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseDetailPage(course: course),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Featured Courses
          _buildSectionHeader(context, 'Featured Courses', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const SeeAllCoursesPage(title: 'Featured Courses'),
              ),
            );
          }),
          SizedBox(
            height: 180,
            child: StreamBuilder<List<Course>>(
              stream: StoreRepository().getCourses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final courses = snapshot.data!;
                if (courses.isEmpty) {
                  StoreRepository().updateExistingCoursesVisibility();
                  return const Center(child: Text('No courses available'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return CourseCard(
                      course: course,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseDetailPage(course: course),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAll,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
        ],
      ),
    );
  }
}

/// The tab content widget displaying all active combo packs in a premium grid.
class _ComboPacksContent extends StatelessWidget {
  const _ComboPacksContent();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CombinationPack>>(
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
    );
  }
}

/// A premium glassmorphic Horizontal card to highlight combo packs in home slider.
class _GlassmorphicComboPackCard extends StatelessWidget {
  final CombinationPack pack;
  final VoidCallback onTap;

  const _GlassmorphicComboPackCard({
    required this.pack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = pack.realPrice > 0 && pack.realPrice > pack.finalPrice
        ? '${((pack.realPrice - pack.finalPrice) / pack.realPrice * 100).toStringAsFixed(0)}% OFF'
        : null;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade900.withValues(alpha: 0.85),
            Colors.purple.shade900.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text('🎁', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'COMBO BUNDLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (discount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            discount,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    pack.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pack.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₹${pack.finalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (pack.realPrice > pack.finalPrice) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '₹${pack.realPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to showcase the detailed Bottom Sheet overlay for a Combo Pack.
void _showComboPackDetails(BuildContext context, CombinationPack pack) {
  // Extract unique course and test series IDs for pre-fetching
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
      // Chunk queries by 10 to protect against firestore whereIn limits
      const chunkSize = 10;
      for (var i = 0; i < courseIds.length; i += chunkSize) {
        final chunk = courseIds.sublist(i, (i + chunkSize).clamp(0, courseIds.length));
        futures.add(FirebaseFirestore.instance
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
        futures.add(FirebaseFirestore.instance
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
                // Header
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
                // Included Courses / Batches
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
                // Included Test Series
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
                // Checkout Section
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
