// file: lib/store/models/store_models.dart
import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final String thumbnailUrl;
  final double priceDefault;
  final List<Batch> batches;

  Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradientColors,
    this.thumbnailUrl = '',
    required this.priceDefault,
    this.batches = const [],
  });
}

class Batch {
  final String id;
  final String name;
  final DateTime startDate;
  final double price;
  int seatsLeft;
  final String duration;
  final String thumbnailUrl;
  bool isEnrolled;

  Batch({
    required this.id,
    required this.name,
    required this.startDate,
    required this.price,
    required this.seatsLeft,
    required this.duration,
    this.thumbnailUrl = '',
    this.isEnrolled = false,
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
  final String title;
  final double price;
  final int quantity;

  CartItem({
    required this.courseId,
    required this.batchId,
    required this.title,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'batchId': batchId,
        'title': title,
        'price': price,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        courseId: json['courseId'],
        batchId: json['batchId'],
        title: json['title'],
        price: json['price'],
        quantity: json['quantity'],
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
