import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helper to parse color from int or hex string if needed, 
// but for Firestore we usually store 0xFFRRGGBB int.
int _colorToInt(dynamic color) {
  if (color is int) return color;
  return 0xFF000000;
}

Color _parseColor(dynamic colorData) {
  return Color(_colorToInt(colorData));
}

class ContinueLearningModel {
  final String id; // Added ID for Firestore
  final String title;
  final String emoji;
  final double progress; // 0.0 to 1.0
  final String lastLessonId; // To resume

  const ContinueLearningModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.progress,
    this.lastLessonId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'emoji': emoji,
      'progress': progress,
      'lastLessonId': lastLessonId,
    };
  }

  factory ContinueLearningModel.fromMap(Map<String, dynamic> map, String id) {
    return ContinueLearningModel(
      id: id,
      title: map['title'] ?? '',
      emoji: map['emoji'] ?? '📚',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      lastLessonId: map['lastLessonId'] ?? '',
    );
  }
}

class EnrolledCourseModel {
  final String id;
  final String courseId;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final int lessonCount;
  final double progress;

  const EnrolledCourseModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.subtitle,
    this.emoji = '📚',
    required this.gradientColors,
    this.lessonCount = 0,
    this.progress = 0.0,
  });

  // For migration, we might map from Store Course
  factory EnrolledCourseModel.fromStoreCourse(Map<String, dynamic> courseData, String id, double progress) {
     List<Color> colors = [Colors.blue, Colors.lightBlueAccent];
    if (courseData['gradientColors'] != null) {
      colors = (courseData['gradientColors'] as List).map((c) => Color(c)).toList();
    }
    
    return EnrolledCourseModel(
      id: id,
      courseId: courseData['id'] ?? '',
      title: courseData['title'] ?? '',
      subtitle: courseData['subtitle'] ?? '',
      emoji: courseData['emoji'] ?? '📚',
      gradientColors: colors,
      lessonCount: 0, // TODO: Fetch real count
      progress: progress,
    );
  }
}

// Renamed from CourseModel to avoid conflict with Store, 
// using alias in export if needed or refactoring usage.
class StudyCourseModel {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final int lessonCount;
  final double progress;

  const StudyCourseModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.emoji = '📚',
    required this.gradientColors,
    this.lessonCount = 0,
    this.progress = 0.0,
  });

   Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'emoji': emoji,
      'gradientColors': gradientColors.map((c) => c.value).toList(),
      'lessonCount': lessonCount,
      'progress': progress,
    };
  }

  factory StudyCourseModel.fromMap(Map<String, dynamic> map, String id) {
    List<Color> colors = [Colors.blue, Colors.lightBlueAccent];
    if (map['gradientColors'] != null) {
      colors = (map['gradientColors'] as List).map((c) => Color(c)).toList();
    }
    return StudyCourseModel(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      emoji: map['emoji'] ?? '📚',
      gradientColors: colors,
      lessonCount: map['lessonCount'] ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory StudyCourseModel.fromSnapshot(DocumentSnapshot doc) {
    return StudyCourseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}

class DailyPracticeModel {
  final String id;
  final String title;
  final String description;
  final IconData icon; // Stored as codePoint or usage name in DB? 
                       // For simplicity, we might map strictly in code based on types.
  final int colorValue;

  Color get color => Color(colorValue);

  const DailyPracticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'iconCode': icon.codePoint,
      'iconFamily': icon.fontFamily,
      'colorValue': colorValue,
    };
  }

  factory DailyPracticeModel.fromMap(Map<String, dynamic> map, String id) {
    return DailyPracticeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(
        map['iconCode'] ?? 0xe0b0, // Default to a circle or similar
        fontFamily: map['iconFamily'] ?? 'MaterialIcons',
      ),
      colorValue: map['colorValue'] ?? 0xFF000000,
    );
  }
}

class LiveClassModel {
  final String id;
  final String title;
  final DateTime dateTime;
  final String emoji;
  final String link;

  const LiveClassModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.emoji,
    this.link = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'emoji': emoji,
      'link': link,
    };
  }

  factory LiveClassModel.fromMap(Map<String, dynamic> map, String id) {
    return LiveClassModel(
      id: id,
      title: map['title'] ?? '',
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
      emoji: map['emoji'] ?? '📹',
      link: map['link'] ?? '',
    );
  }
}

class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'answerIndex': answerIndex,
      'explanation': explanation,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      answerIndex: map['answerIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }
}

class TestModel {
  final String id;
  final String title;
  final String duration; // e.g. "2 Hrs"
  final String difficulty;
  final int questionCount;
  final int bestScore;
  final List<QuestionModel> questions; // Usually fetched separately, but good for model

  const TestModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.difficulty,
    this.questionCount = 0,
    this.bestScore = 0,
    this.questions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'duration': duration,
      'difficulty': difficulty,
      'questionCount': questionCount,
      // bestScore specific to user, not global test model usually
    };
  }

  factory TestModel.fromMap(Map<String, dynamic> map, String id) {
    return TestModel(
      id: id,
      title: map['title'] ?? '',
      duration: map['duration'] ?? '',
      difficulty: map['difficulty'] ?? 'Medium',
      questionCount: map['questionCount'] ?? 0,
      bestScore: 0, // Fetched from user results
      questions: [], // Fetched from subcollection
    );
  }
}

class TopicNodeModel {
  final String id;
  final String title;
  final String description;
  final int colorValue;
  
  Color get color => Color(colorValue);

  const TopicNodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'colorValue': colorValue,
    };
  }

  factory TopicNodeModel.fromMap(Map<String, dynamic> map, String id) {
    return TopicNodeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF0000FF,
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
  
  Map<String, dynamic> toMap() => {
    'title': title,
    'isCompleted': isCompleted,
  };

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) => TaskModel(
    id: id,
    title: map['title'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
  );
}

class WorkbookModel {
  final String id;
  final String userId;
  final String title;
  final DateTime dueDate;
  final String status; // Not Started, In Progress, Submitted, Overdue
  final double progress;
  final List<TaskModel> tasks;

  const WorkbookModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.progress,
    this.tasks = const [],
  });
  
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'dueDate': dueDate.toIso8601String(),
    'status': status,
    'progress': progress,
    'tasks': tasks.map((t) => t.toMap()).toList(),
  };

  factory WorkbookModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkbookModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Not Started',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      tasks: (map['tasks'] as List?)?.map((t) => TaskModel.fromMap(t, '')).toList() ?? [],
    );
  }
}
