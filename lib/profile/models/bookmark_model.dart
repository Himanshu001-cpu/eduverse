
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookmarkType { course, article, video, batch }

class BookmarkItem {
  final String id;
  final String title;
  final BookmarkType type;
  final DateTime dateAdded;
  final Map<String, dynamic>? metadata; // Flexibile field for extra data (e.g., course details, thumbnails)

  BookmarkItem({
    required this.id,
    required this.title,
    required this.type,
    required this.dateAdded,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.index,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'metadata': metadata,
    };
  }

  factory BookmarkItem.fromMap(Map<String, dynamic> map) {
    return BookmarkItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: BookmarkType.values[map['type'] ?? 0],
      dateAdded: (map['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
