import '../../models/message.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';

class ChatViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;
  
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  String _partnerId = '';
  String get partnerId => _partnerId;

  String _partnerName = '';
  String get partnerName => _partnerName;

  String? _partnerAvatarUrl;
  String? get partnerAvatarUrl => _partnerAvatarUrl;

  ChatViewModel({ChatRepository? chatRepository}) 
      : _chatRepository = chatRepository ?? ChatRepository();

  /// Initializes the chat with a specific user
  void initChat(String userId, String name, String? avatarUrl) {
    _partnerId = userId;
    _partnerName = name;
    _partnerAvatarUrl = avatarUrl;
    _loadMessages();
  }

  /// Loads chat messages from the API
  Future<bool> _loadMessages() async {
    return await runBusyFuture(() async {
      try {
        // Create or get chat with this user
        final chat = await _chatRepository.createOrGetChat(_partnerId);
        
        // Get messages for this chat
        final messages = await _chatRepository.getMessages(chat.id);
        
        // Convert to map format for compatibility with existing UI
        _messages = messages.map((message) => {
          'id': message.id,
          'senderId': message.senderId,
          'content': message.content,
          'timestamp': message.createdAt.toIso8601String(),
          'isRead': message.isRead,
        }).toList();
        
        // Mark messages as read
        await _chatRepository.markAsRead(chat.id);
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Sends a new message
  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty) return false;
    
    return await runBusyFuture(() async {
      try {
        // Send message via repository
        final message = await _chatRepository.sendMessage(
          receiverId: _partnerId,
          content: content,
        );
        
        // Add message to local list
        _messages.add({
          'id': message.id,
          'senderId': message.senderId,
          'content': message.content,
          'timestamp': message.createdAt.toIso8601String(),
          'isRead': message.isRead,
        });
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Handles incoming messages (e.g., from WebSocket)
  void handleIncomingMessage(Map<String, dynamic> message) {
    if (message['senderId'] == _partnerId) {
      _messages.add(message);
      notifyListeners();
    }
  }

  /// Clears the chat history
  void clearChat() {
    _messages = [];
    notifyListeners();
  }
}