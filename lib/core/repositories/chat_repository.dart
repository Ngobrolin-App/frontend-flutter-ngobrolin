import '../models/chat.dart';
import '../models/message.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';

/// Repository for chat related operations
class ChatRepository {
  final ApiService _apiService;

  ChatRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Get chat list for current user (legacy, not used anymore)
  Future<List<Chat>> getChatList() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/chats');

      return (response).map((item) => Chat.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Get conversation list from backend with pagination
  Future<Map<String, dynamic>> getConversationList({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/conversations/list',
        // Backend controller membaca dari query, jadi kirim sebagai queryParameters
        queryParameters: {'page': page, 'limit': limit},
      );

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
        final lastCreatedAtStr = lastMessage != null
            ? (lastMessage['created_at'] as String?)
            : (conv['joined_at'] as String?);
        final timestamp = lastCreatedAtStr != null ? DateTime.parse(lastCreatedAtStr) : DateTime.now();

        final lastReadId = conv['last_read_message_id'] as String?;
        final lastMsgId = lastMessage != null ? lastMessage['id'] as String? : null;
        final unreadCount = (lastMsgId != null && lastReadId != lastMsgId) ? 1 : 0;

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
        final chatId = conv['id'] as String;

        // userId untuk navigasi ke chat; saat private pakai partner.id, saat group fallback ke conversation id
        final userId = !isGroup
            ? (partner?['id'] as String? ?? chatId)
            : chatId;

        return Chat(
          id: chatId,
          userId: userId,
          name: name,
          username: username,
          avatarUrl: avatarUrl,
          lastMessage: lastContent,
          timestamp: timestamp,
          unreadCount: unreadCount,
        );
      }).toList();

      return {
        'chats': chats,
        'pagination': pagination,
        'rawConversations': conversations, // untuk akses lastMessageId saat mark as read
      };
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Get messages for a specific chat
  Future<List<Message>> getMessages(String chatId) async {
    try {
      final response = await _apiService.get<List<dynamic>>('/chats/$chatId/messages');

      return (response).map((item) => Message.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Send a message
  Future<Message> sendMessage({required String receiverId, required String content}) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages',
        data: {'receiverId': receiverId, 'content': content},
      );

      return Message.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Mark messages as read in a conversation
  Future<bool> markAsRead({required String conversationId, required String messageId}) async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        '/messages/mark-read',
        data: {'conversationId': conversationId, 'messageId': messageId},
      );
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      await _apiService.delete<Map<String, dynamic>>('/chats/$chatId');
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Create or get a chat with a user
  Future<Chat> createOrGetChat(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/chats',
        data: {'userId': userId},
      );

      return Chat.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }
}
