import '../models/chat.dart';
import '../models/message.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';

/// Repository for chat related operations
class ChatRepository {
  final ApiService _apiService;

  ChatRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Get chat list for current user
  Future<List<Chat>> getChatList() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/chats',
      );
      
      return (response)
          .map((item) => Chat.fromJson(item as Map<String, dynamic>))
          .toList();
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
      final response = await _apiService.get<List<dynamic>>(
        '/chats/$chatId/messages',
      );
      
      return (response)
          .map((item) => Message.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Send a message
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages',
        data: {
          'receiverId': receiverId,
          'content': content,
        },
      );
      
      return Message.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Mark messages as read
  Future<bool> markAsRead(String chatId) async {
    try {
      await _apiService.put<Map<String, dynamic>>(
        '/chats/$chatId/read',
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
      await _apiService.delete<Map<String, dynamic>>(
        '/chats/$chatId',
      );
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
        data: {
          'userId': userId,
        },
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