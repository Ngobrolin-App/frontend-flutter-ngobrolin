import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';

import '../../models/chat_list_item_model.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for managing the conversation list, handling pagination,
/// and reactive real-time socket events for inbox updates.
class ChatListViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  static const String _logName = 'ChatListViewModel';

  List<ChatListItemModel> _chatList = [];
  List<ChatListItemModel> get chatList => _chatList;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

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

    return await runBusyFuture(
          () async {
            final result = await _chatRepository.getConversationList(
              page: _page,
              limit: _limit,
            );

            final paginatedResult = result.data;
            _chatList = paginatedResult?.items ?? [];
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          },
          logName: _logName,
          logContext: 'fetchChatList()',
        ) ??
        false;
  }

  /// Appends older conversations to the active list when scrolling down (Infinite Scroll).
  Future<bool> loadMoreChatList() async {
    if (!_hasMore || _isLoadingMore) return false;

    _isLoadingMore = true;
    notifyListeners();

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
          (paginatedResult?.page ?? 0) < (paginatedResult?.totalPages ?? 0);

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'loadMoreChatList() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());
      _page = (_page > 1) ? _page - 1 : 1;
      return false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Implements optimistic updates to clear unread counts instantly and synchronization over the API network.
  Future<void> markChatAsRead(String conversationId) async {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index == -1) return;

      final oldChat = _chatList[index];
      _chatList[index] = oldChat.copyWith(unreadCount: 0);
      notifyListeners();

      final lastMessage = oldChat.lastMessage;
      if (lastMessage != null && lastMessage.id.isNotEmpty) {
        await _chatRepository.markAsRead(
          conversationId: conversationId,
          messageId: lastMessage.id,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'markChatAsRead() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());
    }
  }

  /// Event listener proxy callback bound to socket event pipelines for 'conversation_updated'.
  void handleSocketConversationUpdate(dynamic data, String? currentUserId) {
    try {
      final conversationId = data['conversationId'] as String?;
      if (conversationId == null) return;

      final rawLastMessage = data['lastMessage'] as Map<String, dynamic>?;
      final rawUpdatedConversation =
          data['updatedConversation'] as Map<String, dynamic>?;

      MessageModel? lastMessage =
          (rawLastMessage != null && rawLastMessage.isNotEmpty)
          ? MessageModel.fromJson(rawLastMessage)
          : null;

      ConversationModel? updatedConversation =
          (rawUpdatedConversation != null && rawUpdatedConversation.isNotEmpty)
          ? ConversationModel.fromJson(rawUpdatedConversation)
          : null;

      if (lastMessage != null || updatedConversation != null) {
        final unreadCount = data['unreadCount'] as int?;
        updateWithNewMessage(
          conversationId,
          currentUserId: currentUserId,
          lastMessage: lastMessage,
          unreadCount: unreadCount,
          updatedConversation: updatedConversation,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'handleSocketConversationUpdate() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());
    }
  }

  Future<void> updateWithNewMessage(
    String chatId, {
    String? currentUserId,
    MessageModel? lastMessage,
    int? unreadCount,
    ConversationModel? updatedConversation,
  }) async {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == chatId);

      if (index != -1) {
        final oldChat = _chatList[index];

        _chatList[index] = oldChat.copyWith(
          lastMessage: lastMessage ?? oldChat.lastMessage,
          unreadCount: unreadCount ?? oldChat.unreadCount,
          groupImage: updatedConversation?.groupImage ?? oldChat.groupImage,
          name: updatedConversation?.name ?? oldChat.name,
        );

        // Re-sort current lists
        _chatList.sort((a, b) {
          final timestampA = a.lastMessage?.createdAt;
          final timestampB = b.lastMessage?.createdAt;

          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;

          return timestampB.compareTo(timestampA);
        });

        notifyListeners();
        return;
      }

      // If the chat block is non-existent in the current viewport
      await fetchChatList();
    } catch (e, stackTrace) {
      developer.log(
        'updateWithNewMessage() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());
    }
  }

  void handleSocketConversationReadByMe(String conversationId) {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index != -1) {
        _chatList[index] = _chatList[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e, stackTrace) {
      developer.log(
        'handleSocketConversationReadByMe() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());
    }
  }

  void handleConversationMessagesStatusUpdated(
    String conversationId,
    List<String> messageIds,
  ) {
    try {
      if (messageIds.isEmpty || conversationId.isEmpty) return;
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index != -1) {
        final lastMessage = _chatList[index].lastMessage;
        final lastMessageId = lastMessage?.id;

        if (messageIds.contains(lastMessageId)) {
          final newLastMessage = lastMessage?.copyWith(isRead: true);
          _chatList[index] = _chatList[index].copyWith(
            lastMessage: newLastMessage,
          );
        }
        notifyListeners();
      }
    } catch (e, stackTrace) {
      developer.log(
        'handleConversationMessagesStatusUpdated() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());
    }
  }

  void handleConversationUserTypingToggle(
    String conversationId,
    String userName,
    bool isTyping,
  ) {
    try {
      if (conversationId.isEmpty || userName.isEmpty) return;
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index != -1) {
        _chatList[index] = _chatList[index].copyWith(
          isTyping: isTyping,
          typingUserName: isTyping ? userName : null,
        );

        notifyListeners();
      }
    } catch (e, stackTrace) {
      developer.log(
        'handleConversationUserTypingToggle() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());
    }
  }
}
