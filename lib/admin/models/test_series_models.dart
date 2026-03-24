import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a link between a test series and a specific course batch.
class LinkedBatch {
  final String courseId;
  final String batchId;
  final String courseName;
  final String batchName;

  LinkedBatch({
    required this.courseId,
    required this.batchId,
    required this.courseName,
    required this.batchName,
  });

  factory LinkedBatch.fromMap(Map<String, dynamic> data) {
    return LinkedBatch(
      courseId: data['courseId'] ?? '',
      batchId: data['batchId'] ?? '',
      courseName: data['courseName'] ?? '',
      batchName: data['batchName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'batchId': batchId,
      'courseName': courseName,
      'batchName': batchName,
    };
  }
}

/// Admin-side model for a Test Series.
/// Stored in Firestore at `test_series/{testSeriesId}`.
class AdminTestSeries {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String category; // Prelims, Mains, Topic-wise
  final String thumbnailUrl;
  final List<int> gradientColors;
  final String emoji;
  final double price;
  final String visibility; // draft, published, archived
  final int totalTests;
  final int durationMinutes;
  final List<LinkedBatch> linkedBatches;
  final DateTime createdAt;

  AdminTestSeries({
    required this.id,
    required this.title,
    required this.description,
    this.subject = '',
    this.category = 'General',
    this.thumbnailUrl = '',
    required this.gradientColors,
    this.emoji = '📝',
    this.price = 0.0,
    required this.visibility,
    this.totalTests = 0,
    this.durationMinutes = 0,
    this.linkedBatches = const [],
    required this.createdAt,
  });

  factory AdminTestSeries.fromMap(Map<String, dynamic> data, String id) {
    List<int> colors = [];
    if (data['gradientColors'] != null) {
      colors = List<int>.from(data['gradientColors']);
    }
    if (colors.isEmpty) {
      colors = [0xFF4CAF50, 0xFF2E7D32]; // Default green gradient
    }

    return AdminTestSeries(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      category: data['category'] ?? 'General',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      gradientColors: colors,
      emoji: data['emoji'] ?? '📝',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      visibility: data['visibility'] ?? 'draft',
      totalTests: data['totalTests'] ?? 0,
      durationMinutes: data['durationMinutes'] ?? 0,
      linkedBatches:
          (data['linkedBatches'] as List<dynamic>?)
              ?.map((b) => LinkedBatch.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'gradientColors': gradientColors,
      'emoji': emoji,
      'price': price,
      'visibility': visibility,
      'totalTests': totalTests,
      'durationMinutes': durationMinutes,
      'linkedBatches': linkedBatches.map((b) => b.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
