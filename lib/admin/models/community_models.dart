import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String teacherId;
  final String teacherName;
  final String subjectName;
  final String description;
  final List<String> courseIds;
  final int memberCount;
  final int postCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Community({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.subjectName,
    this.description = '',
    this.courseIds = const [],
    this.memberCount = 0,
    this.postCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Community.fromMap(Map<String, dynamic> data, String id) {
    return Community(
      id: id,
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      subjectName: data['subjectName'] ?? '',
      description: data['description'] ?? '',
      courseIds: List<String>.from(data['courseIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      postCount: data['postCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjectName': subjectName,
      'description': description,
      'courseIds': courseIds,
      'memberCount': memberCount,
      'postCount': postCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Community copyWith({
    String? teacherName,
    String? description,
    List<String>? courseIds,
    int? memberCount,
    int? postCount,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Community(
      id: id,
      teacherId: teacherId,
      teacherName: teacherName ?? this.teacherName,
      subjectName: subjectName,
      description: description ?? this.description,
      courseIds: courseIds ?? this.courseIds,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final String authorRole; // student, teacher, admin
  final String title;
  final String body;
  final String? imageUrl;
  final bool isPinned;
  final bool isAnswered;
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.body,
    this.imageUrl,
    this.isPinned = false,
    this.isAnswered = false,
    this.replyCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> data, String id, String communityId) {
    return CommunityPost(
      id: id,
      communityId: communityId,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? 'student',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      isPinned: data['isPinned'] ?? false,
      isAnswered: data['isAnswered'] ?? false,
      replyCount: data['replyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'title': title,
      'body': body,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isPinned': isPinned,
      'isAnswered': isAnswered,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CommunityPost copyWith({
    String? title,
    String? body,
    String? imageUrl,
    bool? isPinned,
    bool? isAnswered,
    int? replyCount,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id,
      communityId: communityId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      isPinned: isPinned ?? this.isPinned,
      isAnswered: isAnswered ?? this.isAnswered,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CommunityReply {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String body;
  final String? imageUrl;
  final bool isTeacherReply;
  final DateTime createdAt;

  CommunityReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.body,
    this.imageUrl,
    this.isTeacherReply = false,
    required this.createdAt,
  });

  factory CommunityReply.fromMap(Map<String, dynamic> data, String id, String postId) {
    return CommunityReply(
      id: id,
      postId: postId,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? 'student',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      isTeacherReply: data['isTeacherReply'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'body': body,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isTeacherReply': isTeacherReply,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
