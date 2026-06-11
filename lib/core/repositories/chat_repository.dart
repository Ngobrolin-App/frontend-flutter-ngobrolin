import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:ngobrolin_app/core/models/api_response.dart';
import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/models/conversation_participant_model.dart';

import '../models/chat_list_item_model.dart';
import '../models/message_model.dart';
import '../models/paginated_result.dart';
import '../services/api/api_service.dart';
import 'package:dio/dio.dart';

/// Repository for chat related operations
class ChatRepository {
  final ApiService _apiService;

  ChatRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Get conversation list from backend with pagination
  Future<ApiResponse<PaginatedResult<ChatListItemModel>>> getConversationList({
    int page = 1,
    int limit = 20,
  }) async {
    return _apiService.post<ApiResponse<PaginatedResult<ChatListItemModel>>>(
      '/conversations/list',
      // Backend membaca dari req.query, jadi kirim sebagai queryParameters
      queryParameters: {'page': page, 'limit': limit},
      parser: (response) =>
          ApiResponse<PaginatedResult<ChatListItemModel>>.fromJson(
            response,
            (data) => _parseConversationList(data),
          ),
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
      final lastContent = lastMessage != null
          ? (lastMessage['content'] as String? ?? '')
          : '';
      final lastMessageId = lastMessage != null
          ? (lastMessage['id'] as String?)
          : null;
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
  Future<ApiResponse> markAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    return await _apiService.post<ApiResponse>(
      '/messages/mark-read',
      data: {'conversationId': conversationId, 'messageId': messageId},
      parser: (response) => ApiResponse.fromJson(response, null),
    );
  }

  // Tambahkan helper untuk dapat/membuat conversation privat dan mengembalikan id-nya
  Future<ApiResponse<ConversationModel>> getOrCreatePrivateConversationId(
    String participantId,
  ) async {
    return _apiService.post<ApiResponse<ConversationModel>>(
      '/conversations/create',
      data: {'type': 'private', 'participantId': participantId},
      parser: (response) => ApiResponse<ConversationModel>.fromJson(
        response,
        (data) => ConversationModel.fromJson(data),
      ),
    );
  }

  Future<ApiResponse<ConversationModel>> getPrivateConversationByPartnerId(
    String partnerId,
  ) async {
    return _apiService.post<ApiResponse<ConversationModel>>(
      '/conversations/private-conversation',
      data: {'partnerId': partnerId},
      parser: (response) {
        return ApiResponse<ConversationModel>.fromJson(
          response,
          (data) => ConversationModel.fromJson(data),
        );
      },
    );
  }

  /// Get conversation participants
  Future<ApiResponse<ConversationModel>> getConversationById({
    required String conversationId,
    bool isShowParticipants = true,
    bool isParticipantsIncludeMe = true,
  }) async {
    return await _apiService.post<ApiResponse<ConversationModel>>(
      '/conversations/get',
      data: {
        'conversationId': conversationId,
        'isShowParticipants': isShowParticipants,
        'isParticipantsIncludeMe': isParticipantsIncludeMe,
      },
      parser: (response) => ApiResponse<ConversationModel>.fromJson(
        response,
        (data) => ConversationModel.fromJson(data),
      ),
    );
  }

  /// Get conversation participants
  Future<ApiResponse<List<ConversationParticipantModel>>>
  getConversationParticipants({
    required String conversationId,
    bool isIncludeMe = true,
  }) async {
    return await _apiService
        .post<ApiResponse<List<ConversationParticipantModel>>>(
          '/conversations/participants',
          data: {'conversationId': conversationId, 'isIncludeMe': isIncludeMe},
          parser: (response) =>
              ApiResponse<List<ConversationParticipantModel>>.fromJson(
                response,
                (data) => (data as List<dynamic>)
                    .map(
                      (e) => ConversationParticipantModel.fromJson(
                        e as Map<String, dynamic>,
                      ),
                    )
                    .toList(),
              ),
        );
  }

  Future<ApiResponse<PaginatedResult<MessageModel>>>
  getMessagesByConversationId({
    required String conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiService.post<ApiResponse<PaginatedResult<MessageModel>>>(
      '/messages/get',
      data: {'conversationId': conversationId, 'page': page, 'limit': limit},
      parser: (response) {
        debugPrint(
          'ChatRepository - getMessagesByConversationId() response: $response',
          wrapWidth: 1024,
        );
        return ApiResponse<PaginatedResult<MessageModel>>.fromJson(response, (
          data,
        ) {
          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
          final messages = data['messages'] as List<dynamic>? ?? [];

          final items = messages
              .map(
                (item) => MessageModel.fromJson(
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
                ),
              )
              .toList();

          return PaginatedResult(
            items: items,
            total: pagination['total'] as int? ?? 0,
            page: pagination['page'] as int? ?? 1,
            limit: pagination['limit'] as int? ?? 20,
            totalPages: pagination['totalPages'] as int? ?? 1,
          );
        });
      },
    );
  }

  /// Send a message (kontrak baru: pakai conversationId dan endpoint backend)
  Future<ApiResponse<MessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  }) async {
    return _apiService.post<ApiResponse<MessageModel>>(
      '/messages/send',
      data: {
        'conversationId': conversationId,
        'content': content,
        'type': type,
      },
      parser: (response) {
        return ApiResponse<MessageModel>.fromJson(
          response,
          (data) => MessageModel.fromJson(data),
        );
      },
    );
  }

  Future<ApiResponse<String>> uploadAttachment({
    required String filePath,
    required String type,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'type': type,
    });
    return _apiService.post<ApiResponse<String>>(
      '/messages/upload',
      data: formData,
      parser: (response) => ApiResponse<String>.fromJson(response, (data) {
        return (data['url'] as String? ?? '').toString();
      }),
    );
  }
}
