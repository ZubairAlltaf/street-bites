import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:streetbites/screens/vendore/seller_home_screen.dart';
import 'package:streetbites/screens/vendore/seller_stall_creation_screen.dart';

class SellerAuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool isLoading = false;
  bool checkingUsername = false;
  bool usernameAvailable = true;

  User? get currentUser => _client.auth.currentUser;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setUsernameStatus(bool checking, bool available) {
    checkingUsername = checking;
    usernameAvailable = available;
    notifyListeners();
  }

  Future<void> checkUsername(String username) async {
    if (username.length < 4) {
      _setUsernameStatus(false, false);
      return;
    }
    _setUsernameStatus(true, true);
    final res = await _client
        .from('users')
        .select('username')
        .eq('username', username.trim())
        .maybeSingle();
    _setUsernameStatus(false, res == null);
  }

  Future<bool> checkEmailExists(String email) async {
    final res = await _client
        .from('users')
        .select('email')
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();
    return res != null;
  }

  Future<String?> signUpSeller({
    required BuildContext context,
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final usernameRes = await _client
          .from('users')
          .select('username')
          .eq('username', username.trim())
          .maybeSingle();
      if (usernameRes != null) return 'Username is already taken.';

      final emailExists = await checkEmailExists(email);
      if (emailExists) return 'This email is already registered.';

      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'full_name': name.trim(),
          'username': username.trim(),
        },
      );

      if (res.user == null) {
        debugPrint('SIGNUP ERROR: No user returned after signup');
        return 'Signup failed. Please try again.';
      }

      // After successful signup in auth, create the user profile in the public 'users' table.
      await _client.from('users').insert({
        'id': res.user!.id,
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'username': username.trim(),
        'role': 'seller', // Explicitly set role
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('SIGNUP SUCCESS: User ${res.user!.id} created in auth and users table');
      return null;
    } on AuthException catch (e) {
      debugPrint('SIGNUP AUTH EXCEPTION: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('SELLER SIGNUP ERROR: $e');
      return 'Something went wrong. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  // --- CORRECTED AND SIMPLIFIED SIGN-IN METHOD ---
  Future<String?> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 1. Authenticate the user. Let Supabase handle errors like "Invalid credentials".
      final authResponse = await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password.trim(),
      );

      if (authResponse.user == null) {
        return 'Login failed. Please try again.';
      }

      final userId = authResponse.user!.id;

      // 2. Fetch the user's profile from your public 'users' table.
      final userData = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      // 3. Check the role and navigate.
      // If userData is null, it means the user exists in auth but not in your
      // public table. The signup flow should prevent this, but we default to 'seller'
      // as a fallback.
      final role = userData?['role'] as String? ?? 'seller';

      debugPrint('SIGNIN SUCCESS: User $userId logged in with role: $role');

      if (role == 'seller') {
        // For sellers, check if they have a stall.
        final stallRes = await _client
            .from('stalls')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        // Navigate based on stall existence.
        if (stallRes != null) {
          debugPrint('Navigating to SellerHomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SellerHomeScreen()),
          );
        } else {
          debugPrint('Navigating to SellerStallCreationScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SellerStallCreationScreen()),
          );
        }
      } else {
        // For any other role, navigate to the food lover home screen.
        debugPrint('Navigating to FoodLoverHomeScreen');
        Navigator.pushReplacementNamed(context, '/food_lover_home');
      }

      return null; // Success
    } on AuthException catch (e) {
      // Let Supabase provide the specific error message (e.g., "Invalid login credentials").
      debugPrint('SIGNIN AUTH EXCEPTION: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('SIGNIN UNEXPECTED ERROR: $e');
      return 'An unexpected error occurred. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> createStall({
    required String businessName,
    required String businessType,
    required String category,
    String? location,
  }) async {
    _setLoading(true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('STALL CREATION ERROR: No user logged in');
        return 'No user logged in.';
      }

      final stallRes = await _client
          .from('stalls')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (stallRes != null) {
        return 'A stall or restaurant is already registered for this account.';
      }

      await _client.from('stalls').insert({
        'user_id': user.id,
        'name': businessName.trim(),
        'type': businessType,
        'category': category.trim(),
        'location':
        businessType == 'Restaurant' ? location!.trim() : location?.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _client.from('users').update({
        'business_name': businessName.trim(),
        'business_type': businessType,
      }).eq('id', user.id);

      debugPrint('STALL CREATION SUCCESS: Stall created for user ${user.id}');
      return null;
    } catch (e) {
      debugPrint('STALL CREATION ERROR: $e');
      return 'Something went wrong while creating your business. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkStallApproval() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('STALL APPROVAL CHECK ERROR: No user logged in');
        return false;
      }
      final stall =
      await _client.from('stalls').select('status').eq('user_id', user.id).single();
      return stall['status'] == 'approved';
    } catch (e) {
      debugPrint('Check stall approval error: $e');
      return false;
    }
  }



  // Add this method inside your SellerAuthProvider class

  Future<Map<String, dynamic>> getSellerDashboardData() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw 'User not logged in.';
      }

      /// Fetch stall data including the 'status'
      final stallData = await _client
          .from('stalls')
          .select('name, status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (stallData == null) {
        throw 'Stall not found for this user.';
      }

      // You can add more data fetching here later (e.g., orders, revenue)
      return {
        'stallName': stallData['name'],
        'status': stallData['status'],
        'sellerName': user.userMetadata?['full_name'] ?? 'Vendor',
        // Placeholder stats for the UI
        'totalRevenue': 'Rs. 0',
        'ordersToday': '0',
        'rating': 'N/A',
      };
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      rethrow; // Rethrow the error to be caught by the UI
    }
  }
}
