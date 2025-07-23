import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorChatProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetches all chat conversations for the current vendor
  Future<List<Map<String, dynamic>>> getMyChats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // --- FIX: Fetch data in two steps to work around the missing DB relationship ---

      // 1. Fetch the chats and the product name. We remove the problematic join on 'buyer_id' for now.
      final chatData = await _client
          .from('chats')
          .select('*, product:product_id(name, image_url)') // Also get product image
          .eq('seller_id', userId)
          .order('last_message_at', ascending: false);

      // 2. Manually fetch the buyer's name for each chat.
      // This is less efficient but will prevent the app from crashing.
      for (var chat in chatData) {
        final buyerId = chat['buyer_id'];
        if (buyerId != null) {
          try {
            final buyerData = await _client
                .from('users')
                .select('full_name')
                .eq('id', buyerId)
                .single();
            // Add the buyer data into the chat map.
            chat['buyer'] = buyerData;
          } catch (e) {
            // If a buyer is not found, add a placeholder.
            chat['buyer'] = {'full_name': 'Unknown Buyer'};
          }
        }
      }

      return chatData;

    } catch (e) {
      debugPrint("Error fetching vendor chats: $e");
      // Rethrow the exception so the UI can display a helpful error message.
      rethrow;
    }
  }

  // Checks if the vendor has any unread chats
  Future<bool> hasUnreadChats() async {
    final chats = await getMyChats();
    for (var chat in chats) {
      if ((chat['seller_unread_count'] ?? 0) > 0) {
        return true;
      }
    }
    return false;
  }

  // Marks a specific chat as read for the vendor
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _client
          .from('chats')
          .update({'seller_unread_count': 0})
          .eq('id', chatId);
    } catch (e) {
      debugPrint("Error marking chat as read for vendor: $e");
    }
  }
}
