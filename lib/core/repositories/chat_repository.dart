import 'dart:developer';

import 'package:ngobrolin_app/core/models/conversation_participant_model.dart';

import '../models/chat_list_item_model.dart';
import '../models/message_model.dart';
import '../models/paginated_result.dart';
import '../services/api/api_service.dart';
import 'package:dio/dio.dart';

/// Repository for chat related operations
class ChatRepository {
  final ApiService _apiService;

  ChatRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Get conversation list from backend with pagination
  Future<PaginatedResult<ChatListItemModel>> getConversationList({
    int page = 1,
    int limit = 20,
  }) async {
    return _apiService.post<PaginatedResult<ChatListItemModel>>(
      '/conversations/list',
      // Backend membaca dari req.query, jadi kirim sebagai queryParameters
      queryParameters: {'page': page, 'limit': limit},
      parser: _parseConversationList,
    );
  }

  PaginatedResult<ChatListItemModel> _parseConversationList(dynamic response) {
    final conversations = (response['conversations'] as List<dynamic>);
    final pagination = (response['pagination'] as Map<String, dynamic>);

    final chats = conversations.map((convRaw) {
      final conv = convRaw as Map<String, dynamic>;
      final type = conv['type'] as String?;
      final participants = (conv['participants'] as List<dynamic>? ?? [])
          .map((p) => p as Map<String, dynamic>)
          .toList();

      final partner = participants.isNotEmpty ? participants.first : null;

      final lastMessage = conv['lastMessage'] as Map<String, dynamic>?;
      final lastContent = lastMessage != null ? (lastMessage['content'] as String? ?? '') : '';
      final lastMessageId = lastMessage != null ? (lastMessage['id'] as String?) : null;
      final lastMessageType = lastMessage != null
          ? (lastMessage['type'] as String? ?? 'text')
          : 'text';

      final lastCreatedAtStr = lastMessage != null
          ? (lastMessage['created_at'] as String?)
          : (conv['joined_at'] as String?);
      final timestamp = lastCreatedAtStr != null
          ? DateTime.parse(lastCreatedAtStr)
          : DateTime.now();

      final unreadCount = (conv['unreadCount'] as int?) ?? 0;

      // Map untuk private vs group
      final isGroup = type == 'group';
      final name = isGroup
          ? (conv['name'] as String? ?? 'Group')
          : (partner?['name'] as String? ?? '');
      final username = isGroup
          ? (conv['name'] as String? ?? 'Group')
          : (partner?['username'] as String? ?? '');
      final avatarUrl = isGroup
          ? (conv['group_image'] as String?)
          : (partner?['avatarUrl'] as String?);

      // id Chat pakai id conversation (sesuai kebutuhan ViewModel/Screen)
      final convId = conv['id'] as String;

      // userId untuk navigasi ke chat; saat private pakai partner.id, saat group fallback ke conversation id
      final userId = !isGroup ? (partner?['id'] as String? ?? convId) : convId;

      return ChatListItemModel(
        id: convId,
        type: type ?? '',
        userId: userId,
        name: name,
        username: username,
        avatarUrl: avatarUrl,
        lastMessage: lastContent,
        lastMessageId: lastMessageId,
        lastMessageType: lastMessageType,
        timestamp: timestamp,
        unreadCount: unreadCount,
      );
    }).toList();

    log('-------- chats: $chats');

    return PaginatedResult<ChatListItemModel>(
      items: chats,
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }

  /// Mark messages as read in a conversation
  Future<bool> markAsRead({required String conversationId, required String messageId}) async {
    await _apiService.post<Map<String, dynamic>>(
      '/messages/mark-read',
      data: {'conversationId': conversationId, 'messageId': messageId},
    );
    return true;
  }

  // Tambahkan helper untuk dapat/membuat conversation privat dan mengembalikan id-nya
  Future<String> getOrCreatePrivateConversationId(String participantId) async {
    return _apiService.post<String>(
      '/conversations/create',
      data: {'type': 'private', 'participantId': participantId},
      parser: (data) {
        final conversation = data['conversation'] as Map<String, dynamic>;
        return conversation['id'] as String;
      },
    );
  }

  Future<String?> findPrivateConversationIdWith(String participantId) async {
    return _apiService.post<String?>(
      '/conversations/list',
      queryParameters: {'page': 1, 'limit': 100},
      parser: (data) {
        final conversations = (data['conversations'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        for (final conv in conversations) {
          final type = conv['type'] as String?;
          if (type == 'private') {
            final participants = (conv['participants'] as List<dynamic>? ?? [])
                .map((p) => p as Map<String, dynamic>)
                .toList();
            final found = participants.any((p) => (p['id']?.toString()) == participantId);
            if (found) {
              return conv['id'] as String;
            }
          }
        }
        return null;
      },
    );
  }

  // Ambil pesan berdasarkan conversationId sesuai backend (raw untuk akses type)
  Future<List<Map<String, dynamic>>> getMessagesByConversationIdRaw({
    required String conversationId,
  }) async {
    return _apiService.post<List<Map<String, dynamic>>>(
      '/messages/get',
      data: {'conversationId': conversationId},
      parser: (data) =>
          (data['messages'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  /// Get conversation participants
  Future<Map<String, dynamic>> getConversationById({
    required String conversationId,
    bool isShowParticipants = true,
    bool isParticipantsIncludeMe = true,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      '/conversations/get',
      data: {
        'conversationId': conversationId,
        'isShowParticipants': isShowParticipants,
        'isParticipantsIncludeMe': isParticipantsIncludeMe,
      },
    );
  }

  /// Get conversation participants
  Future<List<ConversationParticipantModel>> getConversationParticipants({
    required String conversationId,
    bool isIncludeMe = true,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/conversations/participants',
      data: {'conversationId': conversationId, 'isIncludeMe': isIncludeMe},
    );

    print('-------- getConversationParticipants response: $response');
    print('-------- getConversationParticipants response: ${response['participants']}');

    final conversationParticipantsResponse = (response['participants'] as List<dynamic>)
        .map((e) => ConversationParticipantModel.fromJson(e as Map<String, dynamic>))
        .toList();
    print(
      '-------- getConversationParticipants conversationParticipantsResponse: $conversationParticipantsResponse',
    );

    return conversationParticipantsResponse;
  }

  Future<List<MessageModel>> getMessagesByConversationId({required String conversationId}) async {
    final items = await getMessagesByConversationIdRaw(conversationId: conversationId);
    return items.map((item) {
      final senderId = (item['sender_id']?.toString()) ?? (item['sender']?['id']?.toString() ?? '');
      final createdAtStr = (item['created_at'] as String?) ?? DateTime.now().toIso8601String();
      return MessageModel(
        id: item['id'] as String,
        conversationId: conversationId,
        senderId: senderId,
        content: (item['content'] as String?) ?? '',
        type: (item['type'] as String?) ?? 'text',
        isRead: (item['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(createdAtStr),
      );
    }).toList();
  }

  /// Send a message (kontrak baru: pakai conversationId dan endpoint backend)
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  }) async {
    return _apiService.post<MessageModel>(
      '/messages/send',
      data: {'conversationId': conversationId, 'content': content, 'type': type},
      parser: (response) {
        final data = response['data'] as Map<String, dynamic>;
        final senderId =
            (data['sender_id']?.toString()) ?? (data['sender']?['id']?.toString() ?? '');
        final createdAtStr = (data['created_at'] as String?) ?? DateTime.now().toIso8601String();
        return MessageModel(
          id: data['id'] as String,
          conversationId: conversationId,
          senderId: senderId,
          content: (data['content'] as String?) ?? '',
          type: (data['type'] as String?) ?? 'text',
          isRead: false,
          createdAt: DateTime.parse(createdAtStr),
        );
      },
    );
  }

  Future<String> uploadAttachment({required String filePath, required String type}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'type': type,
    });
    return _apiService.post<String>(
      '/messages/upload',
      data: formData,
      parser: (data) => (data['url'] as String? ?? '').toString(),
    );
  }
}
