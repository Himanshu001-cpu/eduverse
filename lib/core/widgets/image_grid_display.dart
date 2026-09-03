import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'full_screen_image_viewer.dart';

class ImageGridDisplay extends StatelessWidget {
  final List<String> imageUrls;
  final double maxHeight;

  const ImageGridDisplay({
    super.key,
    required this.imageUrls,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final urls = imageUrls.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: maxHeight,
          width: double.infinity,
          child: _buildLayout(context, urls),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, List<String> urls) {
    if (urls.length == 1) {
      return _buildImage(context, urls[0], 0);
    } else if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildImage(context, urls[0], 0)),
          const SizedBox(width: 4),
          Expanded(child: _buildImage(context, urls[1], 1)),
        ],
      );
    } else {
      // 3 images: 1 large on left, 2 small stacked on right
      return Row(
        children: [
          Expanded(flex: 3, child: _buildImage(context, urls[0], 0)),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _buildImage(context, urls[1], 1)),
                const SizedBox(height: 4),
                Expanded(child: _buildImage(context, urls[2], 2)),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImage(BuildContext context, String url, int index) {
    return GestureDetector(
      onTap: () => FullScreenImageViewer.open(context, imageUrls, initialIndex: index),
      child: Container(
        color: Colors.black.withValues(alpha: 0.1),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.grey.withValues(alpha: 0.1),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.withValues(alpha: 0.2),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
