import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/providers/socket_provider.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/chat/chat_list_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/chat_list_item.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatListViewModel = Provider.of<ChatListViewModel>(context, listen: false);
      final socketProvider = Provider.of<SocketProvider>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      chatListViewModel.fetchChatList();

      // Realtime: update last message pada chat list
      socketProvider.on('conversation_updated', (data) {
        debugPrint('-------- conversation_updated on chat list screen: $data');
        try {
          final conversationId = data['conversationId'] as String?;
          final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
          if (conversationId != null && lastMessage != null) {
            final content = lastMessage['content'] as String? ?? '';
            final createdAt =
                lastMessage['created_at'] as String? ?? DateTime.now().toIso8601String();
            final senderId = lastMessage['sender_id']?.toString();
            final currentUserId = authViewModel.user?.id;
            final lastMessageId = lastMessage['id']?.toString();

            chatListViewModel.updateWithNewMessage(
              conversationId,
              content,
              createdAt,
              senderId: senderId,
              currentUserId: currentUserId,
              lastMessageId: lastMessageId,
            );
          }
        } catch (_) {}
      });

      // Realtime: percakapan baru → refresh list agar muncul
      socketProvider.on('conversation_created', (data) {
        debugPrint('-------- conversation_created on chat list screen: $data');
        chatListViewModel.fetchChatList();
      });
    });

    _scrollController.addListener(() {
      final vm = Provider.of<ChatListViewModel>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        vm.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    socketProvider.off('conversation_updated');
    socketProvider.off('conversation_created');
    super.dispose();
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
            icon: Iconify(MaterialSymbols.settings_rounded, color: AppColors.white),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settingsRoute);
            },
          ),
        ],
      ),
      body: chatListViewModel.isLoading && chatList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : chatList.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              controller: _scrollController,
              itemCount: chatList.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
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
          Navigator.of(context).pushNamed(AppRoutes.main, arguments: {'tabIndex': 1});
        },
        backgroundColor: AppColors.accent,
        shape: CircleBorder(),
        child: Iconify(Mdi.message_plus, color: AppColors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/empty_state/img-empty-state.png', width: 150, height: 150),
          const SizedBox(height: 16),
          Text(
            context.tr('no_chats'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            text: context.tr('start_new_chat'),
            onPressed: () {
              // Navigate to search users screen
              Navigator.of(context).pushNamed(AppRoutes.main, arguments: {'tabIndex': 1});
            },
            icon: const Iconify(MaterialSymbols.add_rounded, color: Colors.white),
            isFullWidth: false,
          ),
        ],
      ),
    );
  }
}
