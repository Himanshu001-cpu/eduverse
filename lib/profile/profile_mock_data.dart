import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';

// Models are kept for type definitions - data comes from Firestore
// See the corresponding screen implementations for how data is fetched.

class LiveClass {
  final String id;
  final String title;
  final DateTime dateTime;
  final Duration duration;
  final String instructor;
  final Color color;
  final String? courseId;

  const LiveClass({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.duration,
    required this.instructor,
    required this.color,
    this.courseId,
  });
}

enum DownloadStatus { completed, downloading, failed, queued }

class DownloadItem {
  final String id;
  final String title;
  final String type; // video, article, pdf
  final String size;
  final double progress; // 0.0 to 1.0
  final DownloadStatus status;
  final String? filePath; // Local file path
  final String? url; // Source URL

  const DownloadItem({
    required this.id,
    required this.title,
    required this.type,
    required this.size,
    this.progress = 0.0,
    this.status = DownloadStatus.queued,
    this.filePath,
    this.url,
  });
}

enum TransactionStatus { success, failed, pending }

class Transaction {
  final String id;
  final String orderId;
  final String productTitle;
  final double amount;
  final DateTime date;
  final TransactionStatus status;

  const Transaction({
    required this.id,
    required this.orderId,
    required this.productTitle,
    required this.amount,
    required this.date,
    required this.status,
  });
}

enum BookmarkType { course, article, video }

class BookmarkItem {
  final String id;
  final String title;
  final BookmarkType type;
  final DateTime dateAdded;
  final Course? courseData; // If type is course

  const BookmarkItem({
    required this.id,
    required this.title,
    required this.type,
    required this.dateAdded,
    this.courseData,
  });
}

enum NotificationType { promo, reminder, system, courseUpdate }

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

// Data is now managed via Firestore - empty lists for compatibility
class ProfileMockData {
  // Shared state for notifications
  static final ValueNotifier<int> unreadNotificationCount = ValueNotifier(0);

  // All data comes from Firestore now
  static final List<LiveClass> liveClasses = [];
  static final List<DownloadItem> downloads = [];
  static final List<Transaction> transactions = [];
  static final List<BookmarkItem> bookmarks = [];
  static final List<NotificationItem> notifications = [];
}
