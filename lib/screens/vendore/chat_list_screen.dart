import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../provider/vendore/vendore_chat_provider.dart';
import '../foodlover/chat_screen_fd_lvr.dart';

class VendorChatsListScreen extends StatefulWidget {
  const VendorChatsListScreen({super.key});

  @override
  State<VendorChatsListScreen> createState() => _VendorChatsListScreenState();
}

class _VendorChatsListScreenState extends State<VendorChatsListScreen> {
  late Future<List<Map<String, dynamic>>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to safely call the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
    });
  }

  void _loadChats() {
    final provider = Provider.of<VendorChatProvider>(context, listen: false);
    setState(() {
      _chatsFuture = provider.getMyChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VendorChatProvider(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('Customer Chats', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _chatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final chats = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _loadChats(),
              child: ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                itemBuilder: (context, index) {
                  return _buildChatListItem(context, chats[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, Map<String, dynamic> chat) {
    final vendorChatProvider = Provider.of<VendorChatProvider>(context, listen: false);

    final unreadCount = chat['seller_unread_count'] ?? 0;
    final hasUnread = unreadCount > 0;

    // Extract nested data safely
    final buyerName = (chat['buyer'] as Map<String, dynamic>?)?['full_name'] ?? 'Customer';
    final productName = (chat['product'] as Map<String, dynamic>?)?['name'] ?? 'a product';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        child: Text(
          buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'C',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepOrangeAccent),
        ),
      ),
      title: Text(
        buyerName,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        're: $productName - ${chat['last_message_content'] ?? 'No messages yet.'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: hasUnread ? Colors.black87 : Colors.grey[600],
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: hasUnread
          ? CircleAvatar(
        radius: 12,
        backgroundColor: Colors.deepOrangeAccent,
        child: Text(
          unreadCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      )
          : null,
      onTap: () async {
        await vendorChatProvider.markChatAsRead(chat['id']);

        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat['id'],
            productName: productName,
            // The "seller" from the vendor's perspective is the buyer
            sellerName: buyerName,
          ),
        )).then((_) {
          // Refresh the list when returning from the chat screen
          _loadChats();
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No Customer Chats Yet', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600)),
          Text('Your conversations with customers will appear here.', style: GoogleFonts.poppins(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
