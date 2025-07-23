import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/provider/vendore/seller_auth_provider.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<SellerAuthProvider>(context, listen: false);

    final msg = await authProvider.signIn(
      context: context,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted && msg != null) {
      showCustomSnackBar(context, msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SellerAuthProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // --- BACKGROUND IMAGE ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Using a high-quality, relevant background image
                image: AssetImage('assets/images/food_bite.webp'), // Make sure you have this image
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            color: Colors.black.withOpacity(0.3),
          ),


          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                height: screenHeight - MediaQuery.of(context).padding.top,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        "Welcome Back!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            const Shadow(blurRadius: 10, color: Colors.black54)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        "Log in to your delicious dashboard",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),


                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Email Field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _buildInputDecoration(label: 'Email'),
                                      validator: (v) => v!.isEmpty ? 'Email cannot be empty' : null,
                                    ),
                                    const SizedBox(height: 20),

                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _buildInputDecoration(
                                        label: 'Password',
                                        isPassword: true,
                                      ),
                                      validator: (v) => v!.length < 6 ? 'Password too short' : null,
                                    ),
                                    const SizedBox(height: 24),

                                    ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrangeAccent,
                                        minimumSize: const Size(double.infinity, 50),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 8,
                                        shadowColor: Colors.black.withOpacity(0.4),
                                      ),
                                      child: authProvider.isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : Text('Log In', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text("or continue with", style: GoogleFonts.poppins(color: Colors.white70)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(iconPath: 'assets/images/g.png'),
                              const SizedBox(width: 20), // Add apple icon
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?", style: GoogleFonts.poppins(color: Colors.white70)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/signup'),
                                child: Text('Sign Up', style: GoogleFonts.poppins(color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for input field decoration
  InputDecoration _buildInputDecoration({required String label, bool isPassword = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepOrangeAccent, width: 2),
      ),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      )
          : null,
    );
  }

  Widget _buildSocialButton({required String iconPath}) {
    return InkWell(
      onTap: () {


        ///----impliment the google or other social plat from login -------

      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Image.asset(iconPath, height: 32, width: 32),
      ),
    );
  }
}
