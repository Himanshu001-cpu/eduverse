import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCourse {
  final String id;
  final String title;
  final String slug;
  final String subtitle;
  final String description;
  final String emoji; // For course card display
  final List<String> tags;
  final String language;
  final String level;
  final String thumbnailUrl;
  final List<int> gradientColors; // Store as int ARGB values for compatibility
  final double priceDefault; // Base price for the course
  final String visibility; // draft, published, archived
  final DateTime createdAt;

  AdminCourse({
    required this.id,
    required this.title,
    required this.slug,
    required this.subtitle,
    required this.description,
    this.emoji = '📚',
    required this.tags,
    required this.language,
    required this.level,
    required this.thumbnailUrl,
    required this.gradientColors,
    this.priceDefault = 0.0,
    required this.visibility,
    required this.createdAt,
  });

  factory AdminCourse.fromMap(Map<String, dynamic> data, String id) {
    // Handle both old format (coverGradient as strings) and new format (gradientColors as ints)
    List<int> colors = [];
    if (data['gradientColors'] != null) {
      colors = List<int>.from(data['gradientColors']);
    } else if (data['coverGradient'] != null) {
      // Legacy format conversion (hex strings to int)
      colors = (data['coverGradient'] as List)
          .map((c) => int.tryParse(c.toString().replaceFirst('#', '0xFF')) ?? 0xFF2196F3)
          .toList();
    }
    if (colors.isEmpty) {
      colors = [0xFF2196F3, 0xFF1976D2]; // Default blue gradient
    }

    return AdminCourse(
      id: id,
      title: data['title'] ?? '',
      slug: data['slug'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '📚',
      tags: List<String>.from(data['tags'] ?? []),
      language: data['language'] ?? 'en',
      level: data['level'] ?? 'beginner',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      gradientColors: colors,
      priceDefault: (data['priceDefault'] as num?)?.toDouble() ?? 0.0,
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
      'emoji': emoji,
      'tags': tags,
      'language': language,
      'level': level,
      'thumbnailUrl': thumbnailUrl,
      'gradientColors': gradientColors, // Store as int array for store compatibility
      'priceDefault': priceDefault,
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
      isActive: data['isActive'] ?? true,
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
