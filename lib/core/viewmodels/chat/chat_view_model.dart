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
  // Conversation ID for joining/leaving realtime rooms
  String? _conversationId;
  String? get conversationId => _conversationId;

  Future<bool> _loadMessages() async {
    return await runBusyFuture(() async {
      try {
        // Dapatkan atau buat percakapan privat dengan partner
        final convId = await _chatRepository.getOrCreateConversationId(_partnerId);
        _conversationId = convId;
  
        // Ambil pesan untuk conversation ini
        final messages = await _chatRepository.getMessagesByConversation(conversationId: convId);
  
        // Konversi ke map agar cocok dengan UI
        _messages = messages
            .map(
              (message) => {
                'id': message.id,
                'senderId': message.senderId,
                'content': message.content,
                'timestamp': message.createdAt.toIso8601String(),
                'isRead': message.isRead,
              },
            )
            .toList();
  
        // Tambahkan notify agar UI langsung rebuild setelah data dimuat
        notifyListeners();
  
        // Tandai pesan terakhir sebagai read jika ada
        final lastMessageId = messages.isNotEmpty ? messages.last.id : null;
        if (lastMessageId != null) {
          await _chatRepository.markAsRead(
            conversationId: convId,
            messageId: lastMessageId,
          );
        }
  
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
    if (_conversationId == null) {
      // Jika belum ada conversationId, coba muat dulu
      final loaded = await _loadMessages();
      if (!loaded || _conversationId == null) return false;
    }

    return await runBusyFuture(() async {
      try {
        // Kirim pesan via repository memakai conversationId
        final message = await _chatRepository.sendMessage(
          conversationId: _conversationId!,
          content: content,
        );

        // Tambahkan ke list lokal
        _messages.add({
          'id': message.id,
          'senderId': message.senderId,
          'content': message.content,
          'timestamp': message.createdAt.toIso8601String(),
          'isRead': message.isRead,
        });

        notifyListeners();
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Handles incoming messages (e.g., from WebSocket)
  void handleIncomingMessage(Map<String, dynamic> message) {
    // Dedup: jangan tambahkan jika id sudah ada
    final exists = _messages.any((m) => m['id'] == message['id']);
    if (!exists) {
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
