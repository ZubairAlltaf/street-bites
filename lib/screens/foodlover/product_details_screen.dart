import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import '../../provider/buyer/chat_provider.dart';
import 'chat_screen_fd_lvr.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // --- NEW METHOD TO HANDLE CHAT NAVIGATION ---
  void _navigateToChat() async {
    // Access the provider, but don't listen for changes here
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final sellerId = widget.product['user_id'];
    final productId = widget.product['id'];
    final stallName = (widget.product['stalls'] as Map<String, dynamic>?)?['name'] ?? 'Unknown Stall';

    if (sellerId == null || productId == null) {
      showCustomSnackBar(context, 'Could not initiate chat. Seller or product info missing.', isError: true);
      return;
    }

    try {
      // Show a loading indicator while we find/create the chat
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final chatId = await chatProvider.getOrCreateChat(productId, sellerId);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss the loading indicator

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              productName: widget.product['name'],
              sellerName: stallName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading indicator on error
        showCustomSnackBar(context, 'Error starting chat: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stallName = (widget.product['stalls'] as Map<String, dynamic>?)?['name'] ?? 'Unknown Stall';
    final rating = (widget.product['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = widget.product['review_count'] ?? 0;
    final price = (widget.product['price'] as num).toDouble();
    final totalPrice = price * _quantity;

    // Wrap with a provider so the chat button can access it
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title and Stall Name
                    Text(
                      widget.product['name'],
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          stallName,
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ratings and Reviews
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(rating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('($reviewCount Reviews)', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    const Divider(height: 40, thickness: 1),

                    // Description
                    Text('About this food', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.product['description'] ?? 'No description available.',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800], height: 1.5),
                    ),
                    const Divider(height: 40, thickness: 1),

                    // Quantity Selector
                    _buildQuantitySelector(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(totalPrice),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      backgroundColor: Colors.deepOrangeAccent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_image_${widget.product['id']}', // Unique tag for hero animation
          child: Image.network(
            widget.product['image_url'] ?? 'https://placehold.co/600x400/orange/white.png?text=Food',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.image_not_supported, color: Colors.white, size: 50)),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Quantity', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: _decrementQuantity, color: Colors.red),
              Text('$_quantity', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add), onPressed: _incrementQuantity, color: Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double totalPrice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // Chat Button
          OutlinedButton(
            // --- UPDATED onPressed TO CALL THE NEW METHOD ---
            onPressed: _navigateToChat,
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.deepOrangeAccent),
          ),
          const SizedBox(width: 16),
          // Add to Cart Button
          Expanded(
            child: ElevatedButton(
              // --- CORRECTED onPressed LOGIC ---
              onPressed: () { /* TODO: Add to cart logic */ },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add to Cart', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Rs. ${totalPrice.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
