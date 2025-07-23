import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../provider/buyer/chat_provider.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String productName;
  final String sellerName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.productName,
    required this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: _ChatScreenContent(
        chatId: chatId,
        productName: productName,
        sellerName: sellerName,
      ),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final String chatId;
  final String productName;
  final String sellerName;

  const _ChatScreenContent({
    required this.chatId,
    required this.productName,
    required this.sellerName,
  });

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // --- THE FIX: Use a post-frame callback ---
    // This delays the data fetching until after the first build is complete,
    // which prevents the '!_dirty' error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.fetchMessages(widget.chatId).then((_) {
        // Ensure the widget is still in the tree before subscribing
        if (mounted) {
          provider.subscribeToMessages(widget.chatId);
        }
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // The provider's dispose method will handle cancelling the subscription
    super.dispose();
  }

  void _sendMessage() {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    if (_messageController.text.trim().isNotEmpty) {
      provider.sendMessage(widget.chatId, _messageController.text);
      _messageController.clear();
      // Animate to the bottom of the list after sending
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sellerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('re: ${widget.productName}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              // --- UI IMPROVEMENT: Reverse the list for a natural chat UI ---
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final message = provider.messages[index];
                final isMe = message['sender_id'] == currentUserId;
                return _buildMessageBubble(message['content'], isMe);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepOrangeAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ],
        ),
        child: Text(
          content,
          style: GoogleFonts.poppins(color: isMe ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.deepOrangeAccent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
