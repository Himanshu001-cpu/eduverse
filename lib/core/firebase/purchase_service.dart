import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createPurchase({
    required String uid,
    required double amount,
    required String paymentId,
    required List<Map<String, dynamic>> items,
    String method = 'stripe',
    String status = 'completed',
    String? gstNumber,
    String? promoCode,
    double? discountAmount,
  }) async {
    final batch = _firestore.batch();

    // 1. Create Purchase Record (History)
    final purchaseRef = _firestore.collection(FirestorePaths.purchases).doc();
    final purchaseId = purchaseRef.id;

    batch.set(purchaseRef, {
      'purchaseId': purchaseId,
      'userId': uid,
      'amount': amount,
      'paymentId': paymentId,
      'paymentMethod': method,
      'status': status,
      'items': items,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      if (gstNumber != null && gstNumber.isNotEmpty) 'gstNumber': gstNumber,
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      if (discountAmount != null && discountAmount > 0)
        'discountAmount': discountAmount,
    });

    // 2. Create/Update Enrolled Courses (Access Control)
    // This allows manual enrollments to be added here without a purchase record
    final userEnrollmentRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('enrolledCourses');
    final userRef = _firestore.collection('users').doc(uid);

    // Collect test series IDs to grant access
    final List<String> testSeriesIds = [];
    // Collect enrollment IDs for user doc array update (admin panel visibility)
    final List<String> enrollmentIds = [];

    for (var item in items) {
      final courseId = item['courseId'] as String?;
      final batchId = item['batchId'] as String?;
      final testSeriesId = item['testSeriesId'] as String?;

      // Check if this item is a test series purchase
      if (testSeriesId != null && testSeriesId.isNotEmpty) {
        testSeriesIds.add(testSeriesId);
      } else if (batchId == 'test_series' && courseId != null) {
        // Fallback: legacy marker-based detection
        testSeriesIds.add(courseId);
      } else if (courseId != null && batchId != null) {
        // Standard course/batch enrollment
        final enrollmentId = '${courseId}_$batchId';
        final enrollmentDoc = userEnrollmentRef.doc(enrollmentId);

        batch.set(enrollmentDoc, {
          'courseId': courseId,
          'batchId': batchId,
          'enrolledAt': FieldValue.serverTimestamp(),
          'purchaseId': purchaseId, // Link back to purchase for reference
          'status': 'active',
        }, SetOptions(merge: true));

        enrollmentIds.add(enrollmentId);
      }
    }

    // 2b. Update user doc enrolledCourses array (for admin panel visibility)
    if (enrollmentIds.isNotEmpty) {
      batch.set(userRef, {
        'enrolledCourses': FieldValue.arrayUnion(enrollmentIds),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 3. Grant access to purchased Test Series
    if (testSeriesIds.isNotEmpty) {
      batch.update(userRef, {
        'purchasedTestSeries': FieldValue.arrayUnion(testSeriesIds),
      });
    }

    // Commit both operations atomically
    await batch.commit();

    return purchaseId;
  }

  /// Save transaction record to user's transactions subcollection
  Future<void> saveTransaction({
    required String uid,
    required String orderId,
    required String productTitle,
    required double amount,
    required String status, // 'success', 'failed', 'pending'
    required String paymentMethod,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add({
          'orderId': orderId,
          'productTitle': productTitle,
          'amount': amount,
          'status': status,
          'paymentMethod': paymentMethod,
          'date': FieldValue.serverTimestamp(),
        });
  }

  /// Stream transactions for a user (for Profile Transactions page)
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getUserPurchases(String uid) {
    return _firestore
        .collection(FirestorePaths.purchases)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// One-time migration: backfill user doc enrolledCourses array
  /// from existing successful purchases.
  /// Returns a message summarizing what was done.
  Future<String> migrateExistingPurchasesToUserDoc() async {
    final validStatuses = {'success', 'completed', 'paid'};
    int usersUpdated = 0;
    int totalEnrollments = 0;

    try {
      // 1. Get all purchases
      final purchasesSnap =
          await _firestore.collection(FirestorePaths.purchases).get();

      // 2. Group enrollment IDs by userId
      final Map<String, Set<String>> userEnrollments = {};
      final Map<String, Set<String>> userTestSeries = {};

      for (final doc in purchasesSnap.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final status = data['status'] as String?;
        if (userId == null || status == null) continue;
        if (!validStatuses.contains(status) &&
            status != 'manual_enrollment') continue;

        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final courseId = item['courseId'] as String?;
          final batchId = item['batchId'] as String?;
          final testSeriesId = item['testSeriesId'] as String?;

          if (testSeriesId != null && testSeriesId.isNotEmpty) {
            userTestSeries.putIfAbsent(userId, () => {}).add(testSeriesId);
          } else if (batchId == 'test_series' && courseId != null) {
            userTestSeries.putIfAbsent(userId, () => {}).add(courseId);
          } else if (courseId != null && batchId != null) {
            final enrollmentId = '${courseId}_$batchId';
            userEnrollments
                .putIfAbsent(userId, () => {})
                .add(enrollmentId);
          }
        }
      }

      // 3. Update each user doc
      for (final entry in userEnrollments.entries) {
        final userId = entry.key;
        final enrollmentIds = entry.value.toList();
        if (enrollmentIds.isEmpty) continue;

        await _firestore.collection('users').doc(userId).set({
          'enrolledCourses': FieldValue.arrayUnion(enrollmentIds),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Also ensure subcollection docs exist
        for (final enrollmentId in enrollmentIds) {
          final parts = enrollmentId.split('_');
          if (parts.length >= 2) {
            final courseId = parts[0];
            final batchId = parts.sublist(1).join('_');
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('enrolledCourses')
                .doc(enrollmentId)
                .set({
              'courseId': courseId,
              'batchId': batchId,
              'enrolledAt': FieldValue.serverTimestamp(),
              'status': 'active',
              'migratedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }

        usersUpdated++;
        totalEnrollments += enrollmentIds.length;
      }

      // 4. Update test series too
      for (final entry in userTestSeries.entries) {
        final userId = entry.key;
        final tsIds = entry.value.toList();
        if (tsIds.isEmpty) continue;

        await _firestore.collection('users').doc(userId).set({
          'purchasedTestSeries': FieldValue.arrayUnion(tsIds),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return 'Migration complete: $usersUpdated users updated, '
          '$totalEnrollments enrollments synced.';
    } catch (e) {
      return 'Migration failed: $e';
    }
  }
}
