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
        _chatList = chats.map((chat) => {
          'id': chat.id,
          'userId': chat.userId,
          'name': chat.name,
          'username': chat.username,
          'avatarUrl': chat.avatarUrl,
          'lastMessage': chat.lastMessage,
          'timestamp': chat.timestamp.toIso8601String(),
          'unreadCount': chat.unreadCount,
        }).toList();
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Updates the chat list with a new message
  void updateWithNewMessage(String chatId, String message, String timestamp) {
    final index = _chatList.indexWhere((chat) => chat['id'] == chatId);
    if (index != -1) {
      _chatList[index]['lastMessage'] = message;
      _chatList[index]['timestamp'] = timestamp;
      _chatList[index]['unreadCount'] = _chatList[index]['unreadCount'] + 1;
      
      // Sort chats by timestamp (newest first)
      _chatList.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      
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
    }) ?? false;
  }
}