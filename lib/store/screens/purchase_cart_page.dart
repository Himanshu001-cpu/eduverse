// file: lib/store/screens/purchase_cart_page.dart
import 'package:flutter/material.dart';
import '../purchase_data.dart';
import '../widgets/cart_item_tile.dart';
import 'checkout_page.dart';

// QA Checklist:
// [ ] Add a course to cart and open Cart page - item visible with correct price.
// [ ] Apply a valid coupon - discount applied to total.
// [ ] Proceed to Checkout and select Card with valid mock details - Pay succeeds ~95% and purchase saved.
// [ ] On success, PurchaseHistoryPage shows transaction; tapping opens details modal.
// [ ] Remove item from cart, undo works via SnackBar.
// [ ] On failure (simulate), retry payment works and logged status is "Failed".
// [ ] flutter analyze should not show missing imports for the created files.

class PurchaseCartPage extends StatefulWidget {
  final List<CartItem> initialItems;

  const PurchaseCartPage({Key? key, this.initialItems = const []}) : super(key: key);

  @override
  State<PurchaseCartPage> createState() => _PurchaseCartPageState();
}

class _PurchaseCartPageState extends State<PurchaseCartPage> {
  late List<CartItem> _cartItems;
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.0;
  String? _couponError;
  static const double _taxRate = 0.18; // 18% GST

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.initialItems);
    
    // Mock: If empty, add a sample item for testing if not provided
    if (_cartItems.isEmpty) {
      _cartItems.add(CartItem(
        id: 'c1',
        title: 'UPSC Foundation Batch',
        subtitle: 'Complete Prelims + Mains',
        price: 4999.0,
        emoji: '🏛️',
      ));
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
      // Reset discount if cart becomes empty or logic requires re-validation
      if (_cartItems.isEmpty) _discount = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedItem.title} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _cartItems.insert(index, removedItem);
            });
          },
        ),
      ),
    );
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (PurchaseData.coupons.containsKey(code)) {
      setState(() {
        _discount = PurchaseData.coupons[code]!;
        _couponError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon $code applied!')),
      );
    } else {
      setState(() {
        _discount = 0.0;
        _couponError = 'Invalid coupon code';
      });
    }
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.price);
  double get _tax => (_subtotal - _discount) * _taxRate;
  double get _total => (_subtotal - _discount) + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('My Cart'),
        elevation: 0,
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      return CartItemTile(
                        item: _cartItems[index],
                        onRemove: () => _removeItem(index),
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
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
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
            color: Colors.black.withOpacity(0.05),
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
            // Coupon Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter Coupon Code',
                      errorText: _couponError,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Breakdown
            _buildPriceRow('Subtotal', _subtotal),
            if (_discount > 0)
              _buildPriceRow('Discount', -_discount, color: Colors.green),
            _buildPriceRow('Tax (18%)', _tax),
            const Divider(height: 24),
            _buildPriceRow('Total', _total, isTotal: true),
            
            const SizedBox(height: 24),

            // Checkout Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutPage(
                      items: _cartItems,
                      totalAmount: _total,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            '₹${amount.abs().toStringAsFixed(2)}',
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
