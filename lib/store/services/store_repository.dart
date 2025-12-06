import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/store_data.dart';

class StoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('courses');
  CollectionReference<Map<String, dynamic>> get _purchasesRef =>
      _firestore.collection('purchases');

  // --- Courses ---

  /// Get all published courses (filtered for public visibility)
  Stream<List<Course>> getCourses() {
    return _coursesRef
        .where('visibility', isEqualTo: 'published')
        .snapshots()
        .asyncMap((snapshot) async {
      final courses = <Course>[];
      
      for (final doc in snapshot.docs) {
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
        
        // 1. Fetch batches from embedded array (Legacy/Seeded)
        List<Batch> batches = [];
        if (data['batches'] != null && (data['batches'] as List).isNotEmpty) {
          batches.addAll((data['batches'] as List<dynamic>).map((b) {
            return Batch(
              id: b['id'] ?? '',
              name: b['name'] ?? '',
              startDate: b['startDate'] != null 
                  ? DateTime.parse(b['startDate']) 
                  : DateTime.now(),
              price: (b['price'] as num?)?.toDouble() ?? 0.0,
              seatsLeft: b['seatsLeft'] ?? 0,
              duration: b['duration'] ?? '',
              isEnrolled: b['isEnrolled'] ?? false, // Will be updated later
            );
          }));
        }

        // 2. Fetch from subcollection (Admin-created) and merge
        try {
          final batchSnapshot = await _firestore
              .collection('courses')
              .doc(doc.id)
              .collection('batches')
              .get();
          
          for (final batchDoc in batchSnapshot.docs) {
            final b = batchDoc.data();
            
            // Filter out inactive batches (default to true if missing, e.g. legacy data)
            final bool isActive = b['isActive'] ?? true;
            if (!isActive) continue;

            final batchId = batchDoc.id;

            // Check if this batch is already in the list (avoid duplicates if migration happened)
            final existingIndex = batches.indexWhere((element) => element.id == batchId);
            
            final newBatch = Batch(
              id: batchId,
              name: b['name'] ?? 'Default Batch',
              startDate: (b['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              price: (b['price'] as num?)?.toDouble() ?? (data['priceDefault'] as num?)?.toDouble() ?? 0.0,
              seatsLeft: b['seatsLeft'] ?? 0,
              duration: _calculateDuration(
                (b['startDate'] as Timestamp?)?.toDate(),
                (b['endDate'] as Timestamp?)?.toDate(),
              ),
              isEnrolled: false, // Will be updated later
            );

            if (existingIndex != -1) {
              // Update existing
              batches[existingIndex] = newBatch;
            } else {
              // Add new
              batches.add(newBatch);
            }
          }
        } catch (e) {
          debugPrint('Failed to fetch batches for course ${doc.id}: $e');
        }

        // 3. Update Enrollment Status for all batches
        // Optimization: Fetch user purchases once outside the loop if possible, 
        // but here we are inside the course loop. 
        // We'll rely on the UI to check enrollment or do it here if we have userId.
        // The previous code had `isEnrolled` in the model, but it was just reading from JSON or defaulting to false.
        // We really should check against real purchases if we want it to be accurate.
        // However, `getCourses` doesn't take a userId. 
        // The UI (CourseDetailScreen/StorePage) handles "Enroll Now" vs "Go to Course" logic often by checking purchases again or the user passing logic.
        // But let's keep the `isEnrolled` as false by default here, as strictly `getCourses` is public data.
        // The StorePage or DetailPage can update the state.
        
        courses.add(Course(
          id: doc.id,
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          emoji: data['emoji'] ?? '📚', // Default emoji if not set
          gradientColors: gradientColors.length >= 2 
              ? gradientColors 
              : [Colors.blue, Colors.blueAccent],
          priceDefault: (data['priceDefault'] as num?)?.toDouble() ?? 0.0,
          batches: batches,
        ));
      }
      
      return courses;
    });
  }
  
  // Helper to calculate duration string from start and end dates
  String _calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '3 months';
    final days = end.difference(start).inDays;
    if (days > 30) {
      return '${(days / 30).round()} months';
    }
    return '$days days';
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
        if (purchase.status == 'completed' || purchase.status == 'paid') {
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

  /// Check if user is enrolled in a specific course/batch
  Future<bool> isEnrolled(String userId, String courseId, String batchId) async {
    try {
      final purchases = await getPurchases(userId);
      for (final purchase in purchases) {
        if (purchase.status == 'completed' || purchase.status == 'paid') {
          for (final item in purchase.items) {
            if (item.courseId == courseId && item.batchId == batchId) {
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
        .map((snapshot) =>
            snapshot.docs.map((doc) => Purchase.fromJson(doc.data())).toList());
  }

  // --- Seeding ---

  Future<void> seedInitialData() async {
    final snapshot = await _coursesRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Already seeded

    for (final course in StoreData.courses) {
      await _coursesRef.doc(course.id).set({
        'title': course.title,
        'subtitle': course.subtitle,
        'emoji': course.emoji,
        'gradientColors': course.gradientColors.map((c) => c.toARGB32()).toList(),
        'priceDefault': course.priceDefault,
        'visibility': 'published', // Required for public read access
        'batches': course.batches
            .map((b) => {
                  'id': b.id,
                  'name': b.name,
                  'startDate': b.startDate.toIso8601String(),
                  'price': b.price,
                  'seatsLeft': b.seatsLeft,
                  'duration': b.duration,
                  'isEnrolled': b.isEnrolled,
                })
            .toList(),
      });
    }
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
      // Reseed
      await seedInitialData();
      debugPrint('Force reseed completed');
    } catch (e) {
      debugPrint('Force reseed failed: $e');
    }
  }
}

