import 'package:flutter/material.dart';

class StoreBanner {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;

  StoreBanner({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
  });
}

class Course {
  final String title;
  final String batchInfo;
  final String metadata;
  final String emoji;
  final List<Color> colors;
  final String? tag;

  Course({
    required this.title,
    required this.batchInfo,
    required this.metadata,
    required this.emoji,
    required this.colors,
    this.tag,
  });
}
