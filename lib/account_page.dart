import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/provider/buyer/buyer_auth_provider.dart';
import 'package:streetbites/screens/login_screen.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';
import 'package:streetbites/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _totalSpentController = TextEditingController();
  final _totalOrdersController = TextEditingController();
  final _favStallsController = TextEditingController();
  final _favFoodsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

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
    _getProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _totalSpentController.dispose();
    _totalOrdersController.dispose();
    _favStallsController.dispose();
    _favFoodsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _userData = data;
          _nameController.text = data['name'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _totalSpentController.text = '\$${data['total_spent'] ?? 0}';
          _totalOrdersController.text = '${data['total_orders'] ?? 0}';
          _favStallsController.text = (data['fav_stalls'] as List<dynamic>?)?.join(', ') ?? 'None';
          _favFoodsController.text = (data['fav_foods'] as List<dynamic>?)?.join(', ') ?? 'None';
          _isLoading = false;
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        showCustomSnackBar(context, error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        showCustomSnackBar(context, 'Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<BuyerAuthProvider>(context, listen: false);
    final user = Supabase.instance.client.auth.currentUser!;
    final newUsername = _usernameController.text.trim();
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    try {
      // Check if username changed and is available
      if (newUsername != _userData!['username']) {
        await authProvider.checkUsername(newUsername);
        if (!authProvider.usernameAvailable) {
          showCustomSnackBar(context, 'Username is already taken', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final updates = {
        'id': user.id,
        'name': newName,
        'username': newUsername,
        'phone': newPhone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('users').upsert(updates);
      if (mounted) {
        showCustomSnackBar(context, 'Profile updated successfully!');
        await _getProfile(); // Refresh data
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        showCustomSnackBar(context, error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        showCustomSnackBar(context, 'Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        showCustomSnackBar(context, error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        showCustomSnackBar(context, 'Unexpected error occurred', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<BuyerAuthProvider>(context);

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
          child: _isLoading && _userData == null
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 2,
            ),
          )
              : SingleChildScrollView(
            child: Column(
              children: [
                // Hero section
                Stack(
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/food_bite.webp'),
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
                      child: Text(
                        'Your Profile',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [Shadow(blurRadius: 6, color: Colors.black87)],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                if (value.length > 3 && value != _userData?['username']) {
                                  await authProvider.checkUsername(value);
                                }
                              },
                              suffixIcon: authProvider.checkingUsername
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange,
                                ),
                              )
                                  : _usernameController.text.isNotEmpty &&
                                  _usernameController.text != _userData?['username']
                                  ? Icon(
                                authProvider.usernameAvailable ? Icons.check : Icons.close,
                                color: authProvider.usernameAvailable
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                              )
                                  : null,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value != _userData?['username'] && !authProvider.usernameAvailable) {
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
                              label: 'Email (Read-only)',
                              controller: _emailController,
                              readOnly: true,
                              keyboardType: TextInputType.emailAddress,
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
                              label: 'Total Spent',
                              controller: _totalSpentController,
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              label: 'Total Orders',
                              controller: _totalOrdersController,
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              label: 'Favorite Stalls',
                              controller: _favStallsController,
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              label: 'Favorite Foods',
                              controller: _favFoodsController,
                              readOnly: true,
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTapDown: (_) {
                                if (!_isLoading) {
                                  _animationController.forward();
                                }
                              },
                              onTapUp: (_) {
                                if (!_isLoading) {
                                  _animationController.reverse().then((_) => _updateProfile());
                                }
                              },
                              onTapCancel: () {
                                if (!_isLoading) {
                                  _animationController.reverse();
                                }
                              },
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _updateProfile,
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
                                  child: Text(_isLoading ? 'Updating...' : 'Update Profile'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : _signOut,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange.shade600,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text('Sign Out'),
                            ),
                          ],
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