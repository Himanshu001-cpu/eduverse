// file: lib/store/store_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/store/widgets/banner_slider.dart';
import 'package:eduverse/store/widgets/course_card.dart';
import 'package:eduverse/store/widgets/combo_pack_card.dart';
import 'package:eduverse/store/see_all_courses_page.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/store/services/store_repository.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/widgets/store_test_series_content.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';
import 'package:eduverse/store/see_all_combo_packs_page.dart';
import 'package:eduverse/store/screens/combo_pack_detail_page.dart';
import 'package:eduverse/store/widgets/store_ebooks_content.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with SingleTickerProviderStateMixin {
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
      appBar: AppBar(
        title: const Text('Store', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseCartPage(),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Courses'),
                Tab(text: 'Test Series'),
                Tab(text: 'E-books'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Courses
          _CoursesContent(tabController: _tabController),
          // Tab 2: Test Series
          const StoreTestSeriesContent(),
          // Tab 3: E-books
          const StoreEbooksContent(),
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

          // Combo Packs Slider
          StreamBuilder<List<CombinationPack>>(
            stream: StoreRepository().getCombinationPacks(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final packs = snapshot.data!;
              final screenWidth = MediaQuery.of(context).size.width;
              // Banner slider width is screenWidth * (screenWidth > 900 ? 0.6 : (screenWidth > 600 ? 0.8 : 0.9))
              // Set combo pack card width to be slightly narrower (~0.74 on mobile), keeping its 16:9 thumbnail just a little shorter than the banner slider
              final double comboCardWidth = screenWidth > 900
                  ? 320.0
                  : (screenWidth > 600 ? 280.0 : (screenWidth * 0.74).clamp(240.0, 320.0));
              final double comboImageHeight = (comboCardWidth - 8.0) * 9 / 16;
              final double comboSliderHeight = comboImageHeight + 96.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    'Super Bundles (Combo Packs)',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SeeAllComboPacksPage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: comboSliderHeight,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: packs.length,
                      itemBuilder: (context, index) {
                        final pack = packs[index];
                        return ComboPackCard(
                          pack: pack,
                          width: comboCardWidth,
                          onTap: () => _showComboPackDetails(context, pack),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
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
            height: 210,
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
            height: 210,
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

void _showComboPackDetails(BuildContext context, CombinationPack pack) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ComboPackDetailPage(pack: pack),
    ),
  );
}
