import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodLoverProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  // To store the user's favorite product IDs
  List<String> _userFavorites = [];
  List<String> get userFavorites => _userFavorites;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  // --- NEW --- Fetches the current user's favorite list
  Future<void> loadUserFavorites() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _client
          .from('users')
          .select('fav_foods')
          .eq('id', user.id)
          .single();

      if (data['fav_foods'] != null) {
        // Convert the dynamic list from Supabase to a List<String>
        _userFavorites = List<String>.from(data['fav_foods'].map((id) => id.toString()));
      }
    } catch (e) {
      debugPrint("Error loading user favorites: $e");
      _userFavorites = [];
    }
    notifyListeners();
  }

  // --- NEW --- Toggles a product's favorite status
  Future<void> toggleFavorite(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final isCurrentlyFavorite = _userFavorites.contains(productId);

    if (isCurrentlyFavorite) {
      _userFavorites.remove(productId);
    } else {
      _userFavorites.add(productId);
    }
    notifyListeners(); // Update UI immediately for responsiveness

    try {
      await _client
          .from('users')
          .update({'fav_foods': _userFavorites})
          .eq('id', user.id);
    } catch (e) {
      debugPrint("Error updating favorites in DB: $e");
      // Revert UI change on error
      if (isCurrentlyFavorite) {
        _userFavorites.add(productId);
      } else {
        _userFavorites.remove(productId);
      }
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getProductsForHomeScreen() async {
    try {
      var query = _client
          .from('products')
          .select('*, stalls(name)')
          .eq('is_available', true);

      if (_selectedCategory != null) {
        query = query.eq('category', _selectedCategory!);
      }

      final products = await query.order('created_at', ascending: false);

      return products;
    } catch (e) {
      debugPrint('Error fetching home screen products: $e');
      throw 'Could not fetch products. Please try again.';
    }
  }
}
