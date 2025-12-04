import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCourse {
  final String id;
  final String title;
  final String slug;
  final String subtitle;
  final String description;
  final List<String> tags;
  final String language;
  final String level;
  final String thumbnailUrl;
  final List<String> coverGradient;
  final String visibility; // draft, published, archived
  final DateTime createdAt;

  AdminCourse({
    required this.id,
    required this.title,
    required this.slug,
    required this.subtitle,
    required this.description,
    required this.tags,
    required this.language,
    required this.level,
    required this.thumbnailUrl,
    required this.coverGradient,
    required this.visibility,
    required this.createdAt,
  });

  factory AdminCourse.fromMap(Map<String, dynamic> data, String id) {
    return AdminCourse(
      id: id,
      title: data['title'] ?? '',
      slug: data['slug'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      language: data['language'] ?? 'en',
      level: data['level'] ?? 'beginner',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      coverGradient: List<String>.from(data['coverGradient'] ?? []),
      visibility: data['visibility'] ?? 'draft',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'slug': slug,
      'subtitle': subtitle,
      'description': description,
      'tags': tags,
      'language': language,
      'level': level,
      'thumbnailUrl': thumbnailUrl,
      'coverGradient': coverGradient,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class AdminBatch {
  final String id;
  final String courseId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final int seatsTotal;
  final int seatsLeft;
  final bool isActive;

  AdminBatch({
    required this.id,
    required this.courseId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.isActive,
  });

  factory AdminBatch.fromMap(Map<String, dynamic> data, String id) {
    return AdminBatch(
      id: id,
      courseId: data['courseId'] ?? '',
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seatsTotal: data['seatsTotal'] ?? 0,
      seatsLeft: data['seatsLeft'] ?? 0,
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'seatsTotal': seatsTotal,
      'seatsLeft': seatsLeft,
      'isActive': isActive,
    };
  }
}

class AdminLecture {
  final String id;
  final String title;
  final String description;
  final int orderIndex;
  final String type; // video, article, pdf, quiz
  final String storagePath;
  final bool isLocked;

  AdminLecture({
    required this.id,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.type,
    required this.storagePath,
    required this.isLocked,
  });

  factory AdminLecture.fromMap(Map<String, dynamic> data, String id) {
    return AdminLecture(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      orderIndex: data['orderIndex'] ?? 0,
      type: data['type'] ?? 'video',
      storagePath: data['storagePath'] ?? '',
      isLocked: data['isLocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'orderIndex': orderIndex,
      'type': type,
      'storagePath': storagePath,
      'isLocked': isLocked,
    };
  }
}

class AdminUser {
  final String uid;
  final String email;
  final String role;
  final bool disabled;

  AdminUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.disabled,
  });

  factory AdminUser.fromMap(Map<String, dynamic> data, String uid) {
    return AdminUser(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      disabled: data['disabled'] ?? false,
    );
  }
}

class AdminPurchase {
  final String id;
  final String userId;
  final double amount;
  final String status; // success, failed, refunded
  final DateTime createdAt;

  AdminPurchase({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory AdminPurchase.fromMap(Map<String, dynamic> data, String id) {
    return AdminPurchase(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AdminAudit {
  final String id;
  final String action;
  final String adminId;
  final String entityType;
  final String entityId;
  final DateTime timestamp;
  final Map<String, dynamic> diff;

  AdminAudit({
    required this.id,
    required this.action,
    required this.adminId,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    required this.diff,
  });

  factory AdminAudit.fromMap(Map<String, dynamic> data, String id) {
    return AdminAudit(
      id: id,
      action: data['action'] ?? '',
      adminId: data['adminId'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diff: Map<String, dynamic>.from(data['diff'] ?? {}),
    );
  }
}
