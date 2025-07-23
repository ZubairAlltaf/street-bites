import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/provider/vendore/seller_auth_provider.dart';
import 'package:streetbites/screens/vendore/seller_home_screen.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerStallCreationScreen extends StatefulWidget {
  const SellerStallCreationScreen({super.key});

  @override
  State<SellerStallCreationScreen> createState() => _SellerStallCreationScreenState();
}

class _SellerStallCreationScreenState extends State<SellerStallCreationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _locationController = TextEditingController();
  String _businessType = 'Stall';
  String? _selectedCategory;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, List<String>> _categoryOptions = {
    'Stall': [
      'Burgers & Fries',
      'Shawarma & Rolls',
      'Samosa, Pakora & Kachori',
      'Chaat & Dahi Bhallay',
      'BBQ, Tikka & Kabab',
      'Bun Kabab & Anda Shami',
      'Juices & Shakes',
      'Lassi & Traditional Drinks',
      'Ice Cream & Falooda',
      'Kulfi',
      'Soups & Corn',
      'Fried Fish & Seafood',
      'Haleem & Nihari',
      'Paratha & Chai'
    ],
    'Restaurant': [
      'Karahi (Chicken, Mutton, Beef)',
      'Handi (Boneless)',
      'Biryani & Pulao',
      'BBQ Platters & Grills',
      'Nihari & Paya',
      'Qorma & Curries',
      'Pizza',
      'Burgers & Steaks',
      'Chinese & Thai',
      'Afghan & Middle Eastern',
      'Seafood Specialties',
      'Buffet & Thali',
      'Desserts & Bakeries',
      'Fast Food Deals'
    ],
    'HomeMade': [
      'Daily Lunch/Dinner',
      'Homemade Biryani & Pulao',
      'Frozen Items (Samosa, Kabab, etc.)',
      'Diet & Healthy Meals',
      'Homemade Desserts (Kheer, Gajar Halwa)',
      'Cakes & Bakery Items',
      'Office Lunch Boxes',
      'Salads & Sandwiches',
      'Traditional Dishes (Saag, etc.)'
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleCreateStall() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<SellerAuthProvider>(context, listen: false);

    final msg = await authProvider.createStall(
      businessName: _businessNameController.text.trim(),
      businessType: _businessType,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      category: _selectedCategory!,
    );

    if (mounted) {
      if (msg == null) {
        showCustomSnackBar(context, 'Business created! Awaiting admin approval.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerHomeScreen()),
        );
      } else {
        showCustomSnackBar(context, msg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SellerAuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Setup Your Business', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("1. What's your business type?", Icons.storefront_outlined),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTypeSelector('Stall', Icons.fastfood_outlined),
                      _buildTypeSelector('Restaurant', Icons.restaurant_outlined),
                      _buildTypeSelector('HomeMade', Icons.home_work_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader("2. Tell us more about it", Icons.edit_note_outlined),
                  const SizedBox(height: 16),

                  // Business Name
                  TextFormField(
                    controller: _businessNameController,
                    decoration: _buildInputDecoration(labelText: 'Business Name'),
                    validator: (v) => v!.trim().isEmpty ? 'Please enter a business name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _buildInputDecoration(labelText: 'Category'),
                    items: _categoryOptions[_businessType]!.map((String category) {
                      return DropdownMenuItem<String>(value: category, child: Text(category));
                    }).toList(),
                    validator: (v) => v == null ? 'Please select a category' : null,
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: _buildInputDecoration(labelText: 'Location${_businessType == 'Restaurant' ? '' : ' (Optional)'}'),
                    validator: (v) {
                      if (_businessType == 'Restaurant' && (v == null || v.trim().isEmpty)) {
                        return 'Location is required for restaurants';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Create Button
                  ElevatedButton.icon(
                    onPressed: authProvider.isLoading ? null : _handleCreateStall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      shadowColor: Colors.deepOrange.withOpacity(0.4),
                    ),
                    icon: authProvider.isLoading ? Container() : const Icon(Icons.rocket_launch_outlined),
                    label: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Create Business', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  Widget _buildTypeSelector(String type, IconData icon) {
    final isSelected = _businessType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _businessType = type;
            _selectedCategory = null; // Reset category on type change
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrangeAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.deepOrangeAccent : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[800], size: 28),
              const SizedBox(height: 8),
              Text(
                type,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
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
}
