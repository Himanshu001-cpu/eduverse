import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eduverse/store/models/poster_model.dart';
import 'package:eduverse/core/services/deep_link_screens.dart';

class BannerSlider extends StatelessWidget {
  const BannerSlider({super.key});

  Future<void> _handleNavigation(BuildContext context, String? externalUrl, String? inAppTargetType, String? inAppTargetId) async {
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
    
    // Responsive viewport fraction
    final double viewportFraction = screenWidth > 900 ? 0.6 : (screenWidth > 600 ? 0.8 : 0.9);
    // 16:9 aspect ratio based on visible card width
    final double cardWidth = screenWidth * viewportFraction;
    final double bannerHeight = cardWidth * 9 / 16;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posters')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: bannerHeight,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final posters = docs.map((doc) => Poster.fromMap(doc.data(), doc.id)).toList();

        if (posters.isEmpty) {
          return const SizedBox.shrink();
        }

        return carousel.CarouselSlider(
          options: carousel.CarouselOptions(
            height: bannerHeight,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeCenterPage: true,
            viewportFraction: viewportFraction,
            aspectRatio: 16 / 9,
          ),
          items: posters.map((poster) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    // Only navigate on tap if there are no buttons
                    if (poster.buttons.isEmpty) {
                      _handleNavigation(
                        context,
                        poster.externalUrl,
                        poster.inAppTargetType,
                        poster.inAppTargetId,
                      );
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background: Thumbnail (Aspect Ratio Fitted) or Default Gradient
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: poster.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    poster.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildFallback(poster),
                                  )
                                : _buildFallback(poster),
                          ),
                        ),

                        // Dark overlay for text readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
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
                        ),

                        // Poster Content (Title, Subtitle, Buttons)
                        Padding(
                          padding: EdgeInsets.all(screenWidth > 600 ? 24.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (poster.title.isNotEmpty) ...[
                                Text(
                                  poster.title,
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 24 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                              ],
                              if (poster.subtitle.isNotEmpty) ...[
                                Text(
                                  poster.subtitle,
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 14 : 12,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              // Buttons List
                              if (poster.buttons.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: poster.buttons.map((btn) {
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.blue.shade900,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () {
                                        _handleNavigation(
                                          context,
                                          btn.externalUrl,
                                          btn.inAppTargetType,
                                          btn.inAppTargetId,
                                        );
                                      },
                                      child: Text(
                                        btn.label,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
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
          }).toList(),
        );
      },
    );
  }

  Widget _buildFallback(Poster poster) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.photo_library,
        size: 64,
        color: Colors.white24,
      ),
    );
  }
}
