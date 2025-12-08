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
  }) async {
    final purchaseRef = _firestore.collection(FirestorePaths.purchases).doc();
    final purchaseId = purchaseRef.id;
    
    await purchaseRef.set({
      'purchaseId': purchaseId,
      'userId': uid,
      'amount': amount,
      'paymentId': paymentId,
      'paymentMethod': method,
      'status': status,
      'items': items,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

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
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserPurchases(String uid) {
    return _firestore
        .collection(FirestorePaths.purchases)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
