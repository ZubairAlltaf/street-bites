import 'package:flutter/material.dart';
import 'package:streetbites/screens/foodlover/buyer_signup_screen.dart';
import 'package:streetbites/screens/vendore/seller_signup_screen.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import 'package:streetbites/widgets/role_card.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade600, Colors.green.shade300], // Match BuyerSignUpScreen
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Welcome to StreetBites 🍔',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose your role to start your food journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [Shadow(blurRadius: 3, color: Colors.black87)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                RoleCard(
                  title: 'Food Lover',
                  icon: Icons.restaurant,
                  image: 'assets/images/stall_owner.webp',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BuyerSignUpScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                RoleCard(
                  title: 'Stall Owner',
                  icon: Icons.storefront,
                  image: 'assets/images/stall_owner.webp',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellerSignUpScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                RoleCard(
                  title: 'Rider',
                  icon: Icons.delivery_dining,
                  image: 'assets/images/delivery_rider.webp',
                  onTap: () {
                    showCustomSnackBar(context, 'Rider role coming soon! 🚧');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}