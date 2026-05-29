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
  final bool isCourseBatch;

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
    this.isCourseBatch = false,
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
    bool? isCourseBatch,
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
      isCourseBatch: isCourseBatch ?? this.isCourseBatch,
    );
  }
}

class StudyLecture {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String contentUrl;
  final String subject;
  final String chapter;
  final int orderIndex;
  final int order;
  final bool isLocked;
  final bool isWatched;
  final String type;
  final Duration? duration;
  final int? lectureNo;
  final List<String> linkedNoteIds;

  const StudyLecture({
    required this.id,
    required this.title,
    this.description = '',
    required this.videoUrl,
    this.contentUrl = '',
    this.subject = '', // made optional
    this.chapter = '', // made optional
    this.orderIndex = 0, // made optional
    this.order = 0,
    this.isLocked = false,
    this.isWatched = false,
    this.type = 'video',
    this.duration,
    this.lectureNo,
    this.linkedNoteIds = const [],
  });

  factory StudyLecture.fromMap(Map<String, dynamic> data, String id) {
    return StudyLecture(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? data['storagePath'] ?? '',
      contentUrl: data['contentUrl'] ?? '',
      subject: data['subject'] ?? '',
      chapter: data['chapter'] ?? '',
      orderIndex: data['orderIndex'] ?? 0,
      order: data['order'] ?? 0,
      isLocked: data['isLocked'] ?? false,
      isWatched: data['isWatched'] ?? false,
      type: data['type'] ?? 'video',
      duration: data['durationSeconds'] != null ? Duration(seconds: (data['durationSeconds'] as num).toInt()) : null,
      lectureNo: data['lectureNo'],
      linkedNoteIds: List<String>.from(data['linkedNoteIds'] ?? []),
    );
  }

  StudyLecture copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? contentUrl,
    String? subject,
    String? chapter,
    int? orderIndex,
    int? order,
    bool? isLocked,
    bool? isWatched,
    String? type,
    Duration? duration,
    int? lectureNo,
    List<String>? linkedNoteIds,
  }) {
    return StudyLecture(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      contentUrl: contentUrl ?? this.contentUrl,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      orderIndex: orderIndex ?? this.orderIndex,
      order: order ?? this.order,
      isLocked: isLocked ?? this.isLocked,
      isWatched: isWatched ?? this.isWatched,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      lectureNo: lectureNo ?? this.lectureNo,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
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
  final DateTime? scheduledAt; // If set, students can't take before this time

  const StudyQuiz({
    required this.id,
    required this.title,
    required this.description,
    this.questionCount = 0,
    this.durationMinutes = 0,
    this.scheduledAt,
  });

  /// Whether this quiz is currently locked (scheduled for the future).
  bool get isScheduledForFuture =>
      scheduledAt != null && scheduledAt!.isAfter(DateTime.now());
}

class StudyNote {
  final String id;
  final String title;
  final String? fileUrl;
  final DateTime createdAt;
  final String subject;
  final String chapter;
  final String? lectureId;

  const StudyNote({
    required this.id,
    required this.title,
    this.fileUrl,
    required this.createdAt,
    this.subject = '',
    this.chapter = '',
    this.lectureId,
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
  final String instructorName;
  final DateTime startTime;
  final int durationMinutes;
  final String status; // 'upcoming', 'live', 'completed'
  final String? youtubeUrl;
  final String thumbnailUrl;
  final String subject;
  final String chapter;

  const StudyLiveClass({
    required this.id,
    required this.title,
    this.description = '',
    this.instructorName = '',
    required this.startTime,
    this.durationMinutes = 60,
    this.status = 'upcoming',
    this.youtubeUrl,
    this.thumbnailUrl = '',
    this.subject = '',
    this.chapter = '',
  });

  bool get isUpcoming => status == 'upcoming' && startTime.isAfter(DateTime.now());
  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
}

class StudyDpp {
  final String id;
  final String title;
  final String subject;
  final String chapter;
  final String dppPdfUrl;
  final String solutionPdfUrl;
  final String? lectureId;
  final DateTime createdAt;

  const StudyDpp({
    required this.id,
    required this.title,
    required this.subject,
    required this.chapter,
    required this.dppPdfUrl,
    this.solutionPdfUrl = '',
    this.lectureId,
    required this.createdAt,
  });
}
