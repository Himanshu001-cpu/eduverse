import 'package:flutter/material.dart';

class StudyCourse {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final int totalLectures;
  final int completedLectures;
  final double progress; // 0.0 to 1.0

  const StudyCourse({
    required this.id,
    required this.title,
    required this.subtitle,
    this.emoji = '📚',
    required this.gradientColors,
    this.totalLectures = 0,
    this.completedLectures = 0,
    this.progress = 0.0,
  });

  StudyCourse copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? emoji,
    List<Color>? gradientColors,
    int? totalLectures,
    int? completedLectures,
    double? progress,
  }) {
    return StudyCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      emoji: emoji ?? this.emoji,
      gradientColors: gradientColors ?? this.gradientColors,
      totalLectures: totalLectures ?? this.totalLectures,
      completedLectures: completedLectures ?? this.completedLectures,
      progress: progress ?? this.progress,
    );
  }
}

class StudyLecture {
  final String id;
  final String title;
  final String videoUrl;
  final String contentUrl; // For PDFs/Notes
  final String description;
  final int order;
  final bool isWatched;
  final Duration? duration;

  const StudyLecture({
    required this.id,
    required this.title,
    this.videoUrl = '',
    this.contentUrl = '',
    this.description = '',
    required this.order,
    this.isWatched = false,
    this.duration,
  });

  StudyLecture copyWith({
    String? id,
    String? title,
    String? videoUrl,
    String? contentUrl,
    String? description,
    int? order,
    bool? isWatched,
    Duration? duration,
  }) {
    return StudyLecture(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      contentUrl: contentUrl ?? this.contentUrl,
      description: description ?? this.description,
      order: order ?? this.order,
      isWatched: isWatched ?? this.isWatched,
      duration: duration ?? this.duration,
    );
  }
}

class UserStudyOverview {
  final List<StudyCourse> enrolledCourses;
  final StudyCourse? lastStudiedCourse;
  final StudyLecture? lastStudiedLecture;

  const UserStudyOverview({
    this.enrolledCourses = const [],
    this.lastStudiedCourse,
    this.lastStudiedLecture,
  });
}
