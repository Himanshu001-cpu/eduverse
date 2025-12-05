// file: lib/store/screens/payment_result_page.dart
import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/purchase_history_page.dart';
import 'package:eduverse/store/screens/checkout_page.dart';
import 'package:eduverse/study/screens/batch_section_page.dart';
import 'package:eduverse/study/models/study_models.dart';

class PaymentResultPage extends StatelessWidget {
  final Purchase purchase;

  const PaymentResultPage({super.key, required this.purchase});

  bool get _isSuccess => purchase.status == 'Success';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSuccess ? Icons.check_circle : Icons.error,
                  size: 60,
                  color: _isSuccess ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isSuccess ? 'Payment Successful!' : 'Payment Failed',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isSuccess
                    ? 'Thank you for your purchase. You can now access your courses.'
                    : 'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Transaction ID', purchase.id),
                    const Divider(),
                    _buildDetailRow('Amount', '₹${purchase.amount.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildDetailRow('Date', '${purchase.timestamp.day}/${purchase.timestamp.month}/${purchase.timestamp.year}'),
                  ],
                ),
              ),
              const Spacer(),
              if (_isSuccess) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the batch page of the first item
                      if (purchase.items.isNotEmpty) {
                        final item = purchase.items.first;
                        // Mock conversion to study course
                        final studyCourse = StudyCourseModel(
                          id: item.courseId,
                          title: 'Purchased Course',
                          subtitle: '',
                          gradientColors: [Colors.blue, Colors.purple],
                        );
                        
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BatchSectionPage(
                              course: studyCourse,
                              batchId: item.batchId,
                            ),
                          ),
                          (route) => route.isFirst,
                        );
                      } else {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Go to Course', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const PurchaseHistoryPage()),
                    );
                  },
                  child: const Text('View Purchases'),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                            items: purchase.items,
                            totalAmount: purchase.amount,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry Payment', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
