import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model for a promo code stored in Firestore
class PromoCode {
  final String code;
  final String type; // 'percentage' or 'fixed'
  final double value; // Percentage (0-100) or fixed amount
  final double? minOrderAmount;
  final double? maxDiscount; // For percentage discounts
  final DateTime? expiresAt;
  final bool isActive;
  final int? usageLimit;
  final int usedCount;
  final List<String>? applicableCourseIds; // null = applies to all courses
  final List<String>? applicableBatchIds; // null = applies to all batches

  const PromoCode({
    required this.code,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscount,
    this.expiresAt,
    this.isActive = true,
    this.usageLimit,
    this.usedCount = 0,
    this.applicableCourseIds,
    this.applicableBatchIds,
  });

  factory PromoCode.fromMap(Map<String, dynamic> map) {
    return PromoCode(
      code: map['code'] as String? ?? '',
      type: map['type'] as String? ?? 'percentage',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble(),
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] as bool? ?? true,
      usageLimit: map['usageLimit'] as int?,
      usedCount: map['usedCount'] as int? ?? 0,
      applicableCourseIds: (map['applicableCourseIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      applicableBatchIds: (map['applicableBatchIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'code': code,
      'type': type,
      'value': value,
      'isActive': isActive,
      'usedCount': usedCount,
    };
    if (minOrderAmount != null) map['minOrderAmount'] = minOrderAmount;
    if (maxDiscount != null) map['maxDiscount'] = maxDiscount;
    if (expiresAt != null) map['expiresAt'] = Timestamp.fromDate(expiresAt!);
    if (usageLimit != null) map['usageLimit'] = usageLimit;
    if (applicableCourseIds != null) {
      map['applicableCourseIds'] = applicableCourseIds;
    }
    if (applicableBatchIds != null) {
      map['applicableBatchIds'] = applicableBatchIds;
    }
    return map;
  }

  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    if (usageLimit != null && usedCount >= usageLimit!) return false;
    return true;
  }

  /// Check if this promo code applies to a specific item
  bool isApplicableToItem(String courseId, String batchId) {
    // If no course restriction, applies to all
    final courseMatch =
        applicableCourseIds == null ||
        applicableCourseIds!.isEmpty ||
        applicableCourseIds!.contains(courseId);
    // If no batch restriction, applies to all
    final batchMatch =
        applicableBatchIds == null ||
        applicableBatchIds!.isEmpty ||
        applicableBatchIds!.contains(batchId);
    return courseMatch && batchMatch;
  }

  /// Calculate discount for a given order amount
  double calculateDiscount(double orderAmount) {
    if (!isValid) return 0;
    if (minOrderAmount != null && orderAmount < minOrderAmount!) return 0;

    double discount;
    if (type == 'percentage') {
      discount = orderAmount * (value / 100);
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      // Fixed discount
      discount = value;
    }

    // Discount cannot exceed order amount
    return discount > orderAmount ? orderAmount : discount;
  }
}

/// Result of promo code validation
class PromoCodeResult {
  final bool isValid;
  final double discountAmount;
  final String? errorMessage;
  final PromoCode? promoCode;
  // Map of "courseId_batchId" -> discounted price for each applicable item
  final Map<String, double> itemDiscounts;

  const PromoCodeResult({
    required this.isValid,
    this.discountAmount = 0,
    this.errorMessage,
    this.promoCode,
    this.itemDiscounts = const {},
  });

  factory PromoCodeResult.success(
    PromoCode code,
    double discount,
    Map<String, double> itemDiscounts,
  ) {
    return PromoCodeResult(
      isValid: true,
      discountAmount: discount,
      promoCode: code,
      itemDiscounts: itemDiscounts,
    );
  }

  factory PromoCodeResult.error(String message) {
    return PromoCodeResult(isValid: false, errorMessage: message);
  }
}

/// Represents a cart item for promo validation purposes
class PromoCartItem {
  final String courseId;
  final String batchId;
  final double price;

  const PromoCartItem({
    required this.courseId,
    required this.batchId,
    required this.price,
  });
}

/// Service to validate and apply promo codes from Firestore
class PromoCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _codesRef =>
      _firestore.collection('config').doc('promo_codes').collection('codes');

  /// Validate a promo code against cart items
  Future<PromoCodeResult> validatePromoCode(
    String code,
    List<PromoCartItem> cartItems,
  ) async {
    try {
      final codeUpper = code.trim().toUpperCase();

      if (codeUpper.isEmpty) {
        return PromoCodeResult.error('Please enter a promo code');
      }

      debugPrint('[PromoCodeService] Validating code: $codeUpper');

      // Query Firestore for the promo code
      final doc = await _codesRef.doc(codeUpper).get();

      if (!doc.exists || doc.data() == null) {
        return PromoCodeResult.error('Invalid promo code');
      }

      final promoCode = PromoCode.fromMap(doc.data()!);

      if (!promoCode.isActive) {
        return PromoCodeResult.error('This promo code is no longer active');
      }

      if (promoCode.expiresAt != null &&
          DateTime.now().isAfter(promoCode.expiresAt!)) {
        return PromoCodeResult.error('This promo code has expired');
      }

      if (promoCode.usageLimit != null &&
          promoCode.usedCount >= promoCode.usageLimit!) {
        return PromoCodeResult.error(
          'This promo code has reached its usage limit',
        );
      }

      // Calculate applicable amount & per-item discounts
      double applicableTotal = 0;
      final applicableItems = <PromoCartItem>[];
      for (final item in cartItems) {
        if (promoCode.isApplicableToItem(item.courseId, item.batchId)) {
          applicableTotal += item.price;
          applicableItems.add(item);
        }
      }

      if (applicableItems.isEmpty) {
        return PromoCodeResult.error(
          'This promo code is not applicable to items in your cart',
        );
      }

      if (promoCode.minOrderAmount != null &&
          applicableTotal < promoCode.minOrderAmount!) {
        return PromoCodeResult.error(
          'Minimum order amount of ₹${promoCode.minOrderAmount!.toStringAsFixed(0)} required for applicable items',
        );
      }

      final totalDiscount = promoCode.calculateDiscount(applicableTotal);

      // Calculate per-item discounts proportionally
      final itemDiscounts = <String, double>{};
      for (final item in applicableItems) {
        final key = '${item.courseId}_${item.batchId}';
        final proportion = item.price / applicableTotal;
        final itemDiscount = double.parse(
          (totalDiscount * proportion).toStringAsFixed(2),
        );
        itemDiscounts[key] = item.price - itemDiscount;
      }

      debugPrint(
        '[PromoCodeService] Code valid, discount: ₹$totalDiscount on ${applicableItems.length} items',
      );

      return PromoCodeResult.success(promoCode, totalDiscount, itemDiscounts);
    } catch (e) {
      debugPrint('[PromoCodeService] Error validating code: $e');
      return PromoCodeResult.error('Unable to validate promo code');
    }
  }

  /// Increment usage count after successful payment
  Future<void> incrementUsage(String code) async {
    try {
      final codeUpper = code.trim().toUpperCase();
      await _codesRef.doc(codeUpper).update({
        'usedCount': FieldValue.increment(1),
      });
      debugPrint('[PromoCodeService] Incremented usage for: $codeUpper');
    } catch (e) {
      debugPrint('[PromoCodeService] Error incrementing usage: $e');
    }
  }

  // ─── Admin CRUD Methods ─────────────────────────────────────────

  /// Get all promo codes (for admin panel)
  Stream<List<PromoCode>> getAllPromoCodes() {
    return _codesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PromoCode.fromMap(doc.data())).toList();
    });
  }

  /// Create a new promo code
  Future<void> createPromoCode(PromoCode promoCode) async {
    final codeUpper = promoCode.code.trim().toUpperCase();
    final existing = await _codesRef.doc(codeUpper).get();
    if (existing.exists) {
      throw Exception('Promo code "$codeUpper" already exists');
    }
    await _codesRef.doc(codeUpper).set(promoCode.toMap());
    debugPrint('[PromoCodeService] Created promo code: $codeUpper');
  }

  /// Update an existing promo code
  Future<void> updatePromoCode(PromoCode promoCode) async {
    final codeUpper = promoCode.code.trim().toUpperCase();
    await _codesRef.doc(codeUpper).update(promoCode.toMap());
    debugPrint('[PromoCodeService] Updated promo code: $codeUpper');
  }

  /// Delete a promo code
  Future<void> deletePromoCode(String code) async {
    final codeUpper = code.trim().toUpperCase();
    await _codesRef.doc(codeUpper).delete();
    debugPrint('[PromoCodeService] Deleted promo code: $codeUpper');
  }
}
