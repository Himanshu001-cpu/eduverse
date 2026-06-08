import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String emoji;
  final List<Color> gradientColors;
  final String thumbnailUrl;
  final double priceDefault;
  final double realPrice;
  final double finalPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final int seatsTotal;
  final int seatsLeft;
  final String duration;
  final bool isActive;
  bool isEnrolled;

  Course({
    required this.id,
    required this.title,
    required this.subtitle,
    this.description = '',
    required this.emoji,
    required this.gradientColors,
    this.thumbnailUrl = '',
    required this.priceDefault,
    this.realPrice = 0.0,
    this.finalPrice = 0.0,
    this.startDate,
    this.endDate,
    this.seatsTotal = 0,
    this.seatsLeft = 0,
    this.duration = '',
    this.isActive = true,
    this.isEnrolled = false,
  });

  /// Backward-compatible virtual batch representation for the course.
  /// Maps Course properties into a single virtual Batch.
  List<Batch> get batches => [
        Batch(
          id: '',
          name: 'Course Content',
          startDate: startDate ?? DateTime.now(),
          realPrice: realPrice,
          finalPrice: finalPrice,
          seatsLeft: seatsLeft,
          duration: duration,
          thumbnailUrl: thumbnailUrl,
          isEnrolled: isEnrolled,
          isCourseBatch: true,
        ),
      ];
}

class Batch {
  final String id;
  final String name;
  final DateTime startDate;
  final double realPrice;
  final double finalPrice;
  int seatsLeft;
  final String duration;
  final String thumbnailUrl;
  bool isEnrolled;
  final bool isCourseBatch;

  Batch({
    required this.id,
    required this.name,
    required this.startDate,
    required this.realPrice,
    required this.finalPrice,
    required this.seatsLeft,
    required this.duration,
    this.thumbnailUrl = '',
    this.isEnrolled = false,
    this.isCourseBatch = false,
  });
}

class BannerModel {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;

  BannerModel({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
  });
}

class CartItem {
  final String courseId;
  final String batchId;
  final String? testSeriesId;
  final String? combinationPackId;
  final String? ebookId;
  final String title;
  final double price;
  final int quantity;

  CartItem({
    required this.courseId,
    required this.batchId,
    this.testSeriesId,
    this.combinationPackId,
    this.ebookId,
    required this.title,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'batchId': batchId,
        if (testSeriesId != null) 'testSeriesId': testSeriesId,
        if (combinationPackId != null) 'combinationPackId': combinationPackId,
        if (ebookId != null) 'ebookId': ebookId,
        'title': title,
        'price': price,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        courseId: json['courseId'] ?? '',
        batchId: json['batchId'] ?? '',
        testSeriesId: json['testSeriesId'] as String?,
        combinationPackId: json['combinationPackId'] as String?,
        ebookId: json['ebookId'] as String?,
        title: json['title'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: json['quantity'] ?? 1,
      );
}

class Purchase {
  final String userId;
  final String id;
  final DateTime timestamp;
  final List<CartItem> items;
  final double amount;
  final String paymentMethod;
  final String status;

  Purchase({
    required this.userId,
    required this.id,
    required this.timestamp,
    required this.items,
    required this.amount,
    required this.paymentMethod,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': status,
      };

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        userId: json['userId'] ?? '',
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: json['paymentMethod'],
        status: json['status'],
      );
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class CombinationPack {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final double realPrice;
  final double finalPrice;
  final List<String> courses; // list of course IDs
  final List<String> testSeries; // list of test series IDs
  final bool isActive;

  CombinationPack({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.realPrice,
    required this.finalPrice,
    required this.courses,
    required this.testSeries,
    required this.isActive,
  });

  /// Virtual batches representation mapping courses to legacy maps.
  List<Map<String, String>> get batches =>
      courses.map((cId) => {'courseId': cId, 'batchId': ''}).toList();

  factory CombinationPack.fromMap(Map<String, dynamic> data, String id) {
    final List<String> parsedCourses = [];
    if (data['courses'] != null) {
      parsedCourses.addAll(List<String>.from(data['courses']));
    } else if (data['batches'] != null) {
      final legacyList = data['batches'] as List<dynamic>;
      for (final b in legacyList) {
        if (b is Map && b['courseId'] != null) {
          parsedCourses.add(b['courseId'].toString());
        }
      }
    }

    return CombinationPack(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      realPrice: (data['realPrice'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 0.0,
      courses: parsedCourses,
      testSeries: List<String>.from(data['testSeries'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }
}

class Ebook {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String thumbnailUrl;
  final String pdfUrl;
  final double realPrice;
  final double finalPrice;
  final bool isActive;
  bool isOwned;

  Ebook({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.thumbnailUrl = '',
    required this.pdfUrl,
    required this.realPrice,
    required this.finalPrice,
    this.isActive = true,
    this.isOwned = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'pdfUrl': pdfUrl,
        'realPrice': realPrice,
        'finalPrice': finalPrice,
        'isActive': isActive,
      };

  factory Ebook.fromMap(Map<String, dynamic> data, String id, {bool isOwned = false}) {
    return Ebook(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      realPrice: (data['realPrice'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] ?? true,
      isOwned: isOwned,
    );
  }
}
