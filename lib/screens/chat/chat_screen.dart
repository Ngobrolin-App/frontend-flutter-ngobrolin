import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/enums/reply_message_layout.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:ngobrolin_app/core/widgets/cards/reply_message.dart';
import 'package:ngobrolin_app/core/widgets/inputs/chat_input_bar.dart';
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
import 'image_preview_edit_screen.dart';

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
  Timer? _typingTimer;
  final GlobalKey _textBoxKey = GlobalKey();
  Map<String, GlobalKey> _messageKeys = {};

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
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBlockStatusAndInitChat();
    });
  }

  void _onScroll() {
    // Jika mencapai hampir ke atas (ingat: reverse=true, bawah = index 0)
    // maka sisa scroll akan berada di posisi maxScrollExtent
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final vm = Provider.of<ChatViewModel>(context, listen: false);
      if (!vm.isLoadingMore && vm.hasMore) {
        _chatViewModel
            .loadMoreMessages(); // Panggil method yang sudah Anda buat
      }
    }
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

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

    _scrollController.removeListener(_onScroll);
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
        _scrollController.position.minScrollExtent,
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

  void _scrollToRepliedMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5, // Menempatkan pesan di tengah layar
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
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        if (index == _chatViewModel.messages.length) {
                          // Tampilkan loading spinner di atas jika sedang memuat
                          return _chatViewModel.isLoadingMore
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        }
                        final message = messages[index];
                        final isMe = myId != null && message.senderId == myId;
                        final key = _messageKeys.putIfAbsent(
                          message.id,
                          () => GlobalKey(),
                        );
                        return ChatBubble(
                          key: key,
                          message: message,
                          isMe: isMe,
                          onReplyTap: (repliedMessageId) =>
                              _scrollToRepliedMessage(repliedMessageId),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Selector<ChatViewModel, (MessageModel?, bool)>(
            selector: (_, vm) => (vm.replyingToMessage, vm.isLoading),
            builder: (context, state, _) {
              final replyingTo = state.$1;
              final isLoading = state.$2;

              return ChatInputBar(
                controller: _messageController,
                hintText: context.tr("type_message"),
                isSending: isLoading,
                onSend: _sendMessage,
                onAttachment: () => _handleAttachment(context),
                onSubmitted: (_) => _sendMessage(),
                top: replyingTo == null
                    ? null
                    : ReplyMessageWidget(
                        message: replyingTo,
                        layout: ReplyMessageLayout.composer,
                        onTap: () => _scrollToRepliedMessage(replyingTo.id),
                        onClose: () {
                          context.read<ChatViewModel>().setReplyingTo(null);
                        },
                      ),
              );
            },
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
              // OPSI 1: KAMERA
              GestureDetector(
                onTap: () => Navigator.pop(ctx, 'camera'),
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(context.tr('take_photo') ?? 'Ambil Foto'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // OPSI 2: GALERI
              GestureDetector(
                onTap: () => Navigator.pop(ctx, 'image'),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.tr('choose_image'))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // OPSI 3: FILE
              GestureDetector(
                onTap: () => Navigator.pop(ctx, 'file'),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      color: AppColors.primary,
                    ),
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
    final picker = ImagePicker();
    String? pickedPath;

    if (choice == 'camera') {
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      pickedPath = picked?.path;
    } else if (choice == 'image') {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      pickedPath = picked?.path;
    } else if (choice == 'file') {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = result?.files.first.path;
      if (path != null && mounted) {
        await chatVM.sendAttachment(path, 'file');
        _scrollToBottom();
      }
      return; // Stop process di sini khusus file biasa
    }

    // JIKA GAMBAR BERHASIL DIAMBIL (DARI GALERI ATAU KAMERA)
    if (pickedPath != null && mounted) {
      // Arahkan ke halaman edit/preview simple terlebih dahulu
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewEditScreen(imagePath: pickedPath!),
        ),
      );
      if (result != null && result is Map) {
        final File editedFile = result['file'];
        final String caption = result['caption'];

        if (editedFile != null && mounted) {
          await chatVM.sendAttachment(editedFile.path, 'image');
          _scrollToBottom();
        }
      }
      // final File? editedFile = await Navigator.push<File?>(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ImagePreviewEditScreen(imagePath: pickedPath!),
      //   ),
      // );

      // Jika user menekan tombol kirim di halaman preview
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
