// file: lib/store/purchase_data.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MODELS ---

class CartItem {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final String? thumbnailUrl; // Optional, can use emoji if null
  final String emoji;

  CartItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.thumbnailUrl,
    this.emoji = '📚',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'price': price,
        'thumbnailUrl': thumbnailUrl,
        'emoji': emoji,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        title: json['title'],
        subtitle: json['subtitle'],
        price: json['price'],
        thumbnailUrl: json['thumbnailUrl'],
        emoji: json['emoji'] ?? '📚',
      );
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class Purchase {
  final String id;
  final DateTime date;
  final double amount;
  final List<CartItem> items;
  final String paymentMethod;
  final String status; // 'Success', 'Failed'

  Purchase({
    required this.id,
    required this.date,
    required this.amount,
    required this.items,
    required this.paymentMethod,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'items': items.map((i) => i.toJson()).toList(),
        'paymentMethod': paymentMethod,
        'status': status,
      };

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        id: json['id'],
        date: DateTime.parse(json['date']),
        amount: json['amount'],
        items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
        paymentMethod: json['paymentMethod'],
        status: json['status'],
      );
}

// --- DATA & LOGIC ---

class PurchaseData {
  static const String _historyKey = 'purchase_history_v1';

  // Mock Coupons
  static const Map<String, double> coupons = {
    'WELCOME50': 50.0,
    'STUDY10': 10.0, // 10% off logic handled in UI or fixed amount? 
                     // Prompt says "discount reflected", let's assume fixed amount for simplicity 
                     // or we can make it sophisticated. Let's stick to fixed amount for now as per "discount (coupon)" line item.
    'FLUTTER20': 20.0,
  };

  // Mock Payment Methods
  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'card',
      name: 'Credit / Debit Card',
      description: 'Visa, Mastercard, Rupay',
      icon: Icons.credit_card,
    ),
    PaymentMethod(
      id: 'upi',
      name: 'UPI',
      description: 'Google Pay, PhonePe, Paytm',
      icon: Icons.qr_code,
    ),
    PaymentMethod(
      id: 'netbanking',
      name: 'Net Banking',
      description: 'All Indian banks',
      icon: Icons.account_balance,
    ),
    PaymentMethod(
      id: 'wallet',
      name: 'Wallets',
      description: 'Amazon Pay, Paytm, etc.',
      icon: Icons.account_balance_wallet,
    ),
  ];

  // Logic: Save Purchase
  static Future<void> savePurchase(Purchase purchase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList(_historyKey) ?? [];
      history.add(jsonEncode(purchase.toJson()));
      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      debugPrint('Error saving purchase: $e');
      rethrow;
    }
  }

  // Logic: Get History
  static Future<List<Purchase>> getPurchaseHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList(_historyKey) ?? [];
      return history
          .map((item) => Purchase.fromJson(jsonDecode(item)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }

  // Logic: Mock Payment Processing
  static Future<bool> processPayment() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));
    // 95% Success Rate
    return Random().nextDouble() < 0.95;
  }
}
