import 'package:flutter/material.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/payment_result_page.dart';
import 'package:eduverse/common/persistence/purchase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/purchase_service.dart';
import 'package:eduverse/core/firebase/cart_service.dart';
import 'package:eduverse/core/firebase/razorpay_service.dart';
import 'package:eduverse/core/firebase/promo_code_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _gstController = TextEditingController();
  final _promoController = TextEditingController();

  bool _isProcessing = false;
  bool _isLoadingUser = true;
  bool _isValidatingPromo = false;

  // User data from Firestore
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userAddress = '';

  // Promo code state
  double _discountAmount = 0;
  String? _appliedPromoCode;
  String? _promoError;

  final PromoCodeService _promoService = PromoCodeService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _gstController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] as String? ?? user.displayName ?? '';
          _userEmail = data['email'] as String? ?? user.email ?? '';
          _userPhone = data['phone'] as String? ?? user.phoneNumber ?? '';
          _userAddress = data['address'] as String? ?? '';
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _userName = user.displayName ?? '';
          _userEmail = user.email ?? '';
          _userPhone = user.phoneNumber ?? '';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _userName = user.displayName ?? '';
        _userEmail = user.email ?? '';
        _userPhone = user.phoneNumber ?? '';
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() => _promoError = 'Please enter a promo code');
      return;
    }

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    final cartItems = widget.items
        .map(
          (e) => PromoCartItem(
            courseId: e.courseId,
            batchId: e.batchId,
            price: e.price,
          ),
        )
        .toList();
    final result = await _promoService.validatePromoCode(code, cartItems);

    if (mounted) {
      setState(() {
        _isValidatingPromo = false;
        if (result.isValid) {
          _discountAmount = result.discountAmount;
          _appliedPromoCode = code.toUpperCase();
          _promoError = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Promo code applied! You save ₹${_discountAmount.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _discountAmount = 0;
          _appliedPromoCode = null;
          _promoError = result.errorMessage;
        }
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _discountAmount = 0;
      _appliedPromoCode = null;
      _promoError = null;
      _promoController.clear();
    });
  }

  double get _finalAmount => widget.totalAmount - _discountAmount;

  String? _validateGst(String? value) {
    if (value == null || value.isEmpty) {
      return 'GST number is required';
    }
    // GST format: 15 characters (e.g., 22AAAAA0000A1Z5)
    final gstRegex = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );
    if (!gstRegex.hasMatch(value.toUpperCase())) {
      return 'Enter a valid 15-character GST number';
    }
    return null;
  }

  void _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to continue')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final razorpayService = RazorpayService();
      final tempOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final gstNumber = _gstController.text.trim().toUpperCase();

      await razorpayService.startPayment(
        amount: _finalAmount,
        orderId: tempOrderId,
        customerName: _userName.isNotEmpty ? _userName : 'Customer',
        customerEmail: _userEmail,
        customerPhone: _userPhone,
        customerAddress: _userAddress,
        gstNumber: gstNumber,
        promoCode: _appliedPromoCode,
        description: widget.items.length == 1
            ? widget.items.first.title
            : '${widget.items.length} items',
        onComplete: (result) {
          if (result.success) {
            _onPaymentSuccess(result, user, tempOrderId, gstNumber);
          } else {
            _onPaymentFailure(result);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _onPaymentSuccess(
    PaymentResult result,
    User user,
    String orderId,
    String gstNumber,
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
        amount: _finalAmount,
        paymentId: result.paymentId ?? orderId,
        items: itemsMap,
        method: 'razorpay',
        status: 'success',
        gstNumber: gstNumber,
        promoCode: _appliedPromoCode,
        discountAmount: _discountAmount,
      );

      // Increment promo code usage if applied
      if (_appliedPromoCode != null) {
        await _promoService.incrementUsage(_appliedPromoCode!);
      }

      final productTitle = widget.items.length == 1
          ? widget.items.first.title
          : '${widget.items.length} items';

      await purchaseService.saveTransaction(
        uid: user.uid,
        orderId: purchaseId,
        productTitle: productTitle,
        amount: _finalAmount,
        status: 'success',
        paymentMethod: 'razorpay',
      );

      await cartService.clearCart(user.uid);
      await PurchaseStorage.saveCart([]);

      final purchase = Purchase(
        userId: user.uid,
        id: purchaseId,
        timestamp: DateTime.now(),
        amount: _finalAmount,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving purchase: $e')));
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
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Order Summary'),
                    _buildOrderSummaryCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('GST Details'),
                    _buildGstInput(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Promo Code (Optional)'),
                    _buildPromoCodeInput(),
                    const SizedBox(height: 24),
                    _buildPriceSummary(),
                    const SizedBox(height: 24),
                    _buildUserInfoCard(),
                    const SizedBox(height: 32),
                    _buildPayButton(),
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

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...widget.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGstInput() {
    return TextFormField(
      controller: _gstController,
      decoration: InputDecoration(
        labelText: 'GST Number',
        hintText: 'e.g., 22AAAAA0000A1Z5',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.receipt_long),
        counterText: '',
      ),
      textCapitalization: TextCapitalization.characters,
      maxLength: 15,
      validator: _validateGst,
    );
  }

  Widget _buildPromoCodeInput() {
    if (_appliedPromoCode != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code: $_appliedPromoCode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'You save ₹${_discountAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _removePromoCode,
              icon: const Icon(Icons.close),
              tooltip: 'Remove promo code',
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoController,
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  errorText: _promoError,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isValidatingPromo ? null : _applyPromoCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isValidatingPromo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', widget.totalAmount),
            if (_discountAmount > 0)
              _buildPriceRow('Discount', -_discountAmount, color: Colors.green),
            const Divider(height: 24),
            _buildPriceRow('Total', _finalAmount, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color:
                  color ??
                  (isTotal ? Theme.of(context).primaryColor : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'The following details will be pre-filled in the payment form:',
              style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (_userName.isNotEmpty) _buildInfoRow('Name', _userName),
            if (_userEmail.isNotEmpty) _buildInfoRow('Email', _userEmail),
            if (_userPhone.isNotEmpty) _buildInfoRow('Phone', _userPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                'Pay ₹${_finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
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
