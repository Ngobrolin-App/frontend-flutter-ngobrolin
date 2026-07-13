import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';

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

  String _privatePartnerId = '';
  String get privatePartnerId => _privatePartnerId;

  String _privatePartnerStatus = UserStatus.offline.name;
  String get privatePartnerStatus => _privatePartnerStatus;

  bool _isParticipantTyping = false;
  bool get isParticipantTyping => _isParticipantTyping;

  String? _typingParticipantName;
  String? get typingParticipantName => _typingParticipantName;

  String? _conversationId;
  String? get conversationId => _conversationId;

  String? _conversationType;
  String? get conversationType => _conversationType;

  String? _conversationName;
  String? get conversationName => _conversationName;

  String? _conversationImageUrl;
  String? get conversationImageUrl => _conversationImageUrl;

  MessageModel? _replyingToMessage;
  MessageModel? get replyingToMessage => _replyingToMessage;

  List<UserModel> _participants = [];
  List<UserModel> get participants => _participants;

  List<String> get participantNames =>
      _participants.map((user) => user.name).toList();

  String get participantNamesText =>
      _participants.map((user) => user.name).join(', ');

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
    _privatePartnerId = userId ?? '';
    _conversationName = name ?? '';
    _conversationImageUrl = avatarUrl ?? '';
    _messages = [];
    _isParticipantTyping = false;
    _privatePartnerStatus = UserStatus.offline.name;
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
      await _loadMessages();
    }
  }

  /// Fetches private single room session mappings linked to a user profile ID.
  Future<bool> _getPrivateConversationIdByParticipantId() async {
    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository
                .getPrivateConversationByPartnerId(_privatePartnerId);
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

  void setParticipantTyping(bool isTyping, String? participantName) {
    _isParticipantTyping = isTyping;
    _typingParticipantName = participantName;
    notifyListeners();
  }

  void setPrivatePartnerStatus(String status) {
    _privatePartnerStatus = status;
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
            if (conversation?.type == ConversationType.group.name) {
              _conversationName = conversation?.name;
              _conversationImageUrl = conversation?.groupImage;
            }
            _participants = conversation?.participants ?? [];
            if (conversation?.type == ConversationType.private.name) {
              if (_participants.isNotEmpty) {
                final privatePartner = _participants.first;
                _privatePartnerId = privatePartner.id;
                _conversationName = privatePartner.name;
                _conversationImageUrl = privatePartner.avatarUrl;
              }
            }

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
              if (!lastMessage.isRead &&
                  lastMessage.senderId == _privatePartnerId) {
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

  void setReplyingTo(MessageModel? message) {
    _replyingToMessage = message;
    notifyListeners();
  }

  Future<bool> createGroupConversation({
    required String groupName,
    required List<String> participantIds,
    required String createdByUserId,
    String? groupImagePath,
  }) async {
    return await runBusyFuture(() async {
          try {
            String? groupImageUrl;
            if (groupImagePath != null && groupImagePath.isNotEmpty) {
              final result = await _chatRepository.uploadConversationGroupImage(
                filePath: groupImagePath,
              );
              groupImageUrl = result.data;
            }
            final result = await _chatRepository.createGroupConversation(
              groupName: groupName,
              participantIds: participantIds,
              groupImageUrl: groupImageUrl,
              createdByUserId: createdByUserId,
            );

            final conversation = result.data;
            setConversationId(conversation?.id);
            _conversationType = conversation?.type;
            _conversationName = conversation?.name;
            _conversationImageUrl = conversation?.groupImage;

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "ChatViewModel - createGroupConversation() error $e",
              name: 'ChatViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Submits text strings to remote endpoints.
  Future<bool> sendMessage({
    String? content,
    String type = 'text',
    String? mediaUrl,
    String? mediaFileType,
    String? mediaFileName,
    int? mediaSize,
  }) async {
    if ((content?.trim().isEmpty ?? true) && mediaUrl == null) {
      return false;
    }

    if (_conversationId == null || _conversationId!.isEmpty) {
      final result = await _chatRepository.getOrCreatePrivateConversationId(
        _privatePartnerId,
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
              repliedMessageId: _replyingToMessage?.id,
              mediaUrl: mediaUrl,
              mediaFileType: mediaFileType,
              mediaFileName: mediaFileName,
              mediaSize: mediaSize,
            );

            if (result.isSuccess) {
              _replyingToMessage = null;
              notifyListeners();
            }

            final newMessage = result.data;
            final newMessageId = newMessage?.id ?? '';

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
  Future<bool> sendAttachment({
    required String mediaFilePath,
    required String type,
    String? content,
    String? mediaFileType,
    String? mediaFileName,
    int? mediaSize,
  }) async {
    if (_conversationId == null || _conversationId!.isEmpty) {
      final result = await _chatRepository.getOrCreatePrivateConversationId(
        _privatePartnerId,
      );
      final conversation = result.data;
      setConversationId(conversation?.id);
    }

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.uploadAttachment(
              filePath: mediaFilePath,
              type: type,
            );

            final url = result.data ?? '';
            return await sendMessage(
              content: content,
              type: type,
              mediaUrl: url,
              mediaFileType: mediaFileType,
              mediaFileName: mediaFileName,
              mediaSize: mediaSize,
            );
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

  void handleConversationUpdated(dynamic data) {
    try {
      final rawUpdatedConversation =
          data['updatedConversation'] as Map<String, dynamic>?;

      ConversationModel? updatedConversation;
      if (rawUpdatedConversation != null) {
        updatedConversation = ConversationModel.fromJson(
          rawUpdatedConversation,
        );
        _conversationImageUrl = updatedConversation.groupImage;
        _conversationName = updatedConversation.name;
      }
      notifyListeners();
    } catch (e) {
      developer.log(
        'ChatViewModel - handleConversationUpdated() error: $e',
        name: 'ChatListViewModel',
      );
      setError(e.toString());
    }
  }

  void handleLeftParticipant(dynamic data) {
    try {
      final userId = data as String?;

      if (userId != null) {
        _participants.removeWhere((participant) => participant.id == userId);
      }

      notifyListeners();
    } catch (e) {
      developer.log(
        'ChatViewModel - handleLeftParticipant() error: $e',
        name: 'ChatViewModel',
      );
      setError(e.toString());
    }
  }
}
