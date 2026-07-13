import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringClassRule {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final List<int> weekdays; // 1 = Monday, 7 = Sunday
  final String startTime; // "HH:MM" (local time or UTC)
  final int durationMinutes;
  final DateTime startDate;
  final DateTime endDate;
  final String subject;
  final String chapter;

  RecurringClassRule({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    required this.weekdays,
    required this.startTime,
    required this.durationMinutes,
    required this.startDate,
    required this.endDate,
    this.subject = '',
    this.chapter = '',
  });

  RecurringClassRule copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? instructorId,
    String? instructorName,
    List<int>? weekdays,
    String? startTime,
    int? durationMinutes,
    DateTime? startDate,
    DateTime? endDate,
    String? subject,
    String? chapter,
  }) {
    return RecurringClassRule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      weekdays: weekdays ?? this.weekdays,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
    );
  }

  factory RecurringClassRule.fromMap(Map<String, dynamic> map, String docId) {
    return RecurringClassRule(
      id: docId,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructorId: map['instructorId'] ?? '',
      instructorName: map['instructorName'] ?? '',
      weekdays: List<int>.from(map['weekdays'] ?? []),
      startTime: map['startTime'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      startDate: (map['startDate'] is Timestamp)
          ? (map['startDate'] as Timestamp).toDate()
          : (map['startDate'] != null ? DateTime.parse(map['startDate'].toString()) : DateTime.now()),
      endDate: (map['endDate'] is Timestamp)
          ? (map['endDate'] as Timestamp).toDate()
          : (map['endDate'] != null ? DateTime.parse(map['endDate'].toString()) : DateTime.now()),
      subject: map['subject'] ?? '',
      chapter: map['chapter'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'weekdays': weekdays,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'subject': subject,
      'chapter': chapter,
    };
  }

  // Support JSON serialize/deserialize
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'weekdays': weekdays,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'subject': subject,
      'chapter': chapter,
    };
  }

  factory RecurringClassRule.fromJson(Map<String, dynamic> json) {
    return RecurringClassRule(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructorId: json['instructorId'] ?? '',
      instructorName: json['instructorName'] ?? '',
      weekdays: List<int>.from(json['weekdays'] ?? []),
      startTime: json['startTime'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      subject: json['subject'] ?? '',
      chapter: json['chapter'] ?? '',
    );
  }
}
