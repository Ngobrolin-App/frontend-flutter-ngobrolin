import '../../models/chat_list_item_model.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

class ChatListViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  // Gunakan List<ChatListItemModel> alih-alih List<Map<String, dynamic>> untuk tipe data yang kuat
  List<ChatListItemModel> _chatList = [];
  List<ChatListItemModel> get chatList => _chatList;

  // Pagination state
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  ChatListViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  /// Fetches the list of chats from the API (backend + pagination)
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

  /// Updates the chat list with a new message
  Future<void> updateWithNewMessage(
    String chatId,
    String message,
    String timestamp, {
    String? senderId,
    String? currentUserId,
    String? lastMessageId,
    String? type,
  }) async {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == chatId);
      if (index != -1) {
        // Update existing chat
        final oldChat = _chatList[index];

        // Dedup berdasarkan lastMessageId (jika tersedia)
        if (lastMessageId != null && oldChat.lastMessageId == lastMessageId) {
          return;
        }

        // Increment unread only if message is not from current user
        final shouldIncrementUnread =
            senderId == null ||
            currentUserId == null ||
            senderId != currentUserId;

        final newUnreadCount = shouldIncrementUnread
            ? oldChat.unreadCount + 1
            : oldChat.unreadCount;

        _chatList[index] = oldChat.copyWith(
          lastMessage: message,
          lastMessageId: lastMessageId,
          lastMessageType: type ?? 'text',
          timestamp: DateTime.parse(timestamp),
          unreadCount: newUnreadCount,
        );

        // Sort chats by timestamp (newest first)
        _chatList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        notifyListeners();
        return;
      }

      // Jika percakapan belum ada di list (chat baru atau bukan di halaman saat ini),
      // reload halaman pertama untuk memunculkan update.
      await fetchChatList();
    } catch (e) {
      developer.log(
        'ChatListViewModel - updateWithNewMessage() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }

  /// Load more chats (pagination)
  Future<bool> loadMoreChatList() async {
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

            return true;
          } catch (e) {
            developer.log(
              'ChatListViewModel - loadMoreChatList() error: $e',
              name: 'ChatListViewModel',
            );
            setError(e.toString());
            _page -= 1; // rollback page on failure
            return false;
          }
        }) ??
        false;
  }

  /// Marks a chat as read
  void markChatAsRead(String conversationId) async {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index == -1) return;

      final chat = _chatList[index];

      // Optimistic update
      _chatList[index] = chat.copyWith(unreadCount: 0);
      notifyListeners();

      if (chat.lastMessageId != null) {
        await _chatRepository.markAsRead(
          conversationId: conversationId,
          messageId: chat.lastMessageId!,
        );
      }
    } catch (e) {
      developer.log(
        'ChatListViewModel - markChatAsRead() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }

  /// Handles socket event 'conversation_updated'
  void handleSocketConversationUpdate(dynamic data, String? currentUserId) {
    try {
      final conversationId = data['conversationId'] as String?;
      final lastMessage = data['lastMessage'] as Map<String, dynamic>?;

      if (conversationId != null && lastMessage != null) {
        final content = lastMessage['content'] as String? ?? '';
        final createdAt =
            lastMessage['created_at'] as String? ??
            DateTime.now().toIso8601String();
        final senderId = lastMessage['sender_id']?.toString();
        final lastMessageId = lastMessage['id']?.toString();
        final type = lastMessage['type'] as String?;

        updateWithNewMessage(
          conversationId,
          content,
          createdAt,
          senderId: senderId,
          currentUserId: currentUserId,
          lastMessageId: lastMessageId,
          type: type,
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

  /// Handles socket event 'conversation_read_by_me'
  void handleConversationReadByMe(String conversationId) {
    try {
      final index = _chatList.indexWhere((chat) => chat.id == conversationId);
      if (index != -1) {
        _chatList[index] = _chatList[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      developer.log(
        'ChatListViewModel - loadMoreChatList() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }
}
