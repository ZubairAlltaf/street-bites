import 'dart:io';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/provider/vendore/product_provider.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _foodCategories = ['Main Course', 'Appetizer', 'Dessert', 'Beverage', 'Snack'];
  String? _selectedFoodCategory;
  bool _isVeg = true;
  bool _isAvailable = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleAddProduct() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    // Check if image is picked
    if (productProvider.pickedImage == null) {
      showCustomSnackBar(context, 'Please select a product image before adding.', isError: true);
      return;
    }

    final msg = await productProvider.addProduct(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _selectedFoodCategory!,
      isVeg: _isVeg,
      isAvailable: _isAvailable,
    );

    if (mounted) {
      if (msg == null) {
        showCustomSnackBar(context, 'Product added successfully!');
        Navigator.of(context).pop();
      } else {
        showCustomSnackBar(context, msg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Add New Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Product Image", Icons.image_outlined),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => productProvider.pickImage(),
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildImagePreview(productProvider),
                    ),
                  ),
                ),
              ),
              if (productProvider.pickedImage != null)
                Center(
                  child: TextButton(
                    onPressed: () => productProvider.clearImage(),
                    child: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  ),
                ),
              const SizedBox(height: 24),

              _buildSectionHeader("Product Details", Icons.fastfood_outlined),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(labelText: 'Product Name'),
                validator: (v) => v!.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: _buildInputDecoration(labelText: 'Price (PKR)', prefixText: 'Rs. '),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Please enter a price';
                  if (double.tryParse(v) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionHeader("Categorization", Icons.category_outlined),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFoodCategory,
                decoration: _buildInputDecoration(labelText: 'Food Category'),
                items: _foodCategories.map((String category) {
                  return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                validator: (v) => v == null ? 'Please select a category' : null,
                onChanged: (value) => setState(() => _selectedFoodCategory = value!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildChoiceChip('Veg', Colors.green, _isVeg, () => setState(() => _isVeg = true)),
                  _buildChoiceChip('Non-Veg', Colors.red, !_isVeg, () => setState(() => _isVeg = false)),
                ],
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: Text('Available for Order', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
                activeColor: Colors.deepOrangeAccent,
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: productProvider.isLoading ? null : _handleAddProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: productProvider.isLoading ? Container() : const Icon(Icons.add_circle_outline),
                label: productProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Add Product to Menu', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ProductProvider provider) {
    if (provider.pickedImage == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text('Tap to upload', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return kIsWeb
        ? Image.memory(provider.imageBytes!, fit: BoxFit.cover)
        : Image.file(File(provider.pickedImage!.path), fit: BoxFit.cover);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
      ],
    );
  }

  InputDecoration _buildInputDecoration({required String labelText, String? prefixText}) {
    return InputDecoration(
      labelText: labelText,
      prefixText: prefixText,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepOrangeAccent, width: 2),
      ),
    );
  }

  Widget _buildChoiceChip(String label, Color color, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
      shape: StadiumBorder(side: BorderSide(color: isSelected ? color : Colors.grey.shade300)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
