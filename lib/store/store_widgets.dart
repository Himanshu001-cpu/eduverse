import 'dart:async';
import 'package:flutter/material.dart';
import 'models/store_models.dart';
import 'see_all_courses_page.dart';
import 'store_data.dart';


// ============================================================
// BANNER SLIDER
// ============================================================
class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _currentPage = (_currentPage + 1) % StoreData.banners.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = StoreData.banners;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return BannerCard(banner: banners[index]);
            },
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ============================================================
// BANNER CARD
// ============================================================
class BannerCard extends StatelessWidget {
  final StoreBanner banner;

  const BannerCard({Key? key, required this.banner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: banner.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(banner.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              banner.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              banner.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// COURSE SECTION
// ============================================================
class CourseSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Course> courses;

  const CourseSection({
    Key? key,
    required this.title,
    required this.icon,
    required this.courses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeeAllCoursesPage(
                        title: title,
                        courses: courses,
                      ),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Course list
        SizedBox(
          height: 300,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return CourseCard(course: courses[index]);
            },
          ),
        ),
      ],
    );
  }
}


// ============================================================
// COURSE CARD
// ============================================================
class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thumbnail
              Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: course.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        course.emoji,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                    if (course.tag != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.tag!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        course.batchInfo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              course.metadata,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
