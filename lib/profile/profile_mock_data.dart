/*
README - QA CHECKLIST & MOCK DATA

Files Added:
- lib/profile/screens/free_live_classes_page.dart
- lib/profile/screens/my_downloads_page.dart
- lib/profile/screens/transactions_page.dart
- lib/profile/screens/bookmarks_page.dart
- lib/profile/screens/notifications_page.dart
- lib/common/widgets/cards.dart
- lib/profile/widgets/menu_grid.dart (Updated)
- lib/profile/profile_mock_data.dart (Updated)

How to Test:
1. Free Live Classes:
   - Tap "Free Live Classes".
   - Toggle filters (All/Upcoming/Past).
   - Verify "Join" button for classes starting soon.
   - Tap a card to see details bottom sheet.

2. My Downloads:
   - Tap "My Downloads".
   - Verify list shows items with different states (Completed, Downloading, etc.).
   - Swipe left to delete an item (Undo snackbar appears).
   - Restart app to verify persistence (items remain deleted).

3. My Transactions:
   - Tap "My Transactions".
   - Check summary at top.
   - Use date picker to filter.
   - Tap a transaction to see details.

4. Bookmarks:
   - Tap "Bookmarks".
   - Long press an item to enter selection mode.
   - Select multiple and tap delete or export.
   - Verify persistence after restart.

5. Notifications:
   - Observe badge count on Menu Grid.
   - Tap "Notifications".
   - Tap "Mark all read" -> Badge clears.
   - Long press to see options.

Mock Data Included:
- 6 Live Classes (Upcoming & Past)
- 4 Downloads (Video, PDF, Article)
- 4 Transactions (Success, Failed, Pending)
- 3 Bookmarks (Course, Video, Article)
- 12 Notifications (Promo, System, etc.)
*/

import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';

// --- Models ---

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

// --- Mock Data ---

class ProfileMockData {
  // Shared state for notifications
  static final ValueNotifier<int> unreadNotificationCount = ValueNotifier(4);

  static final List<LiveClass> liveClasses = [
    LiveClass(
      id: '1',
      title: 'Advanced Polity Strategy',
      dateTime: DateTime.now().add(const Duration(minutes: 5)), // Upcoming soon
      duration: const Duration(hours: 1),
      instructor: 'Dr. John Doe',
      color: Colors.blueAccent,
    ),
    LiveClass(
      id: '2',
      title: 'Current Affairs Daily',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
      duration: const Duration(minutes: 45),
      instructor: 'Jane Smith',
      color: Colors.orangeAccent,
    ),
    LiveClass(
      id: '3',
      title: 'History Marathon',
      dateTime: DateTime.now().subtract(const Duration(days: 1)), // Past
      duration: const Duration(hours: 2),
      instructor: 'Amit Kumar',
      color: Colors.redAccent,
    ),
    LiveClass(
      id: '4',
      title: 'CSAT Logic Basics',
      dateTime: DateTime.now().subtract(const Duration(days: 2)), // Past
      duration: const Duration(minutes: 90),
      instructor: 'Sarah Lee',
      color: Colors.purpleAccent,
    ),
    LiveClass(
      id: '5',
      title: 'Geography Mapping',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      duration: const Duration(minutes: 60),
      instructor: 'Rahul Verma',
      color: Colors.green,
    ),
    LiveClass(
      id: '6',
      title: 'Ethics Case Studies',
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      duration: const Duration(minutes: 50),
      instructor: 'Priya Singh',
      color: Colors.teal,
    ),
  ];

  static final List<DownloadItem> downloads = [
    const DownloadItem(
      id: '1',
      title: 'Polity Lecture 1',
      type: 'video',
      size: '150 MB',
      status: DownloadStatus.completed,
      progress: 1.0,
    ),
    const DownloadItem(
      id: '2',
      title: 'Economy Notes PDF',
      type: 'pdf',
      size: '2 MB',
      status: DownloadStatus.completed,
      progress: 1.0,
    ),
    const DownloadItem(
      id: '3',
      title: 'Daily News Analysis',
      type: 'article',
      size: '500 KB',
      status: DownloadStatus.downloading,
      progress: 0.45,
    ),
    const DownloadItem(
      id: '4',
      title: 'History Map Work',
      type: 'video',
      size: '200 MB',
      status: DownloadStatus.failed,
      progress: 0.1,
    ),
  ];

  static final List<Transaction> transactions = [
    Transaction(
      id: 't1',
      orderId: 'ORD-2023-001',
      productTitle: 'UPSC Foundation Batch',
      amount: 4999.0,
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: TransactionStatus.success,
    ),
    Transaction(
      id: 't2',
      orderId: 'ORD-2023-002',
      productTitle: 'CSAT Crash Course',
      amount: 999.0,
      date: DateTime.now().subtract(const Duration(days: 12)),
      status: TransactionStatus.success,
    ),
    Transaction(
      id: 't3',
      orderId: 'ORD-2023-003',
      productTitle: 'Test Series 2024',
      amount: 1499.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: TransactionStatus.failed,
    ),
    Transaction(
      id: 't4',
      orderId: 'ORD-2023-004',
      productTitle: 'Monthly Magazine',
      amount: 49.0,
      date: DateTime.now(),
      status: TransactionStatus.pending,
    ),
  ];

  static final List<BookmarkItem> bookmarks = [
    BookmarkItem(
      id: 'b1',
      title: 'UPSC 2025 Complete Course',
      type: BookmarkType.course,
      dateAdded: DateTime.now().subtract(const Duration(days: 2)),
      courseData: Course(
        id: 'upsc-2025',
        title: 'UPSC 2025 Complete Course',
        subtitle: 'Starts June 1 | Hinglish | 12 Months',
        emoji: '📚',
        gradientColors: [Colors.blue, Colors.lightBlueAccent],
        priceDefault: 4999.0,
      ),
    ),
    BookmarkItem(
      id: 'b2',
      title: 'How to read The Hindu',
      type: BookmarkType.video,
      dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    ),
    BookmarkItem(
      id: 'b3',
      title: 'Budget 2024 Highlights',
      type: BookmarkType.article,
      dateAdded: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static final List<NotificationItem> notifications = List.generate(12, (index) {
    return NotificationItem(
      id: 'n$index',
      title: 'Notification Title $index',
      description: 'This is a short description for notification $index.',
      timestamp: DateTime.now().subtract(Duration(hours: index * 2)),
      type: NotificationType.values[index % NotificationType.values.length],
      isRead: index > 3, // First 4 unread
    );
  });
}
