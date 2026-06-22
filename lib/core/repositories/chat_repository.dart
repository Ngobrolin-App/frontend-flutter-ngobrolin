import 'dart:developer' as developer;
import 'package:ngobrolin_app/core/models/api_response.dart';
import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/models/conversation_participant_model.dart';
import '../models/chat_list_item_model.dart';
import '../models/message_model.dart';
import '../models/paginated_result.dart';
import '../services/api/api_service.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final ApiService _apiService;

  ChatRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<ApiResponse<PaginatedResult<ChatListItemModel>>> getConversationList({
    int page = 1,
    int limit = 20,
  }) async {
    return _apiService.post<ApiResponse<PaginatedResult<ChatListItemModel>>>(
      '/conversations/list',
      queryParameters: {'page': page, 'limit': limit},
      parser: (response) {
        return ApiResponse<PaginatedResult<ChatListItemModel>>.fromJson(
          response,
          (data) {
            final mappedData =
                data as Map<String, dynamic>? ?? <String, dynamic>{};
            final pagination =
                mappedData['pagination'] as Map<String, dynamic>? ?? {};
            final chatListItems =
                mappedData['conversations'] as List<dynamic>? ?? [];

            final items = chatListItems
                .map(
                  (item) => ChatListItemModel.fromJson(
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
                  ),
                )
                .toList();

            return PaginatedResult(
              items: items,
              total: (pagination['total'] as int?) ?? 0,
              page: (pagination['page'] as int?) ?? 1,
              limit: (pagination['limit'] as int?) ?? 20,
              totalPages: (pagination['totalPages'] as int?) ?? 1,
            );
          },
        );
      },
      //   return ApiResponse<PaginatedResult<ChatListItemModel>>.fromJson(
      //     response,
      //     (data) => _parseConversationList(data),
      //   );
      // },
    );
  }

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

  Future<ApiResponse<ConversationModel>> getOrCreatePrivateConversationId(
    String participantId,
  ) async {
    return _apiService.post<ApiResponse<ConversationModel>>(
      '/conversations/create',
      data: {'type': 'private', 'participantId': participantId},
      parser: (response) {
        return ApiResponse<ConversationModel>.fromJson(
          response,
          (data) => ConversationModel.fromJson(
            data as Map<String, dynamic>? ?? <String, dynamic>{},
          ),
        );
      },
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
          (data) => ConversationModel.fromJson(
            data as Map<String, dynamic>? ?? <String, dynamic>{},
          ),
        );
      },
    );
  }

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
        (data) => ConversationModel.fromJson(
          data as Map<String, dynamic>? ?? <String, dynamic>{},
        ),
      ),
    );
  }

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
                (data) => (data as List<dynamic>? ?? [])
                    .map(
                      (e) => ConversationParticipantModel.fromJson(
                        e as Map<String, dynamic>? ?? <String, dynamic>{},
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
        return ApiResponse<PaginatedResult<MessageModel>>.fromJson(response, (
          data,
        ) {
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          final pagination =
              mappedData['pagination'] as Map<String, dynamic>? ?? {};
          final messages = mappedData['messages'] as List<dynamic>? ?? [];

          final items = messages
              .map(
                (item) => MessageModel.fromJson(
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
                ),
              )
              .toList();

          return PaginatedResult(
            items: items,
            total: (pagination['total'] as int?) ?? 0,
            page: (pagination['page'] as int?) ?? 1,
            limit: (pagination['limit'] as int?) ?? 20,
            totalPages: (pagination['totalPages'] as int?) ?? 1,
          );
        });
      },
    );
  }

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
          (data) => MessageModel.fromJson(
            data as Map<String, dynamic>? ?? <String, dynamic>{},
          ),
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
      options: Options(contentType: 'multipart/form-data'),
      parser: (response) => ApiResponse<String>.fromJson(response, (data) {
        final dataMap = data as Map<String, dynamic>? ?? <String, dynamic>{};
        return (dataMap['url'] as String? ?? '').toString();
      }),
    );
  }
}
