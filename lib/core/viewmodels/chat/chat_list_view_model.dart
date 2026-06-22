import 'package:ngobrolin_app/core/models/message_model.dart';

import '../../models/chat_list_item_model.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for managing the conversation list, handling pagination,
/// and reactive real-time socket events for inbox updates.
class ChatListViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  List<ChatListItemModel> _chatList = [];
  List<ChatListItemModel> get chatList => _chatList;

  // Pagination states
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  ChatListViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  /// Fetches the initial list of conversations from the API server.
  /// Resets pagination states back to page 1.
  Future<bool> fetchChatList() async {
    _page = 1;
    _hasMore = true;
    _chatList = [];

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.getConversationList(
              page: _page,
              limit: _limit,
            );

            final paginatedResult = result.data;
            final conversationList = paginatedResult?.items ?? [];

            _chatList = conversationList;
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              'ChatListViewModel - fetchChatList() error: $e',
              name: 'ChatListViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Appends older conversations to the active list when scrolling down (Infinite Scroll).
  Future<bool> loadMoreChatList() async {
    // Prevent duplicated API requests if there is no more data or the channel is busy
    if (!_hasMore || isLoading) return false;

    return await runBusyFuture(() async {
          try {
            _page += 1;
            final result = await _chatRepository.getConversationList(
              page: _page,
              limit: _limit,
            );

            final paginatedResult = result.data;
            final conversationList = paginatedResult?.items ?? [];

            _chatList.addAll(conversationList);
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              'ChatListViewModel - loadMoreChatList() error: $e',
              name: 'ChatListViewModel',
            );
            setError(e.toString());
            _page -= 1; // Rollback page index on network failure
            return false;
          }
        }) ??
        false;
  }

  /// Implements optimistic updates to clear unread counts instantly and synchronization over the API network.
  void markChatAsRead(String conversationId) async {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index == -1) return;

      final chat = _chatList[index];

      // Optimistic UI update for swift interface feedback loops
      _chatList[index] = chat.copyWith(unreadCount: 0);
      notifyListeners();

      final lastMessage = chat.lastMessage;
      if (lastMessage != null) {
        if (lastMessage.id.isNotEmpty) {
          await _chatRepository.markAsRead(
            conversationId: conversationId,
            messageId: lastMessage.id,
          );
        }
      }
    } catch (e) {
      developer.log(
        'ChatListViewModel - markChatAsRead() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }

  /// Event listener proxy callback bound to socket event pipelines for 'conversation_updated'.
  void handleSocketConversationUpdate(dynamic data, String? currentUserId) {
    try {
      final conversationId = data['conversationId'] as String?;
      final rawLastMessage = data['lastMessage'] as Map<String, dynamic>? ?? {};

      final lastMessage = MessageModel.fromJson(rawLastMessage);
      if (conversationId != null) {
        final unreadCount = data['unreadCount'] as int;

        updateWithNewMessage(
          conversationId,
          currentUserId: currentUserId,
          lastMessage: lastMessage,
          unreadCount: unreadCount,
        );
      }
    } catch (e) {
      developer.log(
        'ChatListViewModel - handleSocketConversationUpdate() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }

  /// Updates or realigns a conversation block within the inbox layout upon receiving a new message payload.
  Future<void> updateWithNewMessage(
    String chatId, {
    String? currentUserId,
    MessageModel? lastMessage,
    int? unreadCount,
  }) async {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == chatId);
      if (index != -1) {
        final oldChat = _chatList[index];

        _chatList[index] = oldChat.copyWith(
          lastMessage: lastMessage,
          unreadCount: unreadCount,
        );

        // Re-sort current lists so that the freshest interaction rises to the top layout
        _chatList.sort((a, b) {
          final lastMessageA = a.lastMessage;
          final timestampA = lastMessageA?.createdAt;
          final lastMessageB = b.lastMessage;
          final timestampB = lastMessageB?.createdAt;

          // Jika salah satu atau keduanya null, anggap urutan tidak berubah (return 0)
          if (timestampA == null || timestampB == null) {
            return 0;
          }

          return timestampB.compareTo(timestampA);
        });

        notifyListeners();
        return;
      }

      // If the chat block is non-existent in the current paginated index viewport, fetch page 1 to update layout
      await fetchChatList();
    } catch (e) {
      developer.log(
        'ChatListViewModel - updateWithNewMessage() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }

  /// Event listener proxy callback bound to socket event pipelines for 'conversation_read_by_me'.
  void handleSocketConversationReadByMe(String conversationId) {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index != -1) {
        _chatList[index] = _chatList[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      developer.log(
        'ChatListViewModel - handleSocketConversationReadByMe() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }
}
