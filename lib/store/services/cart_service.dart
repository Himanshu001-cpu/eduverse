import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import '../models/store_models.dart';

/// Service for managing user's shopping cart in Firestore.
/// Uses per-user subcollection: /users/{uid}/cart/{itemId}
class CartService {
  final FirebaseFirestore? _customDb;
  FirebaseFirestore get _db => _customDb ?? EduverseFirebase.firestore;

  CartService({FirebaseFirestore? firestore}) : _customDb = firestore;

  /// Get cart collection reference for a user
  CollectionReference<Map<String, dynamic>> _cartRef(String uid) =>
      _db.collection('users').doc(uid).collection('cart');

  String getCartDocId(CartItem item) {
    if (item.combinationPackId != null && item.combinationPackId!.isNotEmpty) {
      return 'combo_${item.combinationPackId}';
    }
    if (item.ebookId != null && item.ebookId!.isNotEmpty) {
      return 'ebook_${item.ebookId}';
    }
    return '${item.courseId}_${item.batchId}';
  }

  /// Watch cart items as a stream (real-time updates)
  Stream<List<CartItem>> watchCart(String uid) {
    return _cartRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CartItem.fromJson(doc.data());
      }).toList();
    });
  }

  /// Get cart items once (not real-time)
  Future<List<CartItem>> getCart(String uid) async {
    try {
      final snapshot = await _cartRef(uid).get();
      return snapshot.docs.map((doc) {
        return CartItem.fromJson(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Failed to get cart: $e');
      return [];
    }
  }

  /// Add item to cart (or update quantity if exists)
  Future<void> addToCart(String uid, CartItem item) async {
    try {
      final docId = getCartDocId(item);
      
      await _cartRef(uid).doc(docId).set({
        'courseId': item.courseId,
        'batchId': item.batchId,
        'combinationPackId': item.combinationPackId,
        'testSeriesId': item.testSeriesId,
        'ebookId': item.ebookId,
        'title': item.title,
        'price': item.price,
        'quantity': item.quantity,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('Added to cart: ${item.title}');
    } catch (e) {
      debugPrint('Failed to add to cart: $e');
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String uid, String courseId, String batchId, {String? combinationPackId, String? ebookId}) async {
    try {
      final docId = combinationPackId != null && combinationPackId.isNotEmpty
          ? 'combo_$combinationPackId'
          : (ebookId != null && ebookId.isNotEmpty
              ? 'ebook_$ebookId'
              : '${courseId}_$batchId');
      await _cartRef(uid).doc(docId).delete();
      debugPrint('Removed from cart: $docId');
    } catch (e) {
      debugPrint('Failed to remove from cart: $e');
      rethrow;
    }
  }

  /// Update item quantity in cart
  Future<void> updateQuantity(String uid, String courseId, String batchId, int quantity, {String? combinationPackId, String? ebookId}) async {
    try {
      final docId = combinationPackId != null && combinationPackId.isNotEmpty
          ? 'combo_$combinationPackId'
          : (ebookId != null && ebookId.isNotEmpty
              ? 'ebook_$ebookId'
              : '${courseId}_$batchId');
      if (quantity <= 0) {
        await _cartRef(uid).doc(docId).delete();
      } else {
        await _cartRef(uid).doc(docId).update({'quantity': quantity});
      }
    } catch (e) {
      debugPrint('Failed to update quantity: $e');
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart(String uid) async {
    try {
      final batch = _db.batch();
      final docs = await _cartRef(uid).get();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Cart cleared');
    } catch (e) {
      debugPrint('Failed to clear cart: $e');
      rethrow;
    }
  }

  /// Check if item is in cart
  Future<bool> isInCart(String uid, String courseId, String batchId, {String? combinationPackId, String? ebookId}) async {
    try {
      final docId = combinationPackId != null && combinationPackId.isNotEmpty
          ? 'combo_$combinationPackId'
          : (ebookId != null && ebookId.isNotEmpty
              ? 'ebook_$ebookId'
              : '${courseId}_$batchId');
      final doc = await _cartRef(uid).doc(docId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Failed to check cart: $e');
      return false;
    }
  }

  /// Get cart total
  Future<double> getCartTotal(String uid) async {
    final items = await getCart(uid);
    double total = 0.0;
    for (var item in items) {
      total += item.price * item.quantity;
    }
    return total;
  }
}
