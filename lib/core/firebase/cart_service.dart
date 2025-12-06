import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/firestore_paths.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addToCart(String uid, Map<String, dynamic> item) async {
    // item should contain courseId, batchId, title, price
    final courseId = item['courseId'];
    if (courseId == null) return;
    
    final cartRef = _firestore.collection(FirestorePaths.users).doc(uid).collection('cart').doc(courseId);
    await cartRef.set(item);
  }

  Future<void> removeFromCart(String uid, String courseId) async {
    final cartRef = _firestore.collection(FirestorePaths.users).doc(uid).collection('cart').doc(courseId);
    await cartRef.delete();
  }

  Future<void> clearCart(String uid) async {
    final cartRef = _firestore.collection(FirestorePaths.users).doc(uid).collection('cart');
    final snapshot = await cartRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<Map<String, dynamic>>> getCartItems(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }
}
