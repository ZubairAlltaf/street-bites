import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/provider/buyer/buyer_auth_provider.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import 'package:streetbites/widgets/custom_text_field.dart';
import 'email_verification_screen_food.dart';

class BuyerSignUpScreen extends StatefulWidget {
  const BuyerSignUpScreen({super.key});

  @override
  State<BuyerSignUpScreen> createState() => _BuyerSignUpScreenState();
}

class _BuyerSignUpScreenState extends State<BuyerSignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<BuyerAuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade600, Colors.green.shade300],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/food_bite.webp'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      height: 220,
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
                      bottom: 20,
                      left: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Join StreetBites 🍔',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Savor the best street food flavors!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              shadows: [Shadow(blurRadius: 3, color: Colors.black87)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (!auth.isLoading) {
                        _animationController.reverse().then((_) => _animationController.forward());
                      }
                    },
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  label: 'Full Name',
                                  controller: _nameController,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  label: 'Username',
                                  controller: _usernameController,
                                  onChanged: (value) async {
                                    if (value.length > 3) {
                                      await auth.checkUsername(value);
                                    }
                                  },
                                  suffixIcon: auth.checkingUsername
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange,
                                    ),
                                  )
                                      : Icon(
                                    auth.usernameAvailable ? Icons.check : Icons.close,
                                    color: auth.usernameAvailable
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a username';
                                    }
                                    if (!auth.usernameAvailable) {
                                      return 'Username is already taken';
                                    }
                                    if (value.trim().length < 4) {
                                      return 'Username must be at least 4 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  label: 'Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  label: 'Phone Number',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
                                      return 'Please enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.trim().length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTapDown: (_) {
                                    if (!auth.isLoading) {
                                      _animationController.reverse().then((_) => _animationController.forward());
                                    }
                                  },
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () async {
                                      if (!_formKey.currentState!.validate()) return;

                                      final msg = await auth.signUpBuyer(
                                        name: _nameController.text.trim(),
                                        username: _usernameController.text.trim(),
                                        email: _emailController.text.trim(),
                                        phone: _phoneController.text.trim(),
                                        password: _passwordController.text.trim(), context: context,
                                      );

                                      if (msg == null) {
                                        showCustomSnackBar(context, 'Check your email to verify!');
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const EmailVerificationScreen(),
                                          ),
                                        );
                                      } else {
                                        showCustomSnackBar(context, msg, isError: true);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 6,
                                      shadowColor: Colors.black38,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text(auth.isLoading ? 'Signing up...' : 'Create Account'),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade400,
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.restaurant_menu,
                                            size: 20,
                                            color: Colors.orange.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Or continue with',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade400,
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTapDown: (_) {
                                    if (!auth.isLoading) {
                                      _animationController.reverse().then((_) => _animationController.forward());
                                    }
                                  },
                                  child: ElevatedButton.icon(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () async {
                                      final msg = await auth.signInWithGoogle(context:context);
                                      if (msg != null) {
                                        showCustomSnackBar(context, msg, isError: true);
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/g.png',
                                      height: 24,
                                    ),
                                    label: const Text('Google'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      elevation: 6,
                                      shadowColor: Colors.black38,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}