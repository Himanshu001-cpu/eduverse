import 'package:flutter/material.dart';

class StudyCourse {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final String thumbnailUrl;
  final int totalLectures;
  final int completedLectures;
  final double progress; // 0.0 to 1.0

  const StudyCourse({
    required this.id,
    required this.title,
    required this.subtitle,
    this.emoji = '📚',
    required this.gradientColors,
    this.thumbnailUrl = '',
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
    String? thumbnailUrl,
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
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalLectures: totalLectures ?? this.totalLectures,
      completedLectures: completedLectures ?? this.completedLectures,
      progress: progress ?? this.progress,
    );
  }
}

/// Represents an enrolled batch in the Study section.
/// This is the primary entity users interact with after purchasing.
class StudyBatch {
  final String id;
  final String courseId;
  final String name;
  final String courseName; // Parent course title for context
  final String emoji;
  final List<Color> gradientColors;
  final String thumbnailUrl;
  final DateTime startDate;
  final int totalLectures;
  final int completedLectures;
  final double progress; // 0.0 to 1.0

  const StudyBatch({
    required this.id,
    required this.courseId,
    required this.name,
    required this.courseName,
    this.emoji = '📚',
    required this.gradientColors,
    this.thumbnailUrl = '',
    required this.startDate,
    this.totalLectures = 0,
    this.completedLectures = 0,
    this.progress = 0.0,
  });

  StudyBatch copyWith({
    String? id,
    String? courseId,
    String? name,
    String? courseName,
    String? emoji,
    List<Color>? gradientColors,
    String? thumbnailUrl,
    DateTime? startDate,
    int? totalLectures,
    int? completedLectures,
    double? progress,
  }) {
    return StudyBatch(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      courseName: courseName ?? this.courseName,
      emoji: emoji ?? this.emoji,
      gradientColors: gradientColors ?? this.gradientColors,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      startDate: startDate ?? this.startDate,
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

class StudyQuiz {
  final String id;
  final String title;
  final String description;
  final int questionCount;
  final int durationMinutes;

  const StudyQuiz({
    required this.id,
    required this.title,
    required this.description,
    this.questionCount = 0,
    this.durationMinutes = 0,
  });
}

class StudyNote {
  final String id;
  final String title;
  final String? fileUrl;
  final DateTime createdAt;

  const StudyNote({
    required this.id,
    required this.title,
    this.fileUrl,
    required this.createdAt,
  });
}

class StudyPlannerItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? fileUrl;

  const StudyPlannerItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.fileUrl,
  });
}

class StudyLiveClass {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final int durationMinutes;
  final String status; // 'upcoming', 'live', 'completed'
  final String? youtubeUrl;
  final String thumbnailUrl;

  const StudyLiveClass({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    this.durationMinutes = 60,
    this.status = 'upcoming',
    this.youtubeUrl,
    this.thumbnailUrl = '',
  });

  bool get isUpcoming => status == 'upcoming' && startTime.isAfter(DateTime.now());
  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
}
