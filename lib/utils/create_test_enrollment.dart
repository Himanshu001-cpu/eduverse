import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Run this function once to create a test enrollment for the current user.
/// This will allow you to see enrolled courses in the Study section.
Future<void> createTestEnrollment() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ No user logged in. Please sign in first.');
    return;
  }

  final userId = user.uid;
  print('Creating test enrollment for user: $userId');

  // Get the first available course and batch
  final coursesSnapshot = await FirebaseFirestore.instance
      .collection('courses')
      .where('visibility', isEqualTo: 'published')
      .limit(1)
      .get();

  if (coursesSnapshot.docs.isEmpty) {
    print('❌ No published courses found. Please create a course in Admin Panel first.');
    return;
  }

  final courseDoc = coursesSnapshot.docs.first;
  final courseId = courseDoc.id;
  final courseData = courseDoc.data();
  final courseTitle = courseData['title'] ?? 'Test Course';

  // Try to get a batch from subcollection
  final batchesSnapshot = await FirebaseFirestore.instance
      .collection('courses')
      .doc(courseId)
      .collection('batches')
      .limit(1)
      .get();

  String batchId;
  String batchName;
  double price;

  if (batchesSnapshot.docs.isNotEmpty) {
    final batchDoc = batchesSnapshot.docs.first;
    batchId = batchDoc.id;
    final batchData = batchDoc.data();
    batchName = batchData['name'] ?? 'Test Batch';
    price = (batchData['price'] as num?)?.toDouble() ?? 0.0;
  } else {
    // Fallback to embedded batch if exists
    final batches = courseData['batches'] as List?;
    if (batches != null && batches.isNotEmpty) {
      final batch = batches.first;
      batchId = batch['id'] ?? 'batch_1';
      batchName = batch['name'] ?? 'Test Batch';
      price = (batch['price'] as num?)?.toDouble() ?? 0.0;
    } else {
      print('❌ No batches found for this course.');
      return;
    }
  }

  // Create a test purchase
  final purchaseId = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
  final purchase = {
    'userId': userId,
    'id': purchaseId,
    'timestamp': DateTime.now().toIso8601String(),
    'items': [
      {
        'courseId': courseId,
        'batchId': batchId,
        'title': '$courseTitle - $batchName',
        'price': price,
        'quantity': 1,
      }
    ],
    'amount': price,
    'paymentMethod': 'test',
    'status': 'completed', // This is the key - marking as completed
  };

  await FirebaseFirestore.instance
      .collection('purchases')
      .doc(purchaseId)
      .set(purchase);

  print('✅ Test enrollment created successfully!');
  print('   Course: $courseTitle');
  print('   Batch: $batchName');
  print('   Purchase ID: $purchaseId');
  print('   Status: completed');
  print('\nYou can now check the Study section to see your enrolled course.');
}
