import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/chat/chat_list_view_model.dart';
import '../../../core/widgets/cards/chat_list_item.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch chat list when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatListViewModel = Provider.of<ChatListViewModel>(
        context,
        listen: false,
      );
      chatListViewModel.fetchChatList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatListViewModel = Provider.of<ChatListViewModel>(context);
    final chatList = chatListViewModel.chatList;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('chats')),
        actions: [
          IconButton(
            icon: Iconify(
              MaterialSymbols.settings_rounded,
              color: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settingsRoute);
            },
          ),
        ],
      ),
      body: chatListViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatList.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              itemCount: chatList.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final chat = chatList[index];
                return ChatListItem(
                  id: chat['id'],
                  name: chat['name'],
                  avatarUrl: chat['avatarUrl'],
                  lastMessage: chat['lastMessage'],
                  timestamp: DateTime.parse(chat['timestamp']),
                  unreadCount: chat['unreadCount'],
                  onTap: () {
                    // Mark chat as read when opened
                    chatListViewModel.markChatAsRead(chat['id']);

                    Navigator.of(context).pushNamed(
                      AppRoutes.chat,
                      arguments: {
                        'userId': chat['userId'],
                        'name': chat['name'],
                        'avatarUrl': chat['avatarUrl'],
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to search users screen with the intent to start a new chat
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.main, arguments: {'tabIndex': 1});
        },
        backgroundColor: AppColors.accent,
        shape: CircleBorder(),
        child: Iconify(Bx.bxs_message_rounded_add, color: AppColors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/empty_state/img-empty-state.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_chats'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('start_new_chat'),
            style: const TextStyle(fontSize: 16, color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to search users screen
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.main, arguments: {'tabIndex': 1});
            },
            icon: const Icon(Icons.add),
            label: Text(context.tr('start_new_chat')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
