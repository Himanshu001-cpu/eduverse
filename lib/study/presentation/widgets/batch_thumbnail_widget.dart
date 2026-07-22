import 'package:flutter/material.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';

class BatchThumbnailWidget extends StatelessWidget {
  final StudyBatch batch;
  final double width;
  final double height;
  final double borderRadius;
  final double emojiSize;

  const BatchThumbnailWidget({
    super.key,
    required this.batch,
    this.width = 40,
    this.height = 40,
    this.borderRadius = 10,
    this.emojiSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = batch.thumbnailUrl.trim().isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: batch.gradientColors.isNotEmpty
              ? batch.gradientColors
              : [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: hasThumbnail
            ? Image.network(
                batch.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    batch.emoji,
                    style: TextStyle(fontSize: emojiSize),
                  ),
                ),
              )
            : Center(
                child: Text(
                  batch.emoji,
                  style: TextStyle(fontSize: emojiSize),
                ),
              ),
      ),
    );
  }
}
