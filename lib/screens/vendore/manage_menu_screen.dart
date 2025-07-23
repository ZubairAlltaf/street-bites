import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/provider/vendore/product_provider.dart';
import 'package:streetbites/screens/vendore/add_product_screen.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    // We use the provider to fetch the products
    _productsFuture = Provider.of<ProductProvider>(context, listen: false).getProducts();
  }

  void _navigateToAndRefresh(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // When we return from the Add/Edit screen, refresh the product list
    setState(() {
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Manage Your Menu', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAndRefresh(const AddProductScreen()),
        label: Text('Add Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepOrangeAccent,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Products Found',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "Add Product" button to build your menu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                // FIX 1: Request a PNG from the placeholder service
                product['image_url'] ?? 'https://placehold.co/100x100/orange/white.png?text=No+Image',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.network('https://placehold.co/100x100/grey/white.png?text=Error', width: 80, height: 80, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIX 2: Make the title flexible to prevent overflow
                  Text(
                    product['name'],
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Truncate long names
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${product['price']}',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.deepOrangeAccent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['is_available'] ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: product['is_available'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  // TODO: Navigate to an EditProductScreen
                  showCustomSnackBar(context, 'Edit functionality coming soon!');
                } else if (value == 'delete') {
                  final msg = await productProvider.deleteProduct(product['id'], product['image_url']);
                  if (mounted) {
                    if (msg == null) {
                      showCustomSnackBar(context, 'Product deleted successfully.');
                      setState(() { _loadProducts(); }); // Refresh the list
                    } else {
                      showCustomSnackBar(context, msg, isError: true);
                    }
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
