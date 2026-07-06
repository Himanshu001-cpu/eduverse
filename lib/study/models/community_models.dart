import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCommunity {
  final String id;
  final String teacherName;
  final String subjectName;
  final String description;
  final int postCount;
  final List<String> courseIds;

  StudentCommunity({
    required this.id,
    required this.teacherName,
    required this.subjectName,
    required this.description,
    required this.postCount,
    required this.courseIds,
  });

  factory StudentCommunity.fromMap(Map<String, dynamic> data, String id) {
    return StudentCommunity(
      id: id,
      teacherName: data['teacherName'] ?? '',
      subjectName: data['subjectName'] ?? '',
      description: data['description'] ?? '',
      postCount: data['postCount'] ?? 0,
      courseIds: List<String>.from(data['courseIds'] ?? []),
    );
  }
}

class StudentPost {
  final String id;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final String authorRole; // student, teacher, admin
  final bool isAnswered;
  final bool isPinned;
  final int replyCount;
  final DateTime createdAt;

  StudentPost({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.isAnswered,
    required this.isPinned,
    required this.replyCount,
    required this.createdAt,
  });

  factory StudentPost.fromMap(Map<String, dynamic> data, String id) {
    return StudentPost(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? 'student',
      isAnswered: data['isAnswered'] ?? false,
      isPinned: data['isPinned'] ?? false,
      replyCount: data['replyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'isAnswered': isAnswered,
      'isPinned': isPinned,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(createdAt),
    };
  }
}

class StudentReply {
  final String id;
  final String body;
  final String authorId;
  final String authorName;
  final String authorRole;
  final bool isTeacherReply;
  final DateTime createdAt;

  StudentReply({
    required this.id,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.isTeacherReply,
    required this.createdAt,
  });

  factory StudentReply.fromMap(Map<String, dynamic> data, String id) {
    return StudentReply(
      id: id,
      body: data['body'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? 'student',
      isTeacherReply: data['isTeacherReply'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'body': body,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'isTeacherReply': isTeacherReply,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
