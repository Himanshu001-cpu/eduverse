import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:eduverse/store/models/poster_model.dart';
import 'package:eduverse/core/services/deep_link_screens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';

class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  List<Poster> _posters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosters();
  }

  Future<void> _loadPosters() async {
    try {
      final snapshot = await EduverseFirebase.firestore
          .collection('posters')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final items = snapshot.docs.map((doc) {
        return Poster.fromMap(doc.data(), doc.id);
      }).toList();

      debugPrint('TrendingSection loaded ${items.length} active posters');

      if (mounted) {
        setState(() {
          _posters = items;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading posters for trending: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleNavigation(
    BuildContext context,
    String? externalUrl,
    String? inAppTargetType,
    String? inAppTargetId,
  ) async {
    if (externalUrl != null && externalUrl.isNotEmpty) {
      final uri = Uri.tryParse(externalUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (inAppTargetType != null && inAppTargetId != null && inAppTargetId.isNotEmpty) {
      Widget? targetScreen;
      switch (inAppTargetType) {
        case 'course':
          targetScreen = DeepLinkCourseScreen(courseId: inAppTargetId);
          break;
        case 'feedItem':
        case 'quiz':
          targetScreen = DeepLinkFeedScreen(feedId: inAppTargetId);
          break;
        case 'batch':
          targetScreen = DeepLinkBatchScreen(courseId: inAppTargetId, batchId: '');
          break;
        case 'lecture':
          targetScreen = DeepLinkBatchScreen(courseId: '', batchId: inAppTargetId);
          break;
      }

      if (targetScreen != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen!),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double viewportFraction = screenWidth > 900 ? 0.6 : (screenWidth > 600 ? 0.8 : 0.9);
    final double cardWidth = screenWidth * viewportFraction;
    final double bannerHeight = cardWidth * 9 / 16; // 16:9 aspect ratio

    if (_isLoading) {
      return SizedBox(
        height: bannerHeight + 60,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_posters.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Trending Posts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          Container(
            height: bannerHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined, size: 48, color: Colors.white70),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage != null ? 'Failed to load posts' : 'No trending posts yet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage ?? 'Check back soon for new updates!',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Trending Posts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        carousel.CarouselSlider(
          options: carousel.CarouselOptions(
            height: bannerHeight,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            viewportFraction: viewportFraction,
          ),
          items: _posters.map((poster) {
            return Builder(
              builder: (BuildContext context) {
                return _buildPosterCard(context, poster, screenWidth);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPosterCard(
    BuildContext context,
    Poster item,
    double screenWidth,
  ) {
    return GestureDetector(
      onTap: () {
        _handleNavigation(
          context,
          item.externalUrl,
          item.inAppTargetType,
          item.inAppTargetId,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: Thumbnail or Gradient
              item.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      item.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallback(item),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildFallback(item, showLoader: true);
                      },
                    )
                  : _buildFallback(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(Poster item, {bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.indigo.shade900],
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
          : const Icon(
              Icons.photo_library,
              size: 48,
              color: Colors.white24,
            ),
    );
  }
}
