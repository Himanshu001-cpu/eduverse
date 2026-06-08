import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';

class PurchaseService {
  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  PurchaseService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

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
    debugPrint('=== PurchaseService.createPurchase START ===');
    debugPrint('uid: $uid, amount: $amount, paymentId: $paymentId');
    debugPrint('items count: ${items.length}');
    for (var i = 0; i < items.length; i++) {
      debugPrint('  item[$i]: ${items[i]}');
    }

    final purchaseId = _firestore.collection(FirestorePaths.purchases).doc().id;

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. READ PHASE: Fetch all unique combination packs first
        final Map<String, Map<String, dynamic>> comboPacksData = {};
        for (var item in items) {
          final combinationPackId = item['combinationPackId'] as String?;
          if (combinationPackId != null && combinationPackId.isNotEmpty) {
            if (!comboPacksData.containsKey(combinationPackId)) {
              final docRef = _firestore.collection('combination_packs').doc(combinationPackId);
              final snap = await transaction.get(docRef);
              if (snap.exists && snap.data() != null) {
                comboPacksData[combinationPackId] = Map<String, dynamic>.from(snap.data()!);
              }
            }
          }
        }

        // 2. WRITE PHASE: Perform writes atomically
        final List<Map<String, dynamic>> finalItemsToWrite = [];
        
        final userEnrollmentRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('enrolledCourses');
        final userRef = _firestore.collection('users').doc(uid);

        final List<String> testSeriesIds = [];
        final List<String> enrollmentIds = [];
        final List<String> ebookIds = [];

        for (var item in items) {
          final courseId = item['courseId'] as String?;
          final batchId = item['batchId'] as String?;
          final testSeriesId = item['testSeriesId'] as String?;
          final combinationPackId = item['combinationPackId'] as String?;
          final ebookId = item['ebookId'] as String?;

          finalItemsToWrite.add(item); // Write the original item

          // A. Process Combination Pack
          if (combinationPackId != null && combinationPackId.isNotEmpty) {
            debugPrint('  -> Processing combination pack: $combinationPackId');
            final comboData = comboPacksData[combinationPackId];
            if (comboData != null) {
              // Expand bundled course batches
              final List<dynamic> bundledBatches = comboData['batches'] ?? [];
              for (var b in bundledBatches) {
                final bMap = Map<String, dynamic>.from(b as Map);
                final cId = bMap['courseId'] as String?;
                final bId = bMap['batchId'] as String?;
                if (cId != null && bId != null) {
                  final enrollmentId = '${cId}_$bId';
                  final enrollmentDoc = userEnrollmentRef.doc(enrollmentId);

                  debugPrint('     -> Bundle Course enrollment: $enrollmentId');

                  transaction.set(enrollmentDoc, {
                    'courseId': cId,
                    'batchId': bId,
                    'enrolledAt': FieldValue.serverTimestamp(),
                    'purchaseId': purchaseId,
                    'status': 'active',
                    'combinationPackId': combinationPackId, // Trace link
                  }, SetOptions(merge: true));

                  enrollmentIds.add(enrollmentId);
                  
                  // Append expanded batch to finalItemsToWrite for trigger decrementing
                  finalItemsToWrite.add({
                    'courseId': cId,
                    'batchId': bId,
                    'title': bMap['batchName'] ?? 'Bundled Course Batch',
                    'price': 0.0,
                    'combinationPackId': combinationPackId,
                  });
                }
              }

              // Expand bundled test series
              final List<dynamic> bundledTestSeries = comboData['testSeries'] ?? [];
              for (var ts in bundledTestSeries) {
                if (ts is String && ts.isNotEmpty) {
                  debugPrint('     -> Bundle Test series: $ts');
                  testSeriesIds.add(ts);
                  
                  // Append expanded test series to finalItemsToWrite
                  finalItemsToWrite.add({
                    'testSeriesId': ts,
                    'title': 'Bundled Test Series',
                    'price': 0.0,
                    'combinationPackId': combinationPackId,
                  });
                }
              }
            }
          }
          // B. Process Test Series Item
          else if (testSeriesId != null && testSeriesId.isNotEmpty) {
            debugPrint('  -> Test series item detected: $testSeriesId');
            testSeriesIds.add(testSeriesId);
          }
          // C. Process Legacy Test Series Item
          else if (batchId == 'test_series' && courseId != null) {
            debugPrint('  -> Legacy test series item detected: $courseId');
            testSeriesIds.add(courseId);
          }
          // D. Process E-book Item
          else if (ebookId != null && ebookId.isNotEmpty) {
            debugPrint('  -> E-book item detected: $ebookId');
            final ebookDoc = _firestore
                .collection('users')
                .doc(uid)
                .collection('purchasedEbooks')
                .doc(ebookId);

            transaction.set(ebookDoc, {
              'ebookId': ebookId,
              'purchasedAt': FieldValue.serverTimestamp(),
              'purchaseId': purchaseId,
              'status': 'active',
            }, SetOptions(merge: true));

            ebookIds.add(ebookId);
          }
          // E. Process Standard Course Batch Enrollment
          else if (courseId != null && batchId != null && courseId != 'combination_pack') {
            final enrollmentId = '${courseId}_$batchId';
            final enrollmentDoc = userEnrollmentRef.doc(enrollmentId);

            debugPrint('  -> Course enrollment: $enrollmentId');

            transaction.set(enrollmentDoc, {
              'courseId': courseId,
              'batchId': batchId,
              'enrolledAt': FieldValue.serverTimestamp(),
              'purchaseId': purchaseId,
              'status': 'active',
            }, SetOptions(merge: true));

            enrollmentIds.add(enrollmentId);
          } else {
            debugPrint('  -> SKIPPED: invalid course, batch, test series, combination pack or e-book configuration');
          }
        }

        // Set purchase record
        final purchaseRef = _firestore.collection(FirestorePaths.purchases).doc(purchaseId);
        transaction.set(purchaseRef, {
          'purchaseId': purchaseId,
          'userId': uid,
          'amount': amount,
          'paymentId': paymentId,
          'paymentMethod': method,
          'status': status,
          'items': finalItemsToWrite,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          if (gstNumber != null && gstNumber.isNotEmpty) 'gstNumber': gstNumber,
          if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
          if (discountAmount != null && discountAmount > 0)
            'discountAmount': discountAmount,
        });

        // 2c. Update user document with enrolled courses, test series and e-books arrays
        if (enrollmentIds.isNotEmpty || testSeriesIds.isNotEmpty || ebookIds.isNotEmpty) {
          final Map<String, dynamic> userUpdate = {
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (enrollmentIds.isNotEmpty) {
            debugPrint('user enrollments update: $enrollmentIds');
            userUpdate['enrolledCourses'] = FieldValue.arrayUnion(enrollmentIds);
          }
          if (testSeriesIds.isNotEmpty) {
            debugPrint('user test series update: $testSeriesIds');
            userUpdate['purchasedTestSeries'] = FieldValue.arrayUnion(testSeriesIds);
          }
          if (ebookIds.isNotEmpty) {
            debugPrint('user e-books update: $ebookIds');
            userUpdate['purchasedEbooks'] = FieldValue.arrayUnion(ebookIds);
          }
          transaction.set(userRef, userUpdate, SetOptions(merge: true));
        }
      });
      debugPrint('=== PurchaseService.createPurchase SUCCESS (purchaseId: $purchaseId) ===');
    } catch (e) {
      debugPrint('=== PurchaseService.createPurchase FAILED: $e ===');
      rethrow;
    }

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

      // 1a. Get all combination packs for bundle resolution during backfill
      final comboSnap = await _firestore.collection('combination_packs').get();
      final Map<String, Map<String, dynamic>> combinationPacks = {};
      for (final doc in comboSnap.docs) {
        combinationPacks[doc.id] = doc.data();
      }

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
          final combinationPackId = item['combinationPackId'] as String?;

          if (combinationPackId != null && combinationPackId.isNotEmpty) {
            final comboData = combinationPacks[combinationPackId];
            if (comboData != null) {
              // Process bundled course batches
              final bundledBatches = comboData['batches'] as List<dynamic>? ?? [];
              for (var b in bundledBatches) {
                final bMap = Map<String, dynamic>.from(b as Map);
                final cId = bMap['courseId'] as String?;
                final bId = bMap['batchId'] as String?;
                if (cId != null && bId != null) {
                  final enrollmentId = '${cId}_$bId';
                  userEnrollments
                      .putIfAbsent(userId, () => {})
                      .add(enrollmentId);
                }
              }

              // Process bundled test series
              final bundledTestSeries = comboData['testSeries'] as List<dynamic>? ?? [];
              for (var ts in bundledTestSeries) {
                if (ts is String && ts.isNotEmpty) {
                  userTestSeries.putIfAbsent(userId, () => {}).add(ts);
                }
              }
            }
          } else if (testSeriesId != null && testSeriesId.isNotEmpty) {
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
