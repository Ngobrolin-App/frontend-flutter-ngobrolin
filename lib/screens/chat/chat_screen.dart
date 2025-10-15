import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/socket_provider.dart';
import '../../core/widgets/cards/chat_bubble.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String? avatarUrl;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.name,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Mock messages data
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'content': 'Hi there!',
      'senderId': 'current_user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'isRead': true,
    },
    {
      'id': '2',
      'content': 'Hello! How are you?',
      'senderId': 'other_user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 28)),
      'isRead': true,
    },
    {
      'id': '3',
      'content': 'I\'m doing great, thanks for asking. How about you?',
      'senderId': 'current_user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
      'isRead': true,
    },
    {
      'id': '4',
      'content': 'I\'m good too. Just working on some projects.',
      'senderId': 'other_user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 20)),
      'isRead': true,
    },
    {
      'id': '5',
      'content': 'That sounds interesting! What kind of projects?',
      'senderId': 'current_user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 18)),
      'isRead': true,
    },
    {
      'id': '6',
      'content': 'Mostly mobile app development using Flutter. It\'s really fun!',
      'senderId': 'other_user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'isRead': true,
    },
    {
      'id': '7',
      'content': 'That\'s awesome! I love Flutter too.',
      'senderId': 'current_user',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
      'isRead': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Add message to local list
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': message,
        'senderId': 'current_user',
        'timestamp': DateTime.now(),
        'isRead': false,
      };

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });

      // Send message via socket
      final socketProvider = Provider.of<SocketProvider>(context, listen: false);
      socketProvider.sendMessage(
        toUserId: widget.userId,
        content: message,
      );

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.userProfile,
              arguments: {
                'userId': widget.userId,
                'name': widget.name,
                'avatarUrl': widget.avatarUrl,
              },
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.lightGrey,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? Text(
                        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(widget.name),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    const Icon(Icons.block, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(context.tr('block_account')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['senderId'] == 'current_user';
                      
                      return ChatBubble(
                        message: message['content'],
                        timestamp: message['timestamp'],
                        isMe: isMe,
                        isRead: message['isRead'],
                      );
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Implement attachment functionality
                  },
                ),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: context.tr('type_message'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.lightGrey.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                
                // Send button
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : const Icon(Icons.send, color: AppColors.accent),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
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
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_messages'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('start_new_chat'),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('block_account')),
        content: Text(context.tr('are_you_sure_block')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('no')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _blockUser(context);
            },
            child: Text(
              context.tr('yes'),
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  void _blockUser(BuildContext context) {
    // TODO: Implement block user functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} has been blocked'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }
}