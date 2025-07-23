import 'dart:io';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1000);

      if (pickedFile != null) {
        _pickedImage = pickedFile;
        if (kIsWeb) {
          _imageBytes = await pickedFile.readAsBytes();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void clearImage() {
    _pickedImage = null;
    _imageBytes = null;
    notifyListeners();
  }

  Future<String?> _uploadImage(XFile imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${imageFile.name.split('.').last}';
      final filePath = '$userId/$fileName';

      if (kIsWeb) {
        final imageBytes = await imageFile.readAsBytes();
        await _client.storage.from('product_images').uploadBinary(
          filePath,
          imageBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      } else {
        await _client.storage.from('product_images').upload(
          filePath,
          File(imageFile.path),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      }
      return _client.storage.from('product_images').getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Image Upload Error: $e");
      throw 'Image upload failed. Please try again.';
    }
  }

  Future<String?> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required bool isVeg,
    required bool isAvailable,
  }) async {
    _setLoading(true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'User is not authenticated.';

      final stallData = await _client.from('stalls').select('id').eq('user_id', user.id).maybeSingle();
      if (stallData == null) throw 'Could not find a stall for your account.';

      final stallId = stallData['id'];
      String? imageUrl;

      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!, user.id);
      } else {
        // This check is now in the UI, but as a safeguard
        throw 'Please select a product image.';
      }

      // --- UPDATED INSERT STATEMENT ---
      // Includes the new tracking fields with default values.
      await _client.from('products').insert({
        'stall_id': stallId,
        'user_id': user.id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'is_veg': isVeg,
        'is_available': isAvailable,
        'image_url': imageUrl,
        'times_sold': 0,        // Default value
        'total_earnings': 0.0,  // Default value
        'average_rating': 0.0,  // Default value
        'review_count': 0,      // Default value
      });
      // --- END OF UPDATE ---

      clearImage();
      return null;
    } catch (e) {
      debugPrint('Add Product Error: $e');
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String category,
    required bool isVeg,
    required bool isAvailable,
    String? oldImageUrl,
  }) async {
    _setLoading(true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'User is not authenticated.';

      String? newImageUrl = oldImageUrl;

      if (_pickedImage != null) {
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          try {
            final pathToRemove = Uri.parse(oldImageUrl).pathSegments.last;
            await _client.storage.from('product_images').remove(['${user.id}/$pathToRemove']);
          } catch (e) {
            debugPrint("Could not delete old image: $e");
          }
        }
        newImageUrl = await _uploadImage(_pickedImage!, user.id);
      }

      await _client.from('products').update({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'is_veg': isVeg,
        'is_available': isAvailable,
        'image_url': newImageUrl,
      }).eq('id', productId);

      clearImage();
      return null;
    } catch (e) {
      debugPrint('Update Product Error: $e');
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      return await _client.from('products').select('*').eq('user_id', user.id).order('created_at', ascending: false);
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<String?> deleteProduct(String productId, String? imageUrl) async {
    _setLoading(true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'User is not authenticated.';

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final pathToRemove = Uri.parse(imageUrl).pathSegments.last;
          await _client.storage.from('product_images').remove(['${user.id}/$pathToRemove']);
        } catch (e) {
          debugPrint("Could not delete image: $e");
        }
      }

      await _client.from('products').delete().eq('id', productId);
      return null;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return 'Failed to delete product.';
    } finally {
      _setLoading(false);
    }
  }
}
