// file: lib/store/store_data.dart
import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';

// README:
// This file contains mock data for the Store.
// Persistence keys used: 'purchase_history_v1', 'cart_v1', 'bookmarks_v1'.
// To test flows:
// 1. Use 'WELCOME50' coupon in cart.
// 2. Use any valid card format (16 digits) in checkout.
// 3. Purchase updates 'seatsLeft' in-memory (reset on restart).

class StoreData {
  static final List<BannerModel> banners = [
    BannerModel(
      title: 'UPSC 2025 Foundation',
      subtitle: 'Start your journey today',
      emoji: '🏛️',
      colors: [Colors.blue, Colors.indigo],
    ),
    BannerModel(
      title: 'CSAT Mastery',
      subtitle: 'Crack the aptitude test',
      emoji: '🧮',
      colors: [Colors.orange, Colors.deepOrange],
    ),
    BannerModel(
      title: 'NCERT Summary',
      subtitle: 'Build strong basics',
      emoji: '📚',
      colors: [Colors.green, Colors.teal],
    ),
  ];

  static final List<Course> courses = [
    Course(
      id: 'c1',
      title: 'UPSC IAS Foundation',
      subtitle: 'Prelims + Mains + Interview',
      emoji: '🏛️',
      gradientColors: [Colors.blue, Colors.lightBlueAccent],
      priceDefault: 25000,
      batches: [
        Batch(
          id: 'b1_1',
          name: 'Morning Batch A',
          startDate: DateTime.now().add(const Duration(days: 5)),
          price: 25000,
          seatsLeft: 15,
          duration: '12 Months',
        ),
        Batch(
          id: 'b1_2',
          name: 'Evening Batch B',
          startDate: DateTime.now().add(const Duration(days: 12)),
          price: 25000,
          seatsLeft: 50,
          duration: '12 Months',
        ),
      ],
    ),
    Course(
      id: 'c2',
      title: 'CSAT Special',
      subtitle: 'Maths, Reasoning, English',
      emoji: '🧮',
      gradientColors: [Colors.orange, Colors.deepOrangeAccent],
      priceDefault: 5000,
      batches: [
        Batch(
          id: 'b2_1',
          name: 'Weekend Batch',
          startDate: DateTime.now().add(const Duration(days: 2)),
          price: 5000,
          seatsLeft: 5,
          duration: '3 Months',
        ),
      ],
    ),
    Course(
      id: 'c3',
      title: 'Ethics Integrity & Aptitude',
      subtitle: 'GS Paper 4 Complete',
      emoji: '⚖️',
      gradientColors: [Colors.purple, Colors.deepPurpleAccent],
      priceDefault: 8000,
      batches: [
        Batch(
          id: 'b3_1',
          name: 'Fast Track',
          startDate: DateTime.now().add(const Duration(days: 7)),
          price: 8000,
          seatsLeft: 20,
          duration: '2 Months',
        ),
      ],
    ),
    Course(
      id: 'c4',
      title: 'Essay Writing',
      subtitle: 'Master the art of expression',
      emoji: '✍️',
      gradientColors: [Colors.pink, Colors.redAccent],
      priceDefault: 3000,
      batches: [
        Batch(
          id: 'b4_1',
          name: 'Weekly Workshop',
          startDate: DateTime.now().add(const Duration(days: 1)),
          price: 3000,
          seatsLeft: 100,
          duration: '1 Month',
        ),
      ],
    ),
  ];

  static const Map<String, double> coupons = {
    'WELCOME50': 500.0, // Fixed amount discount
    'STUDY10': 100.0,
    'FLUTTER20': 200.0,
  };

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
}
