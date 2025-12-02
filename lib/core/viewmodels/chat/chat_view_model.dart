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

  void setConversationId(String id) {
    _conversationId = id;
    notifyListeners();
  }

  Future<bool> _loadMessages() async {
    return await runBusyFuture(() async {
          try {
            // Cari percakapan privat yang sudah ada dengan partner tanpa membuat baru
            final convId = await _chatRepository.findConversationIdWith(_partnerId);
            _conversationId = convId;

            if (convId == null) {
              _messages = [];
              notifyListeners();
              return true;
            }

            final items = await _chatRepository.getMessagesByConversationRaw(
              conversationId: convId,
            );

            _messages = items
                .map(
                  (item) => {
                    'id': item['id']?.toString() ?? '',
                    'senderId':
                        (item['sender_id']?.toString()) ??
                        (item['sender']?['id']?.toString() ?? ''),
                    'content': item['content'] ?? '',
                    'timestamp':
                        (item['created_at'] as String?) ?? DateTime.now().toIso8601String(),
                    'isRead': item['is_read'] as bool? ?? false,
                    'type': item['type'] as String? ?? 'text',
                  },
                )
                .toList();

            notifyListeners();

            final lastMessageId = messages.isNotEmpty ? messages.last['id'] : null;
            if (lastMessageId != null) {
              await _chatRepository.markAsRead(conversationId: convId, messageId: lastMessageId);
            }

            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Sends a new message
  Future<bool> sendMessage(String content, {String type = 'text'}) async {
    if (content.trim().isEmpty) return false;
    if (_conversationId == null) {
      final convId = await _chatRepository.getOrCreateConversationId(_partnerId);
      setConversationId(convId);
    }

    return await runBusyFuture(() async {
          try {
            await _chatRepository.sendMessage(
              conversationId: _conversationId!,
              content: content,
              type: type,
            );
            notifyListeners();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  Future<bool> sendAttachment(String filePath, String type) async {
    if (_conversationId == null) {
      final convId = await _chatRepository.getOrCreateConversationId(_partnerId);
      setConversationId(convId);
    }
    return await runBusyFuture(() async {
          try {
            final url = await _chatRepository.uploadAttachment(filePath: filePath, type: type);
            return await sendMessage(url, type: type);
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Handles incoming messages (e.g., from WebSocket)
  void handleIncomingMessage(Map<String, dynamic> message) {
    final exists = _messages.any((m) => m['id'] == message['id']);
    if (!exists) {
      _messages.add(message);
      notifyListeners();
    }
  }

  /// Update read status for a batch of messages
  void updateMessagesReadStatus(List<String> messageIds) {
    if (messageIds.isEmpty) return;
    for (final id in messageIds) {
      final idx = _messages.indexWhere((m) => m['id'] == id);
      if (idx != -1) {
        _messages[idx]['isRead'] = true;
      }
    }
    notifyListeners();
  }

  /// Clears the chat history
  void clearChat() {
    _messages = [];
    notifyListeners();
  }
}
