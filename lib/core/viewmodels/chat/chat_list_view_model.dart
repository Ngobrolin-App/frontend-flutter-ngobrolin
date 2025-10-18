import '../../models/chat.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';

class ChatListViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  List<Map<String, dynamic>> _chatList = [];
  List<Map<String, dynamic>> get chatList => _chatList;

  ChatListViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  /// Fetches the list of chats from the API
  Future<bool> fetchChatList() async {
    return await runBusyFuture(() async {
          try {
            final chats = await _chatRepository.getChatList();

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
                  },
                )
                .toList();

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

  /// Marks a chat as read
  void markChatAsRead(String chatId) async {
    try {
      await _chatRepository.markAsRead(chatId);

      final index = _chatList.indexWhere((chat) => chat['id'] == chatId);
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
