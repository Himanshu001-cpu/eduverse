import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/screens/generic_feed_detail_router.dart'; // For FeedDetailRouter
import 'package:eduverse/core/firebase/firestore_paths.dart';

class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int _page = 0;
  Timer? _timer;
  List<FeedItem> _feedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFeedItems();
  }

  Future<void> _loadRecentFeedItems() async {
    try {
      // Fetch most recent public feed items from Firestore
      // Try simple query first (without orderBy to avoid index requirement)
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection(FirestorePaths.feed)
            .where('isPublic', isEqualTo: true)
            .limit(5)
            .get();
      } catch (e) {
        // Fallback: fetch without filter if index doesn't exist
        debugPrint('Falling back to unfiltered query: $e');
        snapshot = await FirebaseFirestore.instance
            .collection(FirestorePaths.feed)
            .limit(5)
            .get();
      }

      debugPrint('Feed trending: Found ${snapshot.docs.length} items');

      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FeedItem.fromJson(data);
      }).toList();

      if (mounted) {
        setState(() {
          _feedItems = items;
          _isLoading = false;
        });
        if (_feedItems.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      debugPrint('Error loading recent feed items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_feedItems.isEmpty) return;
      _page = (_page + 1) % _feedItems.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          _page,
          duration: const Duration(milliseconds: 350),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = screenWidth > 600 ? 220.0 : 200.0;

    if (_isLoading) {
      return SizedBox(
        height: bannerHeight + 60,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_feedItems.isEmpty) {
      // Show placeholder instead of hiding completely
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text('🔥 ', style: TextStyle(fontSize: 20)),
                Text('Trending Posts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: Colors.white70),
                  SizedBox(height: 12),
                  Text(
                    'No posts yet',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check back soon for new content!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
          child: Row(
            children: [
              Text('🔥 ', style: TextStyle(fontSize: 20)),
              Text('Trending Posts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: _feedItems.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final item = _feedItems[index];
              return _buildFeedCard(context, item, screenWidth);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _feedItems.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _page == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _page == i
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeedCard(BuildContext context, FeedItem item, double screenWidth) {
    return GestureDetector(
      onTap: () {
        // Navigate to feed detail using router
        FeedDetailRouter.open(context, item);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.3),
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
                          _buildGradientBackground(item, screenWidth),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildGradientBackground(item, screenWidth, showLoader: true);
                      },
                    )
                  : _buildGradientBackground(item, screenWidth),
              // Dark overlay for text readability when using thumbnail
              if (item.thumbnailUrl.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: EdgeInsets.all(screenWidth > 600 ? 24.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.categoryLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 11 : 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 14 : 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Action button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.buttonIcon, color: item.color, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            item.buttonLabel,
                            style: TextStyle(
                              color: item.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground(FeedItem item, double screenWidth, {bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [item.color, item.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background emoji
          Positioned(
            right: -20,
            bottom: -20,
            child: Text(
              item.emoji,
              style: TextStyle(
                fontSize: screenWidth > 600 ? 120 : 100,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          if (showLoader)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}
