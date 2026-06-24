import '../../models/message_model.dart';
import '../../repositories/chat_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel managing active single or group chat interactions, pagination logs,
/// attachment deliveries, and incoming stream normalization.
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

  String? _conversationId;
  String? get conversationId => _conversationId;

  String? _conversationType;
  String? get conversationType => _conversationType;

  String? _conversationName;
  String? get conversationName => _conversationName;

  String? _conversationGroupImage;
  String? get conversationGroupImage => _conversationGroupImage;

  // Pagination states
  int _page = 1;
  final int _limit = 20;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  ChatViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  /// Synchronously initializes basic UI meta placeholders before executing background fetches.
  void initChat({
    String? userId,
    String? name,
    String? avatarUrl,
    String? conversationId,
  }) {
    _partnerId = userId ?? '';
    _partnerName = name ?? '';
    _partnerAvatarUrl = avatarUrl ?? '';
    _messages = [];
    _isPartnerTyping = false;
    _partnerStatus = 'offline';
    _conversationId = conversationId;
    _page = 1;
    _hasMore = true;

    // Triggers network channels on a separated routine thread to prevent execution freezes
    _setupChatRoomContext();
  }

  /// Internal asynchronous runner orchestration to load chat histories sequentially.
  Future<void> _setupChatRoomContext() async {
    if (_conversationId == null || _conversationId!.isEmpty) {
      await _getPrivateConversationIdByParticipantId();
    }

    if (_conversationId != null && _conversationId!.isNotEmpty) {
      await _getConversationDataOnly();
      await _loadParticipant();
      await _loadMessages();
    }
  }

  /// Fetches private single room session mappings linked to a user profile ID.
  Future<bool> _getPrivateConversationIdByParticipantId() async {
    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository
                .getPrivateConversationByPartnerId(_partnerId);
            final conversation = result.data;
            _conversationId = conversation?.id;

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "ChatViewModel - _getPrivateConversationIdByParticipantId error $e",
              name: 'ChatViewModel',
            );
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

  void setConversationId(String? id) {
    _conversationId = id;
    notifyListeners();
  }

  /// Extracts conversation attributes directly from the server index database.
  Future<bool> _getConversationDataOnly() async {
    if (_conversationId == null) return false;

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.getConversationById(
              conversationId: _conversationId!,
              isShowParticipants: true,
            );
            final conversation = result.data;

            _conversationType = conversation?.type;
            _conversationName = conversation?.name;
            _conversationGroupImage = conversation?.groupImage;

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "ChatViewModel - _getConversationDataOnly() error $e",
              name: 'ChatViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Fetches participants metadata linked inside the room roster array.
  Future<bool> _loadParticipant() async {
    if (_conversationId == null) return false;

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.getConversationParticipants(
              conversationId: _conversationId!,
              isIncludeMe: _conversationType != 'private',
            );

            final participants = result.data ?? [];

            if (_conversationType == 'private' && participants.isNotEmpty) {
              _partnerId = participants.first.id;
              _partnerName = participants.first.name;
              _partnerAvatarUrl = participants.first.avatarUrl;
            }

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "ChatViewModel - _loadParticipant() error $e",
              name: 'ChatViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Requests modern messages logs belonging to the active room.
  Future<bool> _loadMessages() async {
    if (_conversationId == null) return false;

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.getMessagesByConversationId(
              conversationId: _conversationId!,
              page: _page,
              limit: _limit,
            );
            final paginatedResult = result.data;
            final fetchedMessages = paginatedResult?.items ?? [];

            _messages = fetchedMessages;
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);
            notifyListeners();

            // Auto-acknowledge unread elements sent by the partner peer upon entering viewport
            if (_messages.isNotEmpty) {
              final lastMessage = _messages.last;
              if (!lastMessage.isRead && lastMessage.senderId == _partnerId) {
                await _chatRepository.markAsRead(
                  conversationId: _conversationId!,
                  messageId: lastMessage.id,
                );
              }
            }

            return true;
          } catch (e) {
            developer.log(
              "ChatViewModel - _loadMessages() error $e",
              name: 'ChatViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Appends older historical conversations via endless tracking triggers.
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _conversationId == null) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _page += 1;

      final result = await _chatRepository.getMessagesByConversationId(
        conversationId: _conversationId!,
        page: _page,
        limit: _limit,
      );

      final paginatedResult = result.data;
      final olderMessages = paginatedResult?.items ?? [];

      // Prepends chronological legacy message data elements to the tail end of the viewport
      _messages.addAll(olderMessages);
      _hasMore =
          (paginatedResult?.page ?? 0) < (paginatedResult?.totalPages ?? 0);
    } catch (e) {
      developer.log(
        "ChatViewModel - _loadMoreMessages() error $e",
        name: 'ChatViewModel',
      );

      setError(e.toString());
      _page = (_page > 1) ? _page - 1 : 1;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Submits text strings to remote endpoints.
  Future<bool> sendMessage(String content, {String type = 'text'}) async {
    if (content.trim().isEmpty) return false;

    if (_conversationId == null || _conversationId!.isEmpty) {
      final result = await _chatRepository.getOrCreatePrivateConversationId(
        _partnerId,
      );
      final conversation = result.data;
      setConversationId(conversation?.id);
    }

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.sendMessage(
              conversationId: _conversationId!,
              content: content,
              type: type,
            );

            final newMessage = result.data;
            final newMessageId = newMessage?.id ?? '';
            developer.log('nlohhashdioasdlohjjhjjjj ahhhh $newMessageId');

            if (newMessage != null) {
              final exists = _messages.any((m) => m.id == newMessage.id);
              if (!exists) {
                // Adds to index position 0 if list configuration displays inverted streams
                _messages.insert(0, newMessage);
                notifyListeners();
              }
            }
            if (newMessageId.isNotEmpty) markMessageAsRead(newMessageId);
            return true;
          } catch (e) {
            developer.log(
              "ChatViewModel - sendMessage() error $e",
              name: 'ChatViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Submits binary media files through a repository upload tunnel.
  Future<bool> sendAttachment(String filePath, String type) async {
    if (_conversationId == null || _conversationId!.isEmpty) {
      final result = await _chatRepository.getOrCreatePrivateConversationId(
        _partnerId,
      );
      final conversation = result.data;
      setConversationId(conversation?.id);
    }

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.uploadAttachment(
              filePath: filePath,
              type: type,
            );

            final url = result.data ?? '';
            return await sendMessage(url, type: type);
          } catch (e) {
            developer.log(
              "ChatViewModel - sendAttachment() error $e",
              name: 'ChatViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Receives message entries broadcasted via real-time WebSocket infrastructure layers.
  void handleIncomingMessage(dynamic messageData) {
    try {
      MessageModel message;
      if (messageData is MessageModel) {
        message = messageData;
      } else if (messageData is Map<String, dynamic>) {
        message = MessageModel.fromJson(messageData);
      } else {
        return;
      }

      if (message.conversationId != _conversationId) return;

      final exists = _messages.any((m) => m.id == message.id);
      if (!exists) {
        _messages.insert(0, message);
        notifyListeners();
      }
    } catch (e) {
      developer.log(
        "ChatViewModel - handleIncomingMessage() error $e",
        name: 'ChatViewModel',
      );
      setError(e.toString());
    }
  }

  /// Synchronizes unread messages flags immediately on the user interface viewport list.
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

  /// Explicitly marks single remote entries as read across API and real-time states.
  Future<void> markMessageAsRead(String messageId) async {
    if (_conversationId == null) return;
    try {
      await _chatRepository.markAsRead(
        conversationId: _conversationId!,
        messageId: messageId,
      );
    } catch (e) {
      developer.log(
        "ChatViewModel - markMessageAsRead() error $e",
        name: 'ChatViewModel',
      );
      setError(e.toString());
    }
  }

  /// Purges local buffer list values.
  void clearChat() {
    _messages = [];
    notifyListeners();
  }
}
