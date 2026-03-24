// file: lib/store/screens/purchase_cart_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/widgets/cart_item_tile.dart';
import 'package:eduverse/store/screens/payment_result_page.dart';
import 'package:eduverse/common/persistence/purchase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/core/firebase/purchase_service.dart';
import 'package:eduverse/core/firebase/cart_service.dart';
import 'package:eduverse/core/firebase/razorpay_service.dart';
import 'package:eduverse/core/firebase/promo_code_service.dart';

class PurchaseCartPage extends StatefulWidget {
  final List<CartItem> initialItems;

  const PurchaseCartPage({super.key, this.initialItems = const []});

  @override
  State<PurchaseCartPage> createState() => _PurchaseCartPageState();
}

class _PurchaseCartPageState extends State<PurchaseCartPage> {
  List<CartItem> _cartItems = [];
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.0;
  String? _couponError;
  String? _appliedCouponCode;
  Map<String, double> _itemDiscounts =
      {}; // key: courseId_batchId -> discounted price
  bool _isValidatingCoupon = false;

  bool _isProcessing = false;

  final PromoCodeService _promoService = PromoCodeService();

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.initialItems);
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (_cartItems.isEmpty) {
      final savedCart = await PurchaseStorage.readCart();
      setState(() {
        _cartItems = savedCart;
      });
    } else {
      await PurchaseStorage.saveCart(_cartItems);
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _removeItem(int index) {
    final removedItem = _cartItems[index];
    setState(() {
      _cartItems.removeAt(index);
      if (_cartItems.isEmpty) {
        _discount = 0.0;
        _appliedCouponCode = null;
        _itemDiscounts = {};
      }
    });
    PurchaseStorage.saveCart(_cartItems);

    // Re-validate promo if items changed
    if (_appliedCouponCode != null && _cartItems.isNotEmpty) {
      _applyCoupon();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedItem.title} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _cartItems.insert(index, removedItem);
            });
            PurchaseStorage.saveCart(_cartItems);
            // Re-validate promo after undo
            if (_appliedCouponCode != null) {
              _applyCoupon();
            }
          },
        ),
      ),
    );
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    final cartItems = _cartItems
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
        _isValidatingCoupon = false;
        if (result.isValid) {
          _discount = result.discountAmount;
          _couponError = null;
          _appliedCouponCode = code;
          _itemDiscounts = result.itemDiscounts;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Coupon $code applied! You save ₹${_discount.toStringAsFixed(0)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _discount = 0.0;
          _couponError = result.errorMessage;
          _appliedCouponCode = null;
          _itemDiscounts = {};
        }
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _discount = 0.0;
      _couponError = null;
      _appliedCouponCode = null;
      _itemDiscounts = {};
      _couponController.clear();
    });
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.price);
  double get _total => _subtotal - _discount;

  Future<void> _handlePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to continue')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Fetch user data from Firestore for prefill
      String userName = user.displayName ?? 'Customer';
      String userEmail = user.email ?? '';
      String userPhone = user.phoneNumber ?? '';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          userName = data['name'] as String? ?? userName;
          userEmail = data['email'] as String? ?? userEmail;
          userPhone = data['phone'] as String? ?? userPhone;
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }

      final razorpayService = RazorpayService();
      final tempOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      await razorpayService.startPayment(
        amount: _total,
        orderId: tempOrderId,
        customerName: userName,
        customerEmail: userEmail,
        customerPhone: userPhone,
        promoCode: _appliedCouponCode,
        description: _cartItems.length == 1
            ? _cartItems.first.title
            : '${_cartItems.length} items',
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

      final itemsMap = _cartItems.map((e) => e.toJson()).toList();

      final purchaseId = await purchaseService.createPurchase(
        uid: user.uid,
        amount: _total,
        paymentId: result.paymentId ?? orderId,
        items: itemsMap,
        method: 'razorpay',
        status: 'success',
        promoCode: _appliedCouponCode,
        discountAmount: _discount,
      );

      // Increment promo code usage if applied
      if (_appliedCouponCode != null) {
        await _promoService.incrementUsage(_appliedCouponCode!);
      }

      final productTitle = _cartItems.length == 1
          ? _cartItems.first.title
          : '${_cartItems.length} items';

      await purchaseService.saveTransaction(
        uid: user.uid,
        orderId: purchaseId,
        productTitle: productTitle,
        amount: _total,
        status: 'success',
        paymentMethod: 'razorpay',
      );

      await cartService.clearCart(user.uid);
      await PurchaseStorage.saveCart([]);

      final purchase = Purchase(
        userId: user.uid,
        id: purchaseId,
        timestamp: DateTime.now(),
        amount: _total,
        items: _cartItems,
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('My Cart'), elevation: 0),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final key = '${item.courseId}_${item.batchId}';
                      final discountedPrice = _itemDiscounts[key];
                      return CartItemTile(
                        item: item,
                        onRemove: () => _removeItem(index),
                        discountedPrice: discountedPrice,
                      );
                    },
                  ),
                ),
                _buildSummarySection(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coupon input / applied coupon
            if (_appliedCouponCode != null)
              _buildAppliedCouponBanner()
            else
              _buildCouponInput(),
            const SizedBox(height: 20),
            // Price breakdown
            _buildPriceRow('Original Total', _subtotal),
            if (_discount > 0) ...[
              _buildPriceRow(
                'Promo Discount ($_appliedCouponCode)',
                -_discount,
                color: Colors.green,
              ),
            ],
            const Divider(height: 24),
            _buildPriceRow('You Pay', _total, isTotal: true),
            const SizedBox(height: 24),
            ElevatedButton(
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
                      'Pay ₹${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _couponController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter Promo Code',
              errorText: _couponError,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.local_offer_outlined),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isValidatingCoupon ? null : _applyCoupon,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isValidatingCoupon
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildAppliedCouponBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appliedCouponCode!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'You save ₹${_discount.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removeCoupon,
            icon: Icon(Icons.close, color: Colors.green.shade700, size: 20),
            tooltip: 'Remove promo code',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? Colors.black : Colors.black87),
            ),
          ),
        ],
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
