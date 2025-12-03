import '../../models/chat.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';

class ChatListViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  // Gunakan List<Chat> alih-alih List<Map<String, dynamic>> untuk tipe data yang kuat
  List<Chat> _chatList = [];
  List<Chat> get chatList => _chatList;

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
            final result = await _chatRepository.getConversationList(page: _page, limit: _limit);

            _chatList = result.items;
            _hasMore = result.page < result.totalPages;

            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Fetches dummy chat list for testing purposes
  Future<bool> fetchChatListDummy() async {
    return await runBusyFuture(() async {
          try {
            final dummyChats = [
              Chat(
                id: '1',
                userId: 'user1',
                name: 'John Doe',
                username: 'johndoe',
                avatarUrl: 'https://via.placeholder.com/150',
                lastMessage: 'Hey, how are you doing?',
                timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
                unreadCount: 2,
              ),
              Chat(
                id: '2',
                userId: 'user2',
                name: 'Jane Smith',
                username: 'janesmith',
                avatarUrl: 'https://via.placeholder.com/150',
                lastMessage: 'See you tomorrow!',
                timestamp: DateTime.now().subtract(const Duration(hours: 1)),
                unreadCount: 0,
              ),
              Chat(
                id: '3',
                userId: 'user3',
                name: 'Mike Johnson',
                username: 'mikejohnson',
                avatarUrl: 'https://via.placeholder.com/150',
                lastMessage: 'Thanks for the help earlier',
                timestamp: DateTime.now().subtract(const Duration(hours: 3)),
                unreadCount: 1,
              ),
              Chat(
                id: '4',
                userId: 'user4',
                name: 'Sarah Wilson',
                username: 'sarahwilson',
                avatarUrl: 'https://via.placeholder.com/150',
                lastMessage: 'Let\'s meet up this weekend',
                timestamp: DateTime.now().subtract(const Duration(days: 1)),
                unreadCount: 0,
              ),
              Chat(
                id: '5',
                userId: 'user5',
                name: 'David Brown',
                username: 'davidbrown',
                avatarUrl: 'https://via.placeholder.com/150',
                lastMessage: 'Good morning! How\'s your day going?',
                timestamp: DateTime.now().subtract(const Duration(days: 2)),
                unreadCount: 3,
              ),
            ];

            _chatList = dummyChats;
            // Sort chats by timestamp (newest first)
            _chatList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return true;
          } catch (e) {
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
          senderId == null || currentUserId == null || senderId != currentUserId;

      final newUnreadCount = shouldIncrementUnread ? oldChat.unreadCount + 1 : oldChat.unreadCount;

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
  }

  /// Load more chats (pagination)
  Future<bool> loadMore() async {
    if (!_hasMore || isLoading) return false;

    return await runBusyFuture(() async {
          try {
            _page += 1;
            final result = await _chatRepository.getConversationList(page: _page, limit: _limit);

            _chatList.addAll(result.items);
            _hasMore = result.page < result.totalPages;

            return true;
          } catch (e) {
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
      // Revert if needed, or just log error
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
        final createdAt = lastMessage['created_at'] as String? ?? DateTime.now().toIso8601String();
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
      print('Error handling conversation update: $e');
    }
  }

  /// Handles socket event 'conversation_read_by_me'
  void handleConversationReadByMe(String conversationId) {
    final index = _chatList.indexWhere((chat) => chat.id == conversationId);
    if (index != -1) {
      _chatList[index] = _chatList[index].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

  /// Deletes a chat
  Future<bool> deleteChat(String chatId) async {
    return await runBusyFuture(() async {
          try {
            final success = await _chatRepository.deleteChat(chatId);

            if (success) {
              _chatList.removeWhere((chat) => chat.id == chatId);
            }

            return success;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }
}
