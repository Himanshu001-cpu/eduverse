import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple page to create a test enrollment
/// Navigate to this page from anywhere to create test data
class TestEnrollmentPage extends StatefulWidget {
  const TestEnrollmentPage({Key? key}) : super(key: key);

  @override
  State<TestEnrollmentPage> createState() => _TestEnrollmentPageState();
}

class _TestEnrollmentPageState extends State<TestEnrollmentPage> {
  bool _isLoading = false;
  String _message = '';
  String _status = '';

  Future<void> _createEnrollment() async {
    setState(() {
      _isLoading = true;
      _message = 'Creating test enrollment...';
      _status = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final userId = user.uid;
      _updateMessage('User ID: $userId');

      // Get first published course
      _updateMessage('Finding published courses...');
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('visibility', isEqualTo: 'published')
          .limit(1)
          .get();

      if (coursesSnapshot.docs.isEmpty) {
        throw Exception('No published courses found');
      }

      final courseDoc = coursesSnapshot.docs.first;
      final courseId = courseDoc.id;
      final courseData = courseDoc.data();
      final courseTitle = courseData['title'] ?? 'Test Course';

      _updateMessage('Found course: $courseTitle');

      // Get batch
      _updateMessage('Finding batches...');
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
        final batches = courseData['batches'] as List?;
        if (batches != null && batches.isNotEmpty) {
          final batch = batches.first;
          batchId = batch['id'] ?? 'batch_1';
          batchName = batch['name'] ?? 'Test Batch';
          price = (batch['price'] as num?)?.toDouble() ?? 0.0;
        } else {
          throw Exception('No batches found');
        }
      }

      _updateMessage('Found batch: $batchName');

      // Create purchase
      _updateMessage('Creating purchase record...');
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
        'status': 'completed',
      };

      await FirebaseFirestore.instance
          .collection('purchases')
          .doc(purchaseId)
          .set(purchase);

      setState(() {
        _isLoading = false;
        _status = 'success';
        _message = '✅ Success!\n\nCourse: $courseTitle\nBatch: $batchName\nPurchase ID: $purchaseId\n\nGo to Study section to see your enrolled course!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'error';
        _message = '❌ Error: $e';
      });
    }
  }

  void _updateMessage(String msg) {
    setState(() {
      _message = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Test Enrollment'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.science,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Test Enrollment Creator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create a completed purchase for the first available course, allowing you to test the Study section.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status == 'success'
                      ? Colors.green.shade50
                      : _status == 'error'
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status == 'success'
                        ? Colors.green
                        : _status == 'error'
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _status == 'success'
                        ? Colors.green.shade900
                        : _status == 'error'
                            ? Colors.red.shade900
                            : Colors.blue.shade900,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createEnrollment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Test Enrollment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
