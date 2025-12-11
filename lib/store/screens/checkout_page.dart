import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/store_data.dart';
import 'package:eduverse/store/widgets/payment_method_tile.dart';
import 'package:eduverse/store/screens/payment_result_page.dart';
import 'package:eduverse/common/persistence/purchase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/core/firebase/purchase_service.dart';
import 'package:eduverse/core/firebase/cart_service.dart';
import 'package:eduverse/core/firebase/razorpay_service.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedMethodId = 'card';
  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _upiIdController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _handlePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final razorpayService = RazorpayService();
      final tempOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      await razorpayService.startPayment(
        amount: widget.totalAmount,
        orderId: tempOrderId,
        customerName: user.displayName ?? 'Customer',
        customerEmail: user.email ?? '',
        customerPhone: user.phoneNumber ?? '',
        description: widget.items.length == 1
            ? widget.items.first.title
            : '${widget.items.length} items',
        onComplete: (result) {
          if (result.success) {
            _onPaymentSuccess(result, user, tempOrderId);
          } else {
            _onPaymentFailure(result);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _onPaymentSuccess(
    PaymentResult result,
    User user,
    String orderId,
  ) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PaymentProgressDialog(),
    );

    try {
      final purchaseService = PurchaseService();
      final cartService = CartService();

      final itemsMap = widget.items.map((e) => e.toJson()).toList();

      final purchaseId = await purchaseService.createPurchase(
        uid: user.uid,
        amount: widget.totalAmount,
        paymentId: result.paymentId ?? orderId,
        items: itemsMap,
        method: 'razorpay',
        status: 'success',
      );

      final productTitle = widget.items.length == 1
          ? widget.items.first.title
          : '${widget.items.length} items';

      await purchaseService.saveTransaction(
        uid: user.uid,
        orderId: purchaseId,
        productTitle: productTitle,
        amount: widget.totalAmount,
        status: 'success',
        paymentMethod: 'razorpay',
      );

      await cartService.clearCart(user.uid);
      await PurchaseStorage.saveCart([]);

      final purchase = Purchase(
        userId: user.uid,
        id: purchaseId,
        timestamp: DateTime.now(),
        amount: widget.totalAmount,
        items: widget.items,
        paymentMethod: 'razorpay',
        status: 'success',
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentResultPage(purchase: purchase),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving purchase: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _onPaymentFailure(PaymentResult result) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error Code: ${result.errorCode}'),
            const SizedBox(height: 8),
            Text('Message: ${result.errorMessage ?? "Unknown error"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Order Summary'),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.items.length} Items'),
                      Text(
                        '₹${widget.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Payment Method'),
              ...StoreData.paymentMethods.map((method) => PaymentMethodTile(
                    method: method,
                    isSelected: _selectedMethodId == method.id,
                    onTap: () => setState(() => _selectedMethodId = method.id),
                  )),
              const SizedBox(height: 24),
              _buildSectionTitle('Payment Details'),
              _buildPaymentDetailsInput(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Pay ₹${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentDetailsInput() {
    if (_selectedMethodId == 'card') {
      return Column(
        children: [
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '0000 0000 0000 0000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            maxLength: 16,
            validator: (value) {
              if (value == null || value.length != 16) return 'Enter valid 16-digit card number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    hintText: '12/25',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Invalid format';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length != 3) return 'Invalid CVV';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_selectedMethodId == 'upi') {
      return TextFormField(
        controller: _upiIdController,
        decoration: const InputDecoration(
          labelText: 'UPI ID',
          hintText: 'user@bank',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.qr_code),
        ),
        validator: (value) {
          if (value == null || !value.contains('@')) return 'Enter valid UPI ID';
          return null;
        },
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(child: Text('You will be redirected to complete payment.')),
          ],
        ),
      );
    }
  }
}

class _PaymentProgressDialog extends StatelessWidget {
  const _PaymentProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Processing Payment...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Please do not close this screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

