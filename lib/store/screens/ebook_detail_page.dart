import 'package:flutter/material.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/services/cart_service.dart';
import 'package:eduverse/store/screens/purchase_cart_page.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';

class EbookDetailPage extends StatefulWidget {
  final Ebook ebook;

  const EbookDetailPage({super.key, required this.ebook});

  @override
  State<EbookDetailPage> createState() => _EbookDetailPageState();
}

class _EbookDetailPageState extends State<EbookDetailPage> {
  bool _isAddingToCart = false;

  Future<void> _launchPdf(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PDF URL')),
      );
      return;
    }
    try {
      await PdfNavigationManager.navigateToViewer(
        context,
        SecurePdfViewerArgs(
          pdfUrl: url,
          title: widget.ebook.title,
          isProtected: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the PDF URL')),
        );
      }
    }
  }

  Future<void> _handleBuyNow() async {
    final uid = EduverseFirebase.auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to purchase')),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartItem = CartItem(
        courseId: '',
        batchId: '',
        ebookId: widget.ebook.id,
        title: widget.ebook.title,
        price: widget.ebook.finalPrice,
        quantity: 1,
      );

      await CartService().addToCart(uid, cartItem);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PurchaseCartPage(
              initialItems: [cartItem],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to cart: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ebook = widget.ebook;
    final displayPrice = ebook.finalPrice > 0 ? '₹${ebook.finalPrice.toStringAsFixed(0)}' : 'FREE';

    return Scaffold(
      appBar: AppBar(
        title: Text(ebook.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portrait Thumbnail and Core Details
              Center(
                child: Container(
                  width: 180,
                  height: 270,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ebook.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            ebook.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallback(),
                          )
                        : _buildFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                ebook.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ebook.subtitle.isNotEmpty ? 'By ${ebook.subtitle}' : 'Author: Unknown',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (ebook.realPrice > ebook.finalPrice) ...[
                    const SizedBox(width: 10),
                    Text(
                      '₹${ebook.realPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 40),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                ebook.description.isNotEmpty ? ebook.description : 'No description available for this E-book.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 100), // Spacing for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ebook.isOwned
              ? ElevatedButton(
                  onPressed: () => _launchPdf(ebook.pdfUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text(
                        'Read E-book',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: _isAddingToCart ? null : _handleBuyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isAddingToCart
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart),
                            SizedBox(width: 8),
                            Text(
                              'Buy Now',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.book,
        size: 80,
        color: Colors.white70,
      ),
    );
  }
}
