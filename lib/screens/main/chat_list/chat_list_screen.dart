import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/cards/chat_list_item.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Mock data for chat list
  final List<Map<String, dynamic>> _chatList = [
    {
      'id': '1',
      'name': 'John Doe',
      'avatarUrl': null,
      'lastMessage': 'Hey, how are you doing?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'unreadCount': 2,
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'avatarUrl': null,
      'lastMessage': 'See you tomorrow!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'unreadCount': 0,
    },
    {
      'id': '3',
      'name': 'Mike Johnson',
      'avatarUrl': null,
      'lastMessage': 'Thanks for your help!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'unreadCount': 0,
    },
    {
      'id': '4',
      'name': 'Sarah Williams',
      'avatarUrl': null,
      'lastMessage': 'Can we meet tomorrow?',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('chats')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settingsRoute);
            },
          ),
        ],
      ),
      body: _chatList.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              itemCount: _chatList.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final chat = _chatList[index];
                return ChatListItem(
                  id: chat['id'],
                  name: chat['name'],
                  avatarUrl: chat['avatarUrl'],
                  lastMessage: chat['lastMessage'],
                  timestamp: chat['timestamp'],
                  unreadCount: chat['unreadCount'],
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.chat,
                      arguments: {
                        'userId': chat['id'],
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
        child: const Icon(Icons.add),
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
