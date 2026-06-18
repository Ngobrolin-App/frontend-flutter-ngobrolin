import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/providers/socket_provider.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:ngobrolin_app/core/widgets/states/empty_state.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/chat/chat_list_view_model.dart';
import '../../../core/widgets/cards/chat_list_item.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import 'dart:developer' as developer;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ScrollController _scrollController;

  // Socket Handlers disederhanakan tanpa late init ambigu
  Function(dynamic)? _conversationUpdatedHandler;
  Function(dynamic)? _conversationCreatedHandler;
  Function(dynamic)? _conversationReadHandler;

  // Diubah menjadi nullable untuk mengantisipasi eksekusi dispose dini
  SocketProvider? _socketProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Pendaftaran listener scroll dipindah & dioptimasi langsung
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initChatListAndSockets();
    });
  }

  void _initChatListAndSockets() {
    final chatListViewModel = Provider.of<ChatListViewModel>(
      context,
      listen: false,
    );
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // SOLUSI: Ambil instansiasi di post-frame secara aman
    _socketProvider = Provider.of<SocketProvider>(context, listen: false);

    chatListViewModel.fetchChatList();

    // Definisikan Handlers
    _conversationUpdatedHandler = (data) {
      developer.log(
        '-------- conversation_updated: $data',
        name: 'ChatListScreen',
      );
      final currentUserId = authViewModel.user?.id;
      chatListViewModel.handleSocketConversationUpdate(data, currentUserId);
    };

    _conversationCreatedHandler = (data) {
      developer.log(
        '-------- conversation_created: $data',
        name: 'ChatListScreen',
      );
      chatListViewModel.fetchChatList();
    };

    _conversationReadHandler = (data) {
      try {
        final convId = data['conversationId'] as String?;
        if (convId != null) {
          chatListViewModel.handleConversationReadByMe(convId);
        }
      } catch (e) {
        developer.log(
          'Error conversation read handler: $e',
          name: 'ChatListScreen',
        );
      }
    };

    // Daftarkan Handlers ke Socket
    _socketProvider?.on('conversation_updated', _conversationUpdatedHandler!);
    _socketProvider?.on('conversation_created', _conversationCreatedHandler!);
    _socketProvider?.on('conversation_read_by_me', _conversationReadHandler!);
  }

  void _onScroll() {
    final vm = Provider.of<ChatListViewModel>(context, listen: false);
    // OPTIMASI: Cegah double fetch jika view model sedang dalam keadaan loading
    if (!vm.isLoading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      vm.loadMoreChatList();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // SOLUSI: Gunakan null-safe handling saat membersihkan socket listener
    if (_socketProvider != null) {
      try {
        if (_conversationUpdatedHandler != null) {
          _socketProvider!.off(
            'conversation_updated',
            _conversationUpdatedHandler,
          );
        }
        if (_conversationCreatedHandler != null) {
          _socketProvider!.off(
            'conversation_created',
            _conversationCreatedHandler,
          );
        }
        if (_conversationReadHandler != null) {
          _socketProvider!.off(
            'conversation_read_by_me',
            _conversationReadHandler,
          );
        }
      } catch (e) {
        developer.log(
          'Error removing socket listeners: $e',
          name: 'ChatListScreen',
        );
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      // OPTIMASI: Gunakan Consumer secara spesifik hanya pada area list data yang reaktif
      body: Consumer<ChatListViewModel>(
        builder: (context, chatListViewModel, _) {
          final chatList = chatListViewModel.chatList;

          if (chatListViewModel.isLoading && chatList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatList.isEmpty) {
            return EmptyState(
              title: context.tr('no_chats'),
              showButton: true,
              buttonText: context.tr('start_new_chat'),
              onButtonPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.main, arguments: {'tabIndex': 1});
              },
            );
          }

          return ListView.separated(
            controller: _scrollController,
            itemCount: chatList.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final chat = chatList[index];
              return ChatListItem(
                chat: chat,
                onTap: () {
                  chatListViewModel.markChatAsRead(chat.id);
                  Navigator.of(context).pushNamed(
                    AppRoutes.chat,
                    arguments: {
                      'userId': chat.userId,
                      'name': chat.name,
                      'avatarUrl': chat.avatarUrl,
                      'chatId': chat.id,
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
            arguments: {'tabIndex': 1},
          );
        },
        backgroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: Iconify(Mdi.message_plus, color: AppColors.white),
      ),
    );
  }
}
