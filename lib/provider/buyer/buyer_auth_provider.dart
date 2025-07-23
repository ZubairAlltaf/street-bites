import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/foodlover/buyer_home_screen.dart';

// Placeholder HomeScreen widget (replace with your actual HomeScreen)

class BuyerAuthProvider extends ChangeNotifier {
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
        .eq('email', email.trim())
        .maybeSingle();
    return res != null;
  }

  Future<bool> checkPhoneExists(String phone) async {
    final res = await _client
        .from('users')
        .select('phone')
        .eq('phone', phone.trim())
        .maybeSingle();
    return res != null;
  }

  Future<String?> signUpBuyer({
    required BuildContext context,
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      // Check username
      final usernameRes = await _client
          .from('users')
          .select('username')
          .eq('username', username.trim())
          .maybeSingle();
      if (usernameRes != null) {
        return 'Username is already taken.';
      }

      // Check email
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        return 'This email is already registered. Please use another email or sign in.';
      }

      // Check phone
      final phoneExists = await checkPhoneExists(phone);
      if (phoneExists) {
        return 'This phone number is already registered.';
      }

      // Attempt signup
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        emailRedirectTo: 'io.supabase.streetbites://verify',
        data: {
          'full_name': name.trim(),
          'username': username.trim(),
          'phone': phone.trim(),
        },
      );

      await _client.from('users').insert({
        'id': res.user!.id,
        'email': email.trim(),
        'name': name.trim(),
        'username': username.trim(),
        'phone': phone.trim(),
        'role': 'food_lover',
        'created_at': DateTime.now().toIso8601String(),
        'total_spent': 0,
        'total_orders': 0,
        'fav_stalls': [],
        'fav_foods': [],
      });

      // Check email verification
      final isVerified = await checkEmailVerification();
      if (isVerified) {
        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FoodLoverHomeScreen()),
        );
        return null;
      } else {
        return 'Please verify your email before proceeding.';
      }
    } on AuthException catch (e) {
      if (e.message.contains('User already registered')) {
        return 'This email is already registered. Please use another email or sign in.';
      }
      return e.message;
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');
      return 'Something went wrong. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signInBuyer({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Check email verification
      final isVerified = await checkEmailVerification();
      if (isVerified) {
        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FoodLoverHomeScreen()),
        );
        return null;
      } else {
        return 'Please verify your email before proceeding.';
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('SIGNIN ERROR: $e');
      return 'Something went wrong. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signInWithGoogle({required BuildContext context}) async {
    _setLoading(true);
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? '${Uri.base.origin}/auth/callback'
            : 'io.supabase.streetbites://login-callback',
      );
      if (response) {
        final user = _client.auth.currentUser;
        if (user != null) {
          await insertUserIfNotExists(
            user: user,
            name: user.userMetadata?['full_name'] ?? '',
            username: '',
            phone: '',
          );

          // Check email verification
          final isVerified = await checkEmailVerification();
          if (isVerified) {
            // Navigate to HomeScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FoodLoverHomeScreen()),
            );
            return null;
          } else {
            return 'Please verify your email before proceeding.';
          }
        }
        return 'Google sign-in failed.';
      }
      return 'Google sign-in failed.';
    } catch (e) {
      debugPrint('Google login error: $e');
      return 'Failed to sign in with Google. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> insertUserIfNotExists({
    required User user,
    required String name,
    required String username,
    required String phone,
  }) async {
    final exists = await _client
        .from('users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (exists == null) {
      String finalUsername = username.isNotEmpty
          ? username.trim()
          : 'user_${DateTime.now().millisecondsSinceEpoch}';

      bool isUnique = false;
      int attempt = 0;
      String baseUsername = finalUsername;
      while (!isUnique && attempt < 5) {
        final usernameRes = await _client
            .from('users')
            .select('username')
            .eq('username', finalUsername)
            .maybeSingle();
        if (usernameRes == null) {
          isUnique = true;
        } else {
          attempt++;
          finalUsername = '$baseUsername$attempt';
        }
      }

      await _client.from('users').insert({
        'id': user.id,
        'email': user.email,
        'name': name.isNotEmpty ? name.trim() : user.userMetadata?['full_name'] ?? '',
        'username': finalUsername,
        'phone': phone.trim(),
        'role': 'food_lover',
        'created_at': DateTime.now().toIso8601String(),
        'total_spent': 0,
        'total_orders': 0,
        'fav_stalls': [],
        'fav_foods': [],
      });
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      // Refresh session to get latest user data
      await _client.auth.refreshSession();
      return user.emailConfirmedAt != null;
    } catch (e) {
      debugPrint('Check verification error: $e');
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      await _client.auth.resend(
        type: OtpType.email,
        email: user.email!,
        emailRedirectTo: 'io.supabase.streetbites://verify',
      );
      return true;
    } catch (e) {
      debugPrint('Resend verification email error: $e');
      return false;
    }
  }
}