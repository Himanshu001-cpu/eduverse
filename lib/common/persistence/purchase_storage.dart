// file: lib/common/persistence/purchase_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eduverse/store/models/store_models.dart';

class PurchaseStorage {
  static const String _keyPurchaseHistory = 'purchase_history_v1';
  static const String _keyCart = 'cart_v1';
  static const String _keyBookmarks = 'bookmarks_v1';

  // --- Purchases ---

  static Future<List<Purchase>> readPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_keyPurchaseHistory) ?? [];
      return list
          .map((jsonStr) => Purchase.fromJson(jsonDecode(jsonStr)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }

  static Future<void> savePurchase(Purchase purchase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_keyPurchaseHistory) ?? [];
      list.add(jsonEncode(purchase.toJson()));
      await prefs.setStringList(_keyPurchaseHistory, list);
    } catch (e) {
      // Handle error
    }
  }

  // --- Cart ---

  static Future<List<CartItem>> readCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_keyCart) ?? [];
      return list.map((jsonStr) => CartItem.fromJson(jsonDecode(jsonStr))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveCart(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = items.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_keyCart, list);
    } catch (e) {
      // Handle error
    }
  }

  // --- Bookmarks ---

  static Future<List<String>> readBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyBookmarks) ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> toggleBookmark(String batchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_keyBookmarks) ?? [];
      if (list.contains(batchId)) {
        list.remove(batchId);
      } else {
        list.add(batchId);
      }
      await prefs.setStringList(_keyBookmarks, list);
    } catch (e) {
      // Handle error
    }
  }
}
