import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/store_data.dart';

class StoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('courses');
  CollectionReference<Map<String, dynamic>> get _purchasesRef =>
      _firestore.collection('purchases');

  // --- Courses ---

  Stream<List<Course>> getCourses() {
    return _coursesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Manual mapping because Course has complex nested objects (Batch)
        // In a real app, you might use json_serializable or similar
        return Course(
          id: doc.id,
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          emoji: data['emoji'] ?? '',
          gradientColors: (data['gradientColors'] as List<dynamic>?)
                  ?.map((c) => Color(c))
                  .toList() ??
              [Colors.blue, Colors.blueAccent],
          priceDefault: (data['priceDefault'] as num?)?.toDouble() ?? 0.0,
          batches: (data['batches'] as List<dynamic>?)?.map((b) {
                return Batch(
                  id: b['id'],
                  name: b['name'],
                  startDate: DateTime.parse(b['startDate']),
                  price: (b['price'] as num).toDouble(),
                  seatsLeft: b['seatsLeft'],
                  duration: b['duration'],
                  isEnrolled: b['isEnrolled'] ?? false,
                );
              }).toList() ??
              [],
        );
      }).toList();
    });
  }

  // --- Purchases ---

  Future<void> createPurchase(Purchase purchase) async {
    await _purchasesRef.doc(purchase.id).set(purchase.toJson());
  }

  Future<List<Purchase>> getPurchases(String userId) async {
    final snapshot = await _purchasesRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => Purchase.fromJson(doc.data())).toList();
  }

  // --- Seeding ---

  Future<void> seedInitialData() async {
    final snapshot = await _coursesRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Already seeded

    for (final course in StoreData.courses) {
      await _coursesRef.doc(course.id).set({
        'title': course.title,
        'subtitle': course.subtitle,
        'emoji': course.emoji,
        'gradientColors': course.gradientColors.map((c) => c.toARGB32()).toList(),
        'priceDefault': course.priceDefault,
        'batches': course.batches
            .map((b) => {
                  'id': b.id,
                  'name': b.name,
                  'startDate': b.startDate.toIso8601String(),
                  'price': b.price,
                  'seatsLeft': b.seatsLeft,
                  'duration': b.duration,
                  'isEnrolled': b.isEnrolled,
                })
            .toList(),
      });
    }
  }
}
