import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Finds an existing chat or creates a new one
  Future<String> getOrCreateChat(String productId, String sellerId) async {
    final buyerId = _client.auth.currentUser?.id;
    if (buyerId == null) throw 'User not logged in';

    // Check if a chat already exists
    var chat = await _client
        .from('chats')
        .select('id')
        .eq('product_id', productId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (chat != null) {
      return chat['id'];
    } else {
      // Create a new chat if one doesn't exist
      final newChat = await _client.from('chats').insert({
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
      }).select('id').single();
      return newChat['id'];
    }
  }

  // Fetches initial messages for a chat room
  Future<void> fetchMessages(String chatId) async {
    _setLoading(true);
    try {
      final data = await _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
      // --- FIX: Order descending to get newest messages first ---
          .order('created_at', ascending: false);
      _messages = data;
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Listens for new messages in real-time
  void subscribeToMessages(String chatId) {
    _messageSubscription = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .listen((data) {
      // Since the stream might not be ordered, we sort it ourselves
      data.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
      _messages = data;
      notifyListeners();
    });
  }

  // Sends a new message
  Future<void> sendMessage(String chatId, String content) async {
    final senderId = _client.auth.currentUser?.id;
    if (senderId == null || content.trim().isEmpty) return;

    try {
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content.trim(),
      });
      // Also update the last message time for the chat
      await _client
          .from('chats')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
