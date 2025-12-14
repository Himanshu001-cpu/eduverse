// file: lib/store/store_data.dart
import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';

// Data is now fetched from Firestore - this file only contains UI constants

class StoreData {
  // Banners are now fetched from Firestore
  static final List<BannerModel> banners = [];

  // Courses are now fetched from Firestore
  static final List<Course> courses = [];

  // Coupons should be managed via Firestore/Admin panel
  static const Map<String, double> coupons = {};

  // Payment methods - UI constants (kept as they define UI options)
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
