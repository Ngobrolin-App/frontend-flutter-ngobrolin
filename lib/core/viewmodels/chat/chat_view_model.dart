import '../../models/message_model.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';

class ChatViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  String _partnerId = '';
  String get partnerId => _partnerId;

  String _partnerName = '';
  String get partnerName => _partnerName;

  String? _partnerAvatarUrl;
  String? get partnerAvatarUrl => _partnerAvatarUrl;

  bool _isPartnerTyping = false;
  bool get isPartnerTyping => _isPartnerTyping;

  String _partnerStatus = 'offline';
  String get partnerStatus => _partnerStatus;

  // Conversation ID for joining/leaving realtime rooms
  String? _conversationId;
  String? get conversationId => _conversationId;

  String? _conversationType;
  String? get conversationType => _conversationType;

  String? _conversationName;
  String? get conversationName => _conversationName;

  String? _conversationGroupImage;
  String? get conversationGroupImage => _conversationGroupImage;

  ChatViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  /// Initializes the chat with a specific user
  void initChat(String? userId, String? name, String? avatarUrl, String? conversationId) async {
    _partnerId = userId ?? '';
    _partnerName = name ?? '';
    _partnerAvatarUrl = avatarUrl ?? '';
    _messages = [];
    _isPartnerTyping = false;
    _partnerStatus = 'offline'; // Default, bisa diupdate via socket nanti

    _conversationId = conversationId;
    if (_conversationId == null || _conversationId!.isEmpty) {
      await _getPrivateConversationIdByParticipantId();
    }
    await _getConversationDataOnly();
    _loadParticipant();
    _loadMessages();
  }

  /// Gets private conversation ID by participant ID from the API
  Future<bool> _getPrivateConversationIdByParticipantId() async {
    print("Loading private conversation ID... $_partnerId");
    return await runBusyFuture(() async {
          try {
            final convId = await _chatRepository.findPrivateConversationIdWith(_partnerId);
            _conversationId = convId;
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  void setPartnerTyping(bool isTyping) {
    _isPartnerTyping = isTyping;
    notifyListeners();
  }

  void setPartnerStatus(String status) {
    _partnerStatus = status;
    notifyListeners();
  }

  void setConversationId(String id) {
    _conversationId = id;
    notifyListeners();
  }

  /// Gets conversation details from the API
  Future<bool> _getConversationDataOnly() async {
    print("Loading conversation... $_conversationId");
    return await runBusyFuture(() async {
          try {
            if (_conversationId == null) {
              return false;
            }

            final conversation = await _chatRepository.getConversationById(
              conversationId: _conversationId!,
              isShowParticipants: false,
            );

            _conversationType = conversation['conversation']['type'];
            _conversationName = conversation['conversation']['name'];
            _conversationGroupImage = conversation['conversation']['group_image'];

            print("get conversation data only: $conversation");

            notifyListeners();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Loads conversation participants from the API
  Future<bool> _loadParticipant() async {
    print("Loading partner participants... $_conversationId");
    return await runBusyFuture(() async {
          try {
            if (_conversationId == null) {
              return false;
            }

            final participants = await _chatRepository.getConversationParticipants(
              conversationId: _conversationId!,
              isIncludeMe: _conversationType != 'private',
            );

            if (_conversationType == 'private') {
              _partnerName = participants.first.name;
              _partnerAvatarUrl = participants.first.avatarUrl;
            }

            notifyListeners();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Loads chat messages from the API
  Future<bool> _loadMessages() async {
    return await runBusyFuture(() async {
          try {
            if (_conversationId == null) {
              return false;
            }

            _messages = await _chatRepository.getMessagesByConversationId(
              conversationId: _conversationId!,
            );

            notifyListeners();

            final lastMessage = _messages.isNotEmpty ? _messages.last : null;
            if (lastMessage != null && !lastMessage.isRead && lastMessage.senderId == _partnerId) {
              await _chatRepository.markAsRead(
                conversationId: _conversationId!,
                messageId: lastMessage.id,
              );
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

    // Optimistic update (opsional, tapi lebih baik tunggu server response untuk id yang valid)
    // Tapi karena kita butuh ID dari server, kita tunggu saja.

    if (_conversationId == null) {
      final convId = await _chatRepository.getOrCreatePrivateConversationId(_partnerId);
      setConversationId(convId);
    }

    return await runBusyFuture(() async {
          try {
            final newMessage = await _chatRepository.sendMessage(
              conversationId: _conversationId!,
              content: content,
              type: type,
            );

            final exists = _messages.any((m) => m.id == newMessage.id);
            if (!exists) {
              _messages.add(newMessage);
              notifyListeners();
            }
            // _messages.add(newMessage);
            // notifyListeners();
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
      final convId = await _chatRepository.getOrCreatePrivateConversationId(_partnerId);
      setConversationId(convId);
    }
    return await runBusyFuture(() async {
          try {
            final url = await _chatRepository.uploadAttachment(filePath: filePath, type: type);
            // sendMessage akan menambahkan pesan ke list
            return await sendMessage(url, type: type);
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Handles incoming messages (e.g., from WebSocket)
  void handleIncomingMessage(dynamic messageData) {
    try {
      MessageModel message;
      if (messageData is MessageModel) {
        message = messageData;
      } else if (messageData is Map<String, dynamic>) {
        // Handle kemungkinan snake_case dari socket
        // Jika struktur sama dengan API response (snake_case), kita mapping manual
        if (messageData.containsKey('created_at') || messageData.containsKey('sender_id')) {
          final senderId =
              (messageData['sender_id']?.toString()) ??
              (messageData['sender']?['id']?.toString() ?? '');
          final createdAtStr =
              (messageData['created_at'] as String?) ?? DateTime.now().toIso8601String();

          message = MessageModel(
            id: messageData['id']?.toString() ?? '',
            senderId: senderId,
            conversationId: _conversationId ?? '',
            content: messageData['content']?.toString() ?? '',
            type: messageData['type']?.toString() ?? 'text',
            isRead: messageData['is_read'] as bool? ?? false,
            createdAt: DateTime.parse(createdAtStr),
          );
        } else {
          // Asumsi camelCase (Message.fromJson)
          message = MessageModel.fromJson(messageData);
        }
      } else {
        return;
      }

      // Ensure message belongs to current conversation
      if (message.conversationId != _conversationId) {
        return;
      }

      // Cek duplikasi
      final exists = _messages.any((m) => m.id == message.id);
      if (!exists) {
        _messages.add(message);
        notifyListeners();
      }
    } catch (e) {
      // Log error parsing quietly
      print('Error handling incoming message: $e');
    }
  }

  /// Update read status for a batch of messages
  void updateMessagesReadStatus(List<String> messageIds) {
    if (messageIds.isEmpty) return;

    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (messageIds.contains(_messages[i].id)) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Marks a specific message as read immediately (used for realtime incoming messages)
  Future<void> markMessageAsRead(String messageId) async {
    if (_conversationId == null) return;
    try {
      await _chatRepository.markAsRead(conversationId: _conversationId!, messageId: messageId);

      // Update local state
      updateMessagesReadStatus([messageId]);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// Clears the chat history
  void clearChat() {
    _messages = [];
    notifyListeners();
  }
}
