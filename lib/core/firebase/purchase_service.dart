import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createPurchase({
    required String uid,
    required double amount,
    required String paymentId,
    required List<Map<String, dynamic>> items, // List of CartItems
    String method = 'stripe',
    String status = 'completed',
  }) async {
    final purchaseRef = _firestore.collection(FirestorePaths.purchases).doc();
    final purchaseId = purchaseRef.id;
    
    await purchaseRef.set({
      'purchaseId': purchaseId,
      'userId': uid, // Changed from 'uid' to 'userId' to match typical model usage if needed, but keeping consistency with internal naming is key. 
                     // Wait, StoreModels.Purchase uses 'userId'. I should stick to that for compatibility.
      'amount': amount,
      'paymentId': paymentId,
      'paymentMethod': method,
      'status': status,
      'items': items,
      'timestamp': FieldValue.serverTimestamp(), // StoreModels uses 'timestamp'
      'createdAt': FieldValue.serverTimestamp(), // Keeping both for safety
    });

    return purchaseId;
  }

  Stream<List<Map<String, dynamic>>> getUserPurchases(String uid) {
    return _firestore
        .collection(FirestorePaths.purchases)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
