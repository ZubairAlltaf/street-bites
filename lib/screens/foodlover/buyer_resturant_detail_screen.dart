import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/models/cart_model.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> mockMenuItems = const [
    {
      'id': '1',
      'restaurant_id': '1',
      'name': 'Chicken Tacos',
      'description': 'Soft tortillas with grilled chicken, salsa, and avocado.',
      'price': 8.99,
      'image': 'https://images.pexels.com/photos/1231146/pexels-photo-1231146.jpeg',
    },
    {
      'id': '2',
      'restaurant_id': '2',
      'name': 'Classic Burger',
      'description': 'Beef patty with lettuce, tomato, and secret sauce.',
      'price': 10.99,
      'image': 'https://images.pexels.com/photos/1639557/pexels-photo-1639557.jpeg',
    },
    {
      'id': '3',
      'restaurant_id': '3',
      'name': 'Margherita Pizza',
      'description': 'Fresh mozzarella, basil, and tomato sauce.',
      'price': 12.99,
      'image': 'https://images.pexels.com/photos/315755/pexels-photo-315755.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Hero section
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    image: DecorationImage(
                      image: NetworkImage(widget.restaurant['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurant['name'],
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                        ),
                      ),
                      Text(
                        widget.restaurant['cuisine'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: mockMenuItems.length,
                itemBuilder: (context, index) {
                  final item = mockMenuItems[index];
                  if (item['restaurant_id'] != widget.restaurant['id']) return const SizedBox.shrink();
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item['image'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  item['description'],
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '\$${item['price'].toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTapDown: (_) => _animationController.forward(),
                            onTapUp: (_) {
                              _animationController.reverse().then((_) {
                                cartProvider.addItem(CartItem(
                                  id: item['id'],
                                  name: item['name'],
                                  price: item['price'],
                                  image: item['image'],
                                ));
                                showCustomSnackBar(context, '${item['name']} added to cart!');
                              });
                            },
                            onTapCancel: () => _animationController.reverse(),
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.orange, size: 32),
                                onPressed: () {
                                  cartProvider.addItem(CartItem(
                                    id: item['id'],
                                    name: item['name'],
                                    price: item['price'],
                                    image: item['image'],
                                  ));
                                  showCustomSnackBar(context, '${item['name']} added to cart!');
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}