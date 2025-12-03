// file: lib/store/screens/payment_result_page.dart
import 'package:flutter/material.dart';
import '../purchase_data.dart';
import 'purchase_history_page.dart';
import 'checkout_page.dart';

class PaymentResultPage extends StatelessWidget {
  final Purchase purchase;

  const PaymentResultPage({Key? key, required this.purchase}) : super(key: key);

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
              // Status Icon
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
              
              // Title
              Text(
                _isSuccess ? 'Payment Successful!' : 'Payment Failed',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Message
              Text(
                _isSuccess
                    ? 'Thank you for your purchase. You can now access your courses.'
                    : 'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Details Card
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
                    _buildDetailRow('Date', '${purchase.date.day}/${purchase.date.month}/${purchase.date.year}'),
                    const Divider(),
                    _buildDetailRow('Payment Method', purchase.paymentMethod.toUpperCase()),
                  ],
                ),
              ),
              
              const Spacer(),

              // Actions
              if (_isSuccess) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Purchase History
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const PurchaseHistoryPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Go to Purchases', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // Pop until back to app root or store
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Continue Studying'),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Retry: Open Checkout again
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
