import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/store_models.dart';

/// Service for managing user's shopping cart in Firestore.
/// Uses per-user subcollection: /users/{uid}/cart/{itemId}
class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get cart collection reference for a user
  CollectionReference<Map<String, dynamic>> _cartRef(String uid) =>
      _db.collection('users').doc(uid).collection('cart');

  /// Watch cart items as a stream (real-time updates)
  Stream<List<CartItem>> watchCart(String uid) {
    return _cartRef(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          courseId: data['courseId'] ?? '',
          batchId: data['batchId'] ?? '',
          title: data['title'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: data['quantity'] ?? 1,
        );
      }).toList();
    });
  }

  /// Get cart items once (not real-time)
  Future<List<CartItem>> getCart(String uid) async {
    try {
      final snapshot = await _cartRef(uid).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          courseId: data['courseId'] ?? '',
          batchId: data['batchId'] ?? '',
          title: data['title'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: data['quantity'] ?? 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('Failed to get cart: $e');
      return [];
    }
  }

  /// Add item to cart (or update quantity if exists)
  Future<void> addToCart(String uid, CartItem item) async {
    try {
      // Use courseId_batchId as document ID to prevent duplicates
      final docId = '${item.courseId}_${item.batchId}';
      
      await _cartRef(uid).doc(docId).set({
        'courseId': item.courseId,
        'batchId': item.batchId,
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
  Future<void> removeFromCart(String uid, String courseId, String batchId) async {
    try {
      final docId = '${courseId}_$batchId';
      await _cartRef(uid).doc(docId).delete();
      debugPrint('Removed from cart: $docId');
    } catch (e) {
      debugPrint('Failed to remove from cart: $e');
      rethrow;
    }
  }

  /// Update item quantity in cart
  Future<void> updateQuantity(String uid, String courseId, String batchId, int quantity) async {
    try {
      final docId = '${courseId}_$batchId';
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
  Future<bool> isInCart(String uid, String courseId, String batchId) async {
    try {
      final docId = '${courseId}_$batchId';
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
