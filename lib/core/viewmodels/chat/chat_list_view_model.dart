import '../../models/chat.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';

class ChatListViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  List<Map<String, dynamic>> _chatList = [];
  List<Map<String, dynamic>> get chatList => _chatList;

  // Pagination state
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Cache lastMessageId per conversation for mark-as-read
  final Map<String, String?> _lastMessageIdByConversation = {};

  ChatListViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  /// Fetches the list of chats from the API (backend + pagination)
  Future<bool> fetchChatList() async {
    _page = 1;
    _hasMore = true;
    _chatList = [];
    _lastMessageIdByConversation.clear();

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.getConversationList(page: _page, limit: _limit);
            final chats = (result['chats'] as List<Chat>);
            final rawConversations = (result['rawConversations'] as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList();
            final pagination = (result['pagination'] as Map<String, dynamic>);

            // Map raw lastMessageId
            for (final conv in rawConversations) {
              final convId = conv['id'] as String;
              final lastMessage = conv['lastMessage'] as Map<String, dynamic>?;
              _lastMessageIdByConversation[convId] = lastMessage != null ? lastMessage['id'] as String? : null;
            }

            // Convert to map format for compatibility with existing UI
            _chatList = chats
                .map(
                  (chat) => {
                    'id': chat.id,
                    'userId': chat.userId,
                    'name': chat.name,
                    'username': chat.username,
                    'avatarUrl': chat.avatarUrl,
                    'lastMessage': chat.lastMessage,
                    'timestamp': chat.timestamp.toIso8601String(),
                    'unreadCount': chat.unreadCount,
                    'lastMessageId': _lastMessageIdByConversation[chat.id], // tambahan
                  },
                )
                .toList();

            _hasMore = (pagination['page'] as int) < (pagination['totalPages'] as int);

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
            // Create dummy chat data
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

            // Convert to map format for compatibility with existing UI
            _chatList = dummyChats
                .map(
                  (chat) => {
                    'id': chat.id,
                    'userId': chat.userId,
                    'name': chat.name,
                    'username': chat.username,
                    'avatarUrl': chat.avatarUrl,
                    'lastMessage': chat.lastMessage,
                    'timestamp': chat.timestamp.toIso8601String(),
                    'unreadCount': chat.unreadCount,
                  },
                )
                .toList();

            // Sort chats by timestamp (newest first)
            _chatList.sort(
              (a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])),
            );

            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Updates the chat list with a new message
  void updateWithNewMessage(String chatId, String message, String timestamp) {
    final index = _chatList.indexWhere((chat) => chat['id'] == chatId);
    if (index != -1) {
      _chatList[index]['lastMessage'] = message;
      _chatList[index]['timestamp'] = timestamp;
      _chatList[index]['unreadCount'] = _chatList[index]['unreadCount'] + 1;

      // Sort chats by timestamp (newest first)
      _chatList.sort(
        (a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])),
      );

      notifyListeners();
    }
  }

  /// Load more chats (pagination)
  Future<bool> loadMore() async {
    if (!_hasMore || isLoading) return false;

    return await runBusyFuture(() async {
          try {
            _page += 1;
            final result = await _chatRepository.getConversationList(page: _page, limit: _limit);
            final chats = (result['chats'] as List<Chat>);
            final rawConversations = (result['rawConversations'] as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList();
            final pagination = (result['pagination'] as Map<String, dynamic>);

            // Map raw lastMessageId
            for (final conv in rawConversations) {
              final convId = conv['id'] as String;
              final lastMessage = conv['lastMessage'] as Map<String, dynamic>?;
              _lastMessageIdByConversation[convId] = lastMessage != null ? lastMessage['id'] as String? : null;
            }

            final additional = chats
                .map(
                  (chat) => {
                    'id': chat.id,
                    'userId': chat.userId,
                    'name': chat.name,
                    'username': chat.username,
                    'avatarUrl': chat.avatarUrl,
                    'lastMessage': chat.lastMessage,
                    'timestamp': chat.timestamp.toIso8601String(),
                    'unreadCount': chat.unreadCount,
                    'lastMessageId': _lastMessageIdByConversation[chat.id],
                  },
                )
                .toList();

            _chatList.addAll(additional);
            _hasMore = (pagination['page'] as int) < (pagination['totalPages'] as int);

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
      final lastMessageId = _lastMessageIdByConversation[conversationId];
      if (lastMessageId == null) {
        // Tidak ada lastMessage, tidak perlu call API
        final index = _chatList.indexWhere((chat) => chat['id'] == conversationId);
        if (index != -1) {
          _chatList[index]['unreadCount'] = 0;
          notifyListeners();
        }
        return;
      }

      await _chatRepository.markAsRead(conversationId: conversationId, messageId: lastMessageId);

      final index = _chatList.indexWhere((chat) => chat['id'] == conversationId);
      if (index != -1) {
        _chatList[index]['unreadCount'] = 0;
        notifyListeners();
      }
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Deletes a chat
  Future<bool> deleteChat(String chatId) async {
    return await runBusyFuture(() async {
          try {
            final success = await _chatRepository.deleteChat(chatId);

            if (success) {
              _chatList.removeWhere((chat) => chat['id'] == chatId);
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
