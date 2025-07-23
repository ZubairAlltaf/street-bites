import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/screens/vendore/add_product_screen.dart';
import 'package:streetbites/screens/vendore/chat_list_screen.dart';
import 'package:streetbites/screens/vendore/manage_menu_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../provider/vendore/seller_auth_provider.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    // Fetch the data when the screen loads
    _dashboardData = Provider.of<SellerAuthProvider>(context, listen: false)
        .getSellerDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          }

          final data = snapshot.data!;
          final status = data['status'];

          // Conditionally build the UI based on the stall's status
          return status == 'approved'
              ? _buildDashboardScreen(context, data)
              : _buildPendingScreen(context, data);
        },
      ),
    );
  }

  // --- UI FOR PENDING/REJECTED STALLS ---
  Widget _buildPendingScreen(BuildContext context, Map<String, dynamic> data) {
    return Container(
      decoration: _buildBackgroundDecoration(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 80),
                  const SizedBox(height: 20),
                  Text(
                    'Pending Approval',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Your business "${data['stallName']}" is under review. We will notify you once it\'s approved.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// --- UI FOR APPROVED STALLS (THE MAIN DASHBOARD) ---
  Widget _buildDashboardScreen(BuildContext context, Map<String, dynamic> data) {
    return Container(
      decoration: _buildBackgroundDecoration(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Text(
                      'Welcome, ${data['sellerName']}!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(onPressed: (){
                      Navigator.of(context).push(MaterialPageRoute(builder: (context)=> VendorChatsListScreen()));
                    }, icon:Icon(Icons.chat_outlined) )
                  ],),
                  Text(
                    'Your Dashboard for "${data['stallName']}"',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Section
                  Row(
                    children: [
                      _buildStatCard('Total Revenue', data['totalRevenue'], Icons.account_balance_wallet_outlined, Colors.green),
                      const SizedBox(width: 16),
                      _buildStatCard('Orders Today', data['ordersToday'], Icons.receipt_long_outlined, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions Section
                  _buildDashboardCard(
                    context: context,
                    title: 'Manage Menu',
                    subtitle: 'Add, edit, or remove food items',
                    icon: Icons.restaurant_menu_outlined,
                    color: Colors.deepOrangeAccent,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context)=> ManageMenuScreen()));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDashboardCard(
                    context: context,
                    title: 'View Orders',
                    subtitle: 'Check incoming and past orders',
                    icon: Icons.list_alt_outlined,
                    color: Colors.blueAccent,
                    onTap: () { /* TODO: Navigate to Orders Screen */ },
                  ),
                  const SizedBox(height: 16),
                  _buildDashboardCard(
                    context: context,
                    title: 'Store Settings',
                    subtitle: 'Update business hours and details',
                    icon: Icons.settings_outlined,
                    color: Colors.purpleAccent,
                    onTap: () { /* TODO: Navigate to Settings Screen */ },
                  ),
                  const SizedBox(height: 32),

                  // Sign Out Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/stall_owner.webp'),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color,
                      radius: 24,
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(subtitle, style: GoogleFonts.poppins(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}