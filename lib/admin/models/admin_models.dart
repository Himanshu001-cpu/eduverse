import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/feed/models/feed_models.dart';

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
          .map(
            (c) =>
                int.tryParse(c.toString().replaceFirst('#', '0xFF')) ??
                0xFF2196F3,
          )
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
      'gradientColors':
          gradientColors, // Store as int array for store compatibility
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
  final String thumbnailUrl;

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
    this.thumbnailUrl = '',
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
      thumbnailUrl: data['thumbnailUrl'] ?? '',
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
      'thumbnailUrl': thumbnailUrl,
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
  final String subject;
  final String chapter;
  final int? lectureNo;
  final List<String> linkedNoteIds;

  AdminLecture({
    required this.id,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.type,
    required this.storagePath,
    required this.isLocked,
    this.subject = '',
    this.chapter = '',
    this.lectureNo,
    this.linkedNoteIds = const [],
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
      subject: data['subject'] ?? '',
      chapter: data['chapter'] ?? '',
      lectureNo: data['lectureNo'] as int?,
      linkedNoteIds: List<String>.from(data['linkedNoteIds'] ?? []),
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
      'subject': subject,
      'chapter': chapter,
      'lectureNo': lectureNo,
      'linkedNoteIds': linkedNoteIds,
    };
  }
}

class AdminUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String role; // student, admin
  final bool disabled;
  final List<String> enrolledCourses;
  final List<String> purchasedTestSeries;
  final List<String> cart;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.disabled,
    this.enrolledCourses = const [],
    this.purchasedTestSeries = const [],
    this.cart = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AdminUser.fromMap(Map<String, dynamic> data, String uid) {
    return AdminUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'student',
      disabled: data['disabled'] ?? false,
      enrolledCourses: List<String>.from(data['enrolledCourses'] ?? []),
      purchasedTestSeries: List<String>.from(data['purchasedTestSeries'] ?? []),
      cart: List<String>.from(data['cart'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'disabled': disabled,
      'enrolledCourses': enrolledCourses,
      'purchasedTestSeries': purchasedTestSeries,
      'cart': cart,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AdminUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? disabled,
    List<String>? enrolledCourses,
    List<String>? purchasedTestSeries,
    List<String>? cart,
  }) {
    return AdminUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      disabled: disabled ?? this.disabled,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      purchasedTestSeries: purchasedTestSeries ?? this.purchasedTestSeries,
      cart: cart ?? this.cart,
      createdAt: createdAt,
      updatedAt: updatedAt,
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

class AdminNote {
  final String id;
  final String title;
  final String subtitle;
  final String pdfUrl;
  final DateTime createdAt;
  final String subject;
  final String chapter;
  final String? lectureId; // Optional link to a specific lecture

  AdminNote({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.pdfUrl,
    required this.createdAt,
    this.subject = '',
    this.chapter = '',
    this.lectureId,
  });

  factory AdminNote.fromMap(Map<String, dynamic> data, String id) {
    return AdminNote(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      pdfUrl: data['pdfUrl'] ?? data['url'] ?? '', // Fallback to old url
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subject: data['subject'] ?? '',
      chapter: data['chapter'] ?? '',
      lectureId: data['lectureId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'subject': subject,
      'chapter': chapter,
      'lectureId': lectureId,
    };
  }
}

class AdminDpp {
  final String id;
  final String title;
  final String subject;
  final String chapter;
  final String dppPdfUrl;
  final String solutionPdfUrl;
  final String? lectureId;
  final DateTime createdAt;

  AdminDpp({
    required this.id,
    required this.title,
    required this.subject,
    required this.chapter,
    required this.dppPdfUrl,
    this.solutionPdfUrl = '',
    this.lectureId,
    required this.createdAt,
  });

  factory AdminDpp.fromMap(Map<String, dynamic> data, String id) {
    return AdminDpp(
      id: id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      chapter: data['chapter'] ?? '',
      dppPdfUrl: data['dppPdfUrl'] ?? '',
      solutionPdfUrl: data['solutionPdfUrl'] ?? '',
      lectureId: data['lectureId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'chapter': chapter,
      'dppPdfUrl': dppPdfUrl,
      'solutionPdfUrl': solutionPdfUrl,
      'lectureId': lectureId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AdminPlannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String pdfUrl;
  final DateTime date;

  AdminPlannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.pdfUrl,
    required this.date,
  });

  factory AdminPlannerItem.fromMap(Map<String, dynamic> data, String id) {
    return AdminPlannerItem(
      id: id,
      title: data['title'] ?? data['topic'] ?? '',
      subtitle: data['subtitle'] ?? data['subject'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'pdfUrl': pdfUrl,
      'date': Timestamp.fromDate(date),
    };
  }
}

class AdminQuiz {
  final String id;
  final String title;
  final String description;
  final String instructions;
  final int? timeLimitMinutes;
  final int? timeLimitSeconds; // New: stores time in seconds for precision
  final double? marksPerQuestion;
  final double? negativeMarking;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime? scheduledAt; // Optional: if set, students can't attempt before this time

  AdminQuiz({
    required this.id,
    required this.title,
    required this.description,
    this.instructions = '',
    this.timeLimitMinutes,
    this.timeLimitSeconds,
    this.marksPerQuestion,
    this.negativeMarking,
    required this.questions,
    required this.createdAt,
    this.scheduledAt,
  });

  factory AdminQuiz.fromMap(Map<String, dynamic> data, String id) {
    return AdminQuiz(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      instructions: data['instructions'] ?? '',
      timeLimitMinutes: data['timeLimitMinutes'] as int?,
      timeLimitSeconds: data['timeLimitSeconds'] as int?,
      marksPerQuestion: (data['marksPerQuestion'] as num?)?.toDouble(),
      negativeMarking: (data['negativeMarking'] as num?)?.toDouble(),
      questions:
          (data['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'instructions': instructions,
      'timeLimitMinutes': timeLimitMinutes,
      'timeLimitSeconds': timeLimitSeconds,
      'marksPerQuestion': marksPerQuestion,
      'negativeMarking': negativeMarking,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
    };
  }
}

class AdminLiveClass {
  final String id;
  final String title;
  final String description;
  final String instructorName;
  final DateTime startTime;
  final int durationMinutes;
  final String youtubeUrl;
  final String thumbnailUrl;
  final String status; // scheduled, live, completed
  final DateTime createdAt;
  final String subject;
  final String chapter;
  final int? lectureNo;
  /// Tracks which batches this class is linked to.
  /// Each entry: { 'courseId': '...', 'batchId': '...' }
  final List<Map<String, String>> linkedBatches;

  AdminLiveClass({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    required this.startTime,
    required this.durationMinutes,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.status,
    required this.createdAt,
    this.subject = '',
    this.chapter = '',
    this.lectureNo,
    this.linkedBatches = const [],
  });

  factory AdminLiveClass.fromMap(Map<String, dynamic> data, String id) {
    return AdminLiveClass(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      instructorName: data['instructorName'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 60,
      youtubeUrl:
          data['youtubeUrl'] ?? data['meetingUrl'] ?? '', // Fallback for legacy
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      status: data['status'] ?? 'scheduled',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subject: data['subject'] ?? '',
      chapter: data['chapter'] ?? '',
      lectureNo: data['lectureNo'] as int?,
      linkedBatches: (data['linkedBatches'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'instructorName': instructorName,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': durationMinutes,
      'youtubeUrl': youtubeUrl,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'subject': subject,
      'chapter': chapter,
      'lectureNo': lectureNo,
      'linkedBatches': linkedBatches,
    };
  }
}
