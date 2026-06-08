import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreRepository {
  // Singleton pattern
  static final StoreRepository _instance = StoreRepository._internal();
  factory StoreRepository() => _instance;
  StoreRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CombinationPack>>? _comboPacksStream;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('courses');
  CollectionReference<Map<String, dynamic>> get _purchasesRef =>
      _firestore.collection('purchases');

  // --- Courses ---

  /// Get all published courses (filtered for public visibility)
  Stream<List<Course>> getCourses() {
    return _coursesRef.where('visibility', isEqualTo: 'published').snapshots().asyncMap((
      snapshot,
    ) async {
      final user = FirebaseAuth.instance.currentUser;
      final List<String> enrolledCourseIds = [];
      if (user != null) {
        try {
          final enrollsSnapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('enrolledCourses')
              .get();
          for (final doc in enrollsSnapshot.docs) {
            enrolledCourseIds.add(doc.id);
            final data = doc.data();
            final courseId = data['courseId'] as String?;
            if (courseId != null) {
              enrolledCourseIds.add(courseId);
            }
          }
        } catch (e) {
          debugPrint('Failed to fetch user enrollments: $e');
        }
      }

      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();

        // Handle gradient colors - support both formats
        List<Color> gradientColors;
        if (data['gradientColors'] != null) {
          gradientColors = (data['gradientColors'] as List<dynamic>)
              .map((c) => Color(c as int))
              .toList();
        } else {
          gradientColors = [Colors.blue, Colors.blueAccent];
        }

        final isEnrolled = enrolledCourseIds.contains(doc.id) ||
            enrolledCourseIds.any((key) => key.startsWith('${doc.id}_'));

        return Course(
          id: doc.id,
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          description: data['description'] ?? '',
          emoji: data['emoji'] ?? '📚',
          gradientColors: gradientColors.length >= 2
              ? gradientColors
              : [Colors.blue, Colors.blueAccent],
          thumbnailUrl: data['thumbnailUrl'] ?? '',
          priceDefault: (data['priceDefault'] as num?)?.toDouble() ?? 0.0,
          realPrice: (data['realPrice'] as num?)?.toDouble() ??
              (data['price'] as num?)?.toDouble() ??
              (data['priceDefault'] as num?)?.toDouble() ??
              0.0,
          finalPrice: (data['finalPrice'] as num?)?.toDouble() ??
              (data['price'] as num?)?.toDouble() ??
              (data['priceDefault'] as num?)?.toDouble() ??
              0.0,
          startDate: data['startDate'] != null
              ? (data['startDate'] is Timestamp
                  ? (data['startDate'] as Timestamp).toDate()
                  : DateTime.tryParse(data['startDate'].toString()))
              : null,
          endDate: data['endDate'] != null
              ? (data['endDate'] is Timestamp
                  ? (data['endDate'] as Timestamp).toDate()
                  : DateTime.tryParse(data['endDate'].toString()))
              : null,
          seatsTotal: data['seatsTotal'] as int? ?? 0,
          seatsLeft: data['seatsLeft'] as int? ?? 0,
          duration: data['duration'] as String? ?? '',
          isActive: data['isActive'] ?? true,
          isEnrolled: isEnrolled,
        );
      }).toList();

      final results = await Future.wait(futures);
      final courses = results.toList();

      // Filter out enrolled courses from the store page
      return courses.where((course) => !course.isEnrolled).toList();
    });
  }

  // --- Combination Packs ---

  /// Get all active combination packs
  Stream<List<CombinationPack>> getCombinationPacks() {
    _comboPacksStream ??= _firestore
        .collection('combination_packs')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CombinationPack.fromMap(doc.data(), doc.id))
              .toList();
        });
    return _comboPacksStream!;
  }

  // --- E-books ---

  /// Get all active E-books
  Stream<List<Ebook>> getEbooks() {
    return _firestore
        .collection('ebooks')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final user = FirebaseAuth.instance.currentUser;
      final List<String> purchasedEbookIds = [];
      if (user != null) {
        try {
          final purchasesSnapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('purchasedEbooks')
              .get();
          for (final doc in purchasesSnapshot.docs) {
            purchasedEbookIds.add(doc.id);
          }
        } catch (e) {
          debugPrint('Failed to fetch user purchased e-books: $e');
        }
      }

      return snapshot.docs.map((doc) {
        final isOwned = purchasedEbookIds.contains(doc.id);
        return Ebook.fromMap(doc.data(), doc.id, isOwned: isOwned);
      }).toList();
    });
  }

  // --- Purchases ---

  Future<void> createPurchase(Purchase purchase) async {
    await _purchasesRef.doc(purchase.id).set(purchase.toJson());
  }

  Future<List<Purchase>> getPurchases(String userId) async {
    final snapshot = await _purchasesRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => Purchase.fromJson(doc.data())).toList();
  }

  // --- Enrollment Tracking ---

  /// Get list of course IDs the user has purchased
  Future<List<String>> getEnrolledCourseIds(String userId) async {
    try {
      final purchases = await getPurchases(userId);
      final courseIds = <String>{};
      for (final purchase in purchases) {
        if (purchase.status == 'completed' || purchase.status == 'paid' || purchase.status == 'success') {
          for (final item in purchase.items) {
            courseIds.add(item.courseId);
          }
        }
      }
      return courseIds.toList();
    } catch (e) {
      debugPrint('Failed to get enrolled courses: $e');
      return [];
    }
  }

  /// Check if user is enrolled in a specific course
  Future<bool> isEnrolled(
    String userId,
    String courseId, [
    String batchId = '',
  ]) async {
    try {
      // 1. Direct subcollection check (fastest)
      final enrollDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('enrolledCourses')
          .doc(courseId)
          .get();
      if (enrollDoc.exists) return true;

      // 2. Direct check with composite key if migrated
      if (batchId.isNotEmpty) {
        final enrollDocComposite = await _firestore
            .collection('users')
            .doc(userId)
            .collection('enrolledCourses')
            .doc('${courseId}_$batchId')
            .get();
        if (enrollDocComposite.exists) return true;
      }

      // 3. Fallback: Purchase list lookup
      final purchases = await getPurchases(userId);
      for (final purchase in purchases) {
        if (purchase.status == 'completed' || purchase.status == 'paid' || purchase.status == 'success') {
          for (final item in purchase.items) {
            if (item.courseId == courseId) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Failed to check enrollment: $e');
      return false;
    }
  }

  /// Get user's enrollments with course details
  Stream<List<Purchase>> watchUserPurchases(String userId) {
    return _purchasesRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Purchase.fromJson(doc.data()))
              .toList(),
        );
  }

  // Seeding is disabled - data is now managed via Admin Panel
  @Deprecated('Data is now managed via Admin Panel')
  Future<void> seedInitialData() async {
    debugPrint(
      'seedInitialData is deprecated. Use Admin Panel to manage courses.',
    );
  }

  /// Update existing courses to add visibility field (one-time migration)
  Future<void> updateExistingCoursesVisibility() async {
    try {
      final snapshot = await _coursesRef.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['visibility'] == null) {
          await doc.reference.update({'visibility': 'published'});
          debugPrint('Updated visibility for course: ${doc.id}');
        }
      }
      debugPrint('All courses updated with visibility field');
    } catch (e) {
      debugPrint('Failed to update courses visibility: $e');
    }
  }

  /// Force reseed data (deletes existing and recreates)
  Future<void> forceReseedData() async {
    try {
      // Delete existing courses
      final snapshot = await _coursesRef.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint(
        'Data seeding is deprecated. Use Admin Panel to manage courses.',
      );
      debugPrint('Force reseed completed');
    } catch (e) {
      debugPrint('Force reseed failed: $e');
    }
  }
}
