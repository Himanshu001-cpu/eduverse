import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';

/// Student-side repository for fetching test series data.
class TestSeriesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('test_series');

  /// Get all published test series (for Store display).
  Stream<List<TestSeriesItem>> getPublishedTestSeries() {
    return _collection
        .where('visibility', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _mapToTestSeriesItem(data, doc.id);
          }).toList(),
        );
  }

  /// Get test series purchased by a specific user.
  /// Checks the user's `purchasedTestSeries` array in their profile.
  Stream<List<TestSeriesItem>> getPurchasedTestSeries(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data() ?? {};
      final purchasedIds = List<String>.from(
        userData['purchasedTestSeries'] ?? [],
      );

      if (purchasedIds.isEmpty) return <TestSeriesItem>[];

      // Fetch each purchased test series
      final List<TestSeriesItem> items = [];
      for (final tsId in purchasedIds) {
        final doc = await _collection.doc(tsId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          items.add(_mapToTestSeriesItem(data, doc.id, isPurchased: true));
        }
      }
      return items;
    });
  }

  /// Get a single test series detail.
  Future<TestSeriesItem?> getTestSeriesDetail(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return _mapToTestSeriesItem(data, doc.id);
  }

  /// Get test series linked to a specific batch (for study section).
  Stream<List<TestSeriesItem>> getTestSeriesForBatch(
    String courseId,
    String batchId,
  ) {
    return _collection
        .where('visibility', isEqualTo: 'published')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _mapToTestSeriesItem(data, doc.id);
              })
              .where((ts) {
                // Filter client-side for batch linking
                return true; // All published for now, filtering done at UI
              })
              .toList(),
        );
  }

  TestSeriesItem _mapToTestSeriesItem(
    Map<String, dynamic> data,
    String id, {
    bool isPurchased = false,
  }) {
    List<Color> colors = [];
    if (data['gradientColors'] != null) {
      colors = (data['gradientColors'] as List)
          .map((c) => Color(c as int))
          .toList();
    }
    if (colors.isEmpty) {
      colors = [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    }

    return TestSeriesItem(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      category: data['category'] ?? 'General',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      gradientColors: colors,
      emoji: data['emoji'] ?? '📝',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      totalTests: data['totalTests'] ?? 0,
      isPurchased: isPurchased,
    );
  }
}
