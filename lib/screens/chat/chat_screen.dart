import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/socket_provider.dart';
import '../../core/viewmodels/chat/chat_view_model.dart';
import '../../core/viewmodels/settings/settings_view_model.dart';
import '../../core/widgets/cards/chat_bubble.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String? avatarUrl;

  const ChatScreen({Key? key, required this.userId, required this.name, this.avatarUrl})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _joinedRoom = false;
  VoidCallback? _vmListener;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);
      final socketProvider = Provider.of<SocketProvider>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Cek blokir (dua arah). Jika diblokir, jangan mulai chat.
      final isBlocked = await settingsViewModel.isUserBlocked(widget.userId);
      if (isBlocked) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('user_is_blocked_cannot_start_chat')),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      chatViewModel.initChat(widget.userId, widget.name, widget.avatarUrl);

      // Pasang listener: join room sekali dan auto-scroll saat jumlah pesan berubah
      _vmListener = () {
        if (!_joinedRoom && chatViewModel.conversationId != null) {
          socketProvider.joinConversation(chatViewModel.conversationId!);
          _joinedRoom = true;
        }

        final count = chatViewModel.messages.length;
        if (count != _lastMessageCount) {
          _lastMessageCount = count;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      };
      chatViewModel.addListener(_vmListener!);

      // Jika sudah ada conversationId sejak awal, join langsung
      if (chatViewModel.conversationId != null && !_joinedRoom) {
        socketProvider.joinConversation(chatViewModel.conversationId!);
        _joinedRoom = true;
      }

      // Scroll awal (akan diulang lagi saat pesan selesai dimuat)
      _scrollToBottom();

      // Join conversation room for realtime updates
      if (chatViewModel.conversationId != null) {
        socketProvider.joinConversation(chatViewModel.conversationId!);
      }

      // Listen to new_message events tanpa memfilter pesan dari diri sendiri
      socketProvider.on('new_message', (data) {
        debugPrint('-------- new_message on chat screen: $data');
        try {
          final msg = (data['message'] as Map<String, dynamic>);
          final convId = msg['conversation_id'] as String?;
          final senderId = msg['sender_id'] as String?;
          // final myId = authViewModel.user?.id; // tidak lagi digunakan untuk memfilter

          if (convId != null && convId == chatViewModel.conversationId) {
            chatViewModel.handleIncomingMessage({
              'id': msg['id'] ?? '',
              'senderId': senderId ?? '',
              'content': msg['content'] ?? '',
              'timestamp': msg['created_at'] ?? DateTime.now().toIso8601String(),
              'isRead': false,
            });
            _scrollToBottom();
          }
        } catch (_) {}
      });

      // Listen percakapan baru: jika melibatkan saya dan partner saat ini, set conversationId & join
      socketProvider.on('conversation_created', (data) {
        debugPrint('-------- conversation_created on chat screen: $data');
        try {
          final conv = data['conversation'] as Map<String, dynamic>?;
          if (conv == null) return;

          final participantsRaw = (conv['participants'] as List<dynamic>? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();
          final myId = authViewModel.user?.id;
          final isMeIncluded = participantsRaw.any((p) => (p['id']?.toString() ?? '') == myId);
          final isPartnerIncluded = participantsRaw.any(
            (p) => (p['id']?.toString() ?? '') == widget.userId,
          );

          if (isMeIncluded && isPartnerIncluded) {
            final convId = conv['id'] as String?;
            if (convId != null) {
              chatViewModel.setConversationId(convId);
              socketProvider.joinConversation(convId);
            }
          }
        } catch (_) {}
      });

      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // Tinggalkan room dan lepas listener untuk menghindari duplikasi
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    if (chatViewModel.conversationId != null) {
      socketProvider.leaveConversation(chatViewModel.conversationId!);
    }
    socketProvider.off('new_message');
    socketProvider.off('conversation_created');

    // Lepas listener ViewModel agar tidak bocor
    if (_vmListener != null) {
      chatViewModel.removeListener(_vmListener!);
      _vmListener = null;
    }

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

    try {
      // Get the ChatViewModel
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);

      // Kirim pesan via API (backend akan broadcast via socket)
      final success = await chatViewModel.sendMessage(message);

      print('-------- Success send message: $success');
      if (success) {
        _messageController.clear();

        // Hapus emit via socket untuk mencegah duplikasi di backend
        // socketProvider.sendMessage(conversationId: chatViewModel.conversationId!, content: message);
      }

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('failed_to_send_message')}: ${e.toString()}'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    final messages = chatViewModel.messages;
    // Ambil myId dari AuthViewModel untuk menentukan posisi bubble
    final authViewModel = Provider.of<AuthViewModel>(context);
    final myId = authViewModel.user?.id;

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
                backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
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
                    Iconify(Ic.round_block, color: AppColors.warning),
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
          // in build() -> Expanded(child: ...)
          Expanded(
            child: (chatViewModel.isLoading && messages.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      // Posisi kanan bila pengirim adalah user saat ini
                      final isMe = myId != null && message['senderId'] == myId;

                      return ChatBubble(
                        message: message['content'],
                        timestamp: DateTime.parse(message['timestamp']),
                        isMe: isMe,
                        isRead: message['isRead'] ?? false,
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: Iconify(MaterialSymbols.attach_file, color: AppColors.grey),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),

                // Send button
                IconButton(
                  icon: chatViewModel.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        )
                      : Iconify(MaterialSymbols.send_rounded, color: AppColors.accent),
                  onPressed: chatViewModel.isLoading ? null : _sendMessage,
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
          Image.asset('assets/empty_state/img-empty-state.png', width: 120, height: 120),
          const SizedBox(height: 16),
          Text(
            context.tr('no_messages'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('start_new_chat'),
            style: const TextStyle(fontSize: 16, color: AppColors.grey),
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('no'))),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _blockUser(context);
            },
            child: Text(context.tr('yes'), style: const TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _blockUser(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);

    // Block user using SettingsViewModel
    settingsViewModel.blockAccount(widget.userId, widget.name, widget.name).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.name} has been blocked'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block ${widget.name}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    });
  }
}
