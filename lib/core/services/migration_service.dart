import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  /// One-Time Migration: copies old user transaction records
  /// from users/{uid}/transactions subcollection into the top-level
  /// "purchases" collection so they appear in the Admin Purchases screen.
  static Future<void> migrateTransactions() async {
    final db = FirebaseFirestore.instance;
    int migratedCount = 0;
    int alreadyExistsCount = 0;
    int usersScanned = 0;

    debugPrint('=== Legacy Transaction Migration ===');
    debugPrint('Starting migration...\n');

    try {
      // 1. Get all users
      final usersSnap = await db.collection('users').get();
      debugPrint('Found ${usersSnap.docs.length} users to scan.\n');

      // 2. Build deduplication registry from existing purchases
      final existingPurchasesSnap = await db.collection('purchases').get();
      final Set<String> existingPaymentIds = {};
      final Set<String> existingKeys = {};

      for (final doc in existingPurchasesSnap.docs) {
        final data = doc.data();
        final paymentId =
            data['paymentId'] as String? ?? data['purchaseId'] as String?;
        if (paymentId != null && paymentId.isNotEmpty) {
          existingPaymentIds.add(paymentId);
        }

        final uId = data['userId'] as String?;
        final amt = (data['amount'] as num?)?.toDouble();
        final ts = data['createdAt'] ?? data['timestamp'];
        if (uId != null && amt != null && ts != null) {
          final String tsStr =
              ts is Timestamp ? ts.toDate().toIso8601String() : ts.toString();
          existingKeys.add('${uId}_${amt}_$tsStr');
        }
      }

      debugPrint(
          'Loaded ${existingPurchasesSnap.docs.length} existing purchases for deduplication.\n');

      // 3. Process each user's transactions
      for (final userDoc in usersSnap.docs) {
        final userId = userDoc.id;
        usersScanned++;

        final txsSnap = await db
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        if (txsSnap.docs.isEmpty) continue;

        debugPrint(
            '  User $userId: found ${txsSnap.docs.length} transaction(s)');

        for (final txDoc in txsSnap.docs) {
          final txData = txDoc.data();
          final orderId = txData['orderId'] as String? ?? '';
          final amount = (txData['amount'] as num?)?.toDouble() ?? 0.0;
          final status = txData['status'] as String? ?? 'success';
          final paymentMethod = txData['paymentMethod'] as String? ?? 'unknown';
          final productTitle =
              txData['productTitle'] as String? ?? 'Course Enrollment';
          final date = txData['date'] ?? txData['timestamp'];

          // Check for duplicates
          bool alreadyExists = false;
          if (orderId.isNotEmpty && existingPaymentIds.contains(orderId)) {
            alreadyExists = true;
          } else if (date != null) {
            final String tsStr =
                date is Timestamp ? date.toDate().toIso8601String() : date.toString();
            if (existingKeys.contains('${userId}_${amount}_$tsStr')) {
              alreadyExists = true;
            }
          }

          if (alreadyExists) {
            alreadyExistsCount++;
            continue;
          }

          // Write to global purchases collection
          final purchaseData = {
            'userId': userId,
            'amount': amount,
            'paymentId': orderId.isNotEmpty ? orderId : txDoc.id,
            'paymentMethod': paymentMethod,
            'status': status == 'completed' ? 'success' : status,
            'createdAt': date ?? FieldValue.serverTimestamp(),
            'timestamp': date ?? FieldValue.serverTimestamp(),
            'migratedFromTransactionId': txDoc.id,
            'items': [
              {
                'courseId': 'legacy_migrated',
                'batchId': 'legacy_migrated',
                'title': productTitle,
                'price': amount,
                'quantity': 1,
              }
            ],
          };

          await db.collection('purchases').add(purchaseData);
          migratedCount++;
        }
      }

      debugPrint('\n=== Migration Complete ===');
      debugPrint('Users scanned: $usersScanned');
      debugPrint('Transactions migrated: $migratedCount');
      debugPrint('Duplicates skipped: $alreadyExistsCount');
    } catch (e) {
      debugPrint('\n❌ Migration failed: $e');
    }
  }
}
