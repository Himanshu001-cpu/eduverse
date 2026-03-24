import 'package:flutter/material.dart';

/// Student-side model for a Test Series item.
/// Used in both the Store (for browsing/purchasing) and Study (for enrolled series).
class TestSeriesItem {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String category;
  final String thumbnailUrl;
  final List<Color> gradientColors;
  final String emoji;
  final double price;
  final int totalTests;
  final int completedTests;
  final double progress; // 0.0 to 1.0
  final bool isPurchased;

  const TestSeriesItem({
    required this.id,
    required this.title,
    required this.description,
    this.subject = '',
    this.category = 'General',
    this.thumbnailUrl = '',
    required this.gradientColors,
    this.emoji = '📝',
    this.price = 0.0,
    this.totalTests = 0,
    this.completedTests = 0,
    this.progress = 0.0,
    this.isPurchased = false,
  });

  TestSeriesItem copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? category,
    String? thumbnailUrl,
    List<Color>? gradientColors,
    String? emoji,
    double? price,
    int? totalTests,
    int? completedTests,
    double? progress,
    bool? isPurchased,
  }) {
    return TestSeriesItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gradientColors: gradientColors ?? this.gradientColors,
      emoji: emoji ?? this.emoji,
      price: price ?? this.price,
      totalTests: totalTests ?? this.totalTests,
      completedTests: completedTests ?? this.completedTests,
      progress: progress ?? this.progress,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
