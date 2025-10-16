import '../models/user.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';

/// Repository for user related operations
class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Get user profile by ID
  Future<User> getUserById(String userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/users/$userId',
      );
      return User.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    required String userId,
    String? name,
    String? bio,
    bool? isPrivate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (isPrivate != null) data['isPrivate'] = isPrivate;

      final response = await _apiService.put<Map<String, dynamic>>(
        '/users/$userId',
        data: data,
      );
      
      return User.fromJson(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Update user password
  Future<bool> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.put<Map<String, dynamic>>(
        '/users/$userId/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(String userId, String filePath) async {
    try {
      // TODO: Implement file upload
      // This would typically use FormData with Dio
      final response = await _apiService.post<Map<String, dynamic>>(
        '/users/$userId/avatar',
        data: {
          'filePath': filePath,
        },
      );
      return response['avatarUrl'] as String;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Search users
  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/users/search',
        queryParameters: {'q': query},
      );
      
      return (response)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Get random users (for discovery)
  Future<List<User>> getRandomUsers({int limit = 10}) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/users/random',
        queryParameters: {'limit': limit},
      );
      
      return (response)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }
}