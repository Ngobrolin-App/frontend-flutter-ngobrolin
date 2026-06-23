import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ngobrolin_app/core/widgets/states/empty_state.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/socket_provider.dart';
import '../../core/viewmodels/chat/chat_view_model.dart';
import '../../core/viewmodels/settings/settings_view_model.dart';
import '../../core/widgets/cards/chat_bubble.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'dart:developer' as developer;

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String userId;
  final String name;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _joinedRoom = false;
  bool _isInit = false;
  int _lastMessageCount = 0;
  Timer? _typingTimer;

  // Socket Handlers
  late Function(dynamic) _newMessageHandler;
  late Function(dynamic) _readStatusHandler;
  late Function(dynamic) _conversationCreatedHandler;
  late Function(dynamic) _typingHandler;
  late Function(dynamic) _stopTypingHandler;
  late Function(dynamic) _statusHandler;

  late ChatViewModel _chatViewModel;
  late AuthViewModel _authViewModel;
  late SettingsViewModel _settingsViewModel;
  late SocketProvider _socketProvider;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBlockStatusAndInitChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInit) {
      _chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      _settingsViewModel = Provider.of<SettingsViewModel>(
        context,
        listen: false,
      );
      _socketProvider = Provider.of<SocketProvider>(context, listen: false);
      _authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      _setupSocketHandlers();
      _isInit = true;
    }
  }

  // OPTIMASI: Ekstraksi listener anonim menjadi method terstruktur untuk mencegah leak
  void _onChatViewModelChanged() {
    if (!mounted) return;

    if (!_joinedRoom && _chatViewModel.conversationId != null) {
      _socketProvider.joinConversation(_chatViewModel.conversationId!);
      _joinedRoom = true;
    }

    final count = _chatViewModel.messages.length;
    if (count != _lastMessageCount) {
      _lastMessageCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _checkBlockStatusAndInitChat() async {
    try {
      final isBlocked = await _settingsViewModel.isUserBlocked(widget.userId);
      if (!mounted)
        return; // Pelindung utama jika user keburu menekan tombol back

      if (isBlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('user_is_blocked_cannot_start_chat')),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      _chatViewModel.initChat(
        conversationId: widget.chatId,
        userId: widget.userId,
        name: widget.name,
        avatarUrl: widget.avatarUrl,
      );

      _chatViewModel.addListener(_onChatViewModelChanged);

      if (_chatViewModel.conversationId != null && !_joinedRoom) {
        _socketProvider.joinConversation(_chatViewModel.conversationId!);
        _joinedRoom = true;
      }

      _scrollToBottom();
    } catch (e) {
      developer.log('Error initializing chat: $e', name: 'ChatScreen');
    }
  }

  void _setupSocketHandlers() {
    _newMessageHandler = (data) {
      developer.log(
        'ChatScreen - _setupSocketHandlers - _newMessageHandler data: $data',
        name: 'ChatScreen',
      );
      try {
        final msgMap = data['message'] as Map<String, dynamic>;
        final convId = msgMap['conversationId'] as String?;

        if (convId != null && convId == _chatViewModel.conversationId) {
          _chatViewModel.handleIncomingMessage(msgMap);

          final senderId = msgMap['senderId']?.toString();
          final msgId = msgMap['id']?.toString();

          if (senderId != _authViewModel.user?.id && msgId != null) {
            _chatViewModel.markMessageAsRead(msgId);
          }
        }
      } catch (_) {}
    };

    _readStatusHandler = (data) {
      try {
        final convId = data['conversationId'] as String?;
        if (convId != null && convId == _chatViewModel.conversationId) {
          final ids = (data['messageIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
          _chatViewModel.updateMessagesReadStatus(ids);
        }
      } catch (_) {}
    };

    _conversationCreatedHandler = (data) {
      try {
        final conv = data['conversation'] as Map<String, dynamic>?;
        if (conv == null) return;

        final participantsRaw = (conv['participants'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final myId = _authViewModel.user?.id;
        final isMeIncluded = participantsRaw.any(
          (p) => (p['id']?.toString() ?? '') == myId,
        );
        final isPartnerIncluded = participantsRaw.any(
          (p) => (p['id']?.toString() ?? '') == widget.userId,
        );

        if (isMeIncluded && isPartnerIncluded) {
          final convId = conv['id'] as String?;
          if (convId != null) {
            _chatViewModel.setConversationId(convId);
            _socketProvider.joinConversation(convId);
            _joinedRoom = true;
          }
        }
      } catch (_) {}
    };

    _typingHandler = (data) {
      try {
        if (data['conversationId'] == _chatViewModel.conversationId &&
            data['userId'] == widget.userId) {
          _chatViewModel.setPartnerTyping(true);
        }
      } catch (_) {}
    };

    _stopTypingHandler = (data) {
      try {
        if (data['conversationId'] == _chatViewModel.conversationId &&
            data['userId'] == widget.userId) {
          _chatViewModel.setPartnerTyping(false);
        }
      } catch (_) {}
    };

    _statusHandler = (data) {
      try {
        final userId = data['userId'] as String?;
        final status = data['status'] as String?;
        if (userId == widget.userId && status != null) {
          _chatViewModel.setPartnerStatus(status);
        }
      } catch (_) {}
    };

    _socketProvider.on('new_message', _newMessageHandler);
    _socketProvider.on('messages_read_status_updated', _readStatusHandler);
    _socketProvider.on('conversation_created', _conversationCreatedHandler);
    _socketProvider.on('user_typing', _typingHandler);
    _socketProvider.on('user_stopped_typing', _stopTypingHandler);
    _socketProvider.on('user_status_changed', _statusHandler);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();

    if (_isInit) {
      if (_chatViewModel.conversationId != null) {
        _socketProvider.leaveConversation(_chatViewModel.conversationId!);
      }

      try {
        _socketProvider.off('new_message', _newMessageHandler);
        _socketProvider.off('messages_read_status_updated', _readStatusHandler);
        _socketProvider.off(
          'conversation_created',
          _conversationCreatedHandler,
        );
        _socketProvider.off('user_typing', _typingHandler);
        _socketProvider.off('user_stopped_typing', _stopTypingHandler);
        _socketProvider.off('user_status_changed', _statusHandler);
      } catch (e) {
        developer.log(
          'ChatScreen - Error unregistering socket: $e',
          name: 'ChatScreen',
        );
      }

      _chatViewModel.removeListener(_onChatViewModelChanged);
    }

    super.dispose();
  }

  void _onTextChanged() {
    if (_chatViewModel.conversationId == null) return;

    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();

    _socketProvider.sendTypingStart(_chatViewModel.conversationId!);

    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _chatViewModel.conversationId != null) {
        _socketProvider.sendTypingStop(_chatViewModel.conversationId!);
      }
    });
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
      final success = await _chatViewModel.sendMessage(message);
      if (success) {
        _messageController.clear();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('failed_to_send_message')}: $e'),
          backgroundColor: AppColors.warning,
        ),
      );
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
              arguments: {'userId': context.read<ChatViewModel>().partnerId},
            );
          },
          child: Row(
            children: [
              // OPTIMASI: Ambil avatar menggunakan Selector agar tidak rebuild jika isi chat bertambah
              Selector<ChatViewModel, String?>(
                selector: (_, vm) => vm.partnerAvatarUrl,
                builder: (context, avatarUrl, _) {
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Selector<ChatViewModel, String>(
                            selector: (_, vm) => vm.partnerName,
                            builder: (context, name, _) => Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Selector<ChatViewModel, String>(
                    selector: (_, vm) => vm.partnerName,
                    builder: (context, name, _) => Text(name),
                  ),
                  // OPTIMASI: Lokalisasi rebuild sub-komponen status/typing via Selector
                  Selector<ChatViewModel, (bool, String)>(
                    selector: (_, vm) => (vm.isPartnerTyping, vm.partnerStatus),
                    builder: (context, state, _) {
                      final isTyping = state.$1;
                      final status = state.$2;
                      if (isTyping) {
                        return Text(
                          '${context.tr('typing')}...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      } else if (status == 'online') {
                        return Text(
                          context.tr('online'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') _showBlockDialog(context);
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
          Expanded(
            child: Selector<ChatViewModel, bool>(
              selector: (_, vm) => vm.isLoading,
              builder: (context, isLoading, _) {
                return Consumer<ChatViewModel>(
                  builder: (context, chatVM, _) {
                    final messages = chatVM.messages;
                    final myId = _authViewModel.user?.id;

                    if (isLoading && messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (messages.isEmpty) {
                      return EmptyState(
                        title: context.tr('no_messages'),
                        subtitle: context.tr('start_new_chat'),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = myId != null && message.senderId == myId;
                        return ChatBubble(message: message, isMe: isMe);
                      },
                    );
                  },
                );
              },
            ),
          ),
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
                IconButton(
                  icon: Iconify(
                    MaterialSymbols.attach_file,
                    color: AppColors.grey,
                  ),
                  onPressed: () => _handleAttachment(context),
                ),
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
                Selector<ChatViewModel, bool>(
                  selector: (_, vm) => vm.isLoading,
                  builder: (context, isLoading, _) {
                    return IconButton(
                      icon: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : Iconify(
                              MaterialSymbols.send_rounded,
                              color: AppColors.accent,
                            ),
                      onPressed: isLoading ? null : _sendMessage,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachment(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(ctx, 'image'),
                child: Row(
                  children: [
                    const Icon(Icons.image),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.tr('choose_image'))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(ctx, 'file'),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.tr('choose_file'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || choice == null) return;

    final chatVM = Provider.of<ChatViewModel>(context, listen: false);

    if (choice == 'image') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        await chatVM.sendAttachment(picked.path, 'image');
        _scrollToBottom();
      }
    } else if (choice == 'file') {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = result?.files.first.path;
      if (path != null && mounted) {
        await chatVM.sendAttachment(path, 'file');
        _scrollToBottom();
      }
    }
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('block_account')),
        content: Text(context.tr('are_you_sure_block')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('no')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
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
    _settingsViewModel.blockAccount(widget.userId).then((success) {
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                _settingsViewModel.successMessage ??
                    'user_blocked_successfully',
              ),
            ),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                _settingsViewModel.errorMessage ?? 'failed_to_block_user',
              ),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    });
  }
}
