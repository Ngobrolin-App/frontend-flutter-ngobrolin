import '../models/user.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';
import 'package:dio/dio.dart';

/// Repository for user related operations
class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Get user profile by ID (backend expects POST /users/get-user with body)
  Future<User> getUserById(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>('/users/get-user', data: {'userId': userId});
      return User.fromMinimalJson(response['user'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Update user profile details (name, bio, isPrivate)
  Future<User> getCurrentProfile() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>('/users/profile/get');
      return User.fromJson(response['user'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

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

      final response =
          await _apiService.post<Map<String, dynamic>>('/users/profile/update', data: data);
      return User.fromJson(response['user'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Update user password via the same edit-profile endpoint
  Future<bool> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        '/users/profile/update',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return true;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Upload profile picture using multipart/form-data on edit-profile endpoint
  Future<String> uploadProfilePicture(String userId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response =
          await _apiService.post<Map<String, dynamic>>('/users/profile/update', data: formData);
      final user = User.fromJson(response['user'] as Map<String, dynamic>);
      return user.avatarUrl ?? '';
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Search users with pagination
  Future<List<User>> searchUsers(String query, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/users/search',
        data: {
          'q': query,
          'page': page,
          'limit': limit,
        },
      );

      final usersList = response['users'] as List<dynamic>;
      return usersList.map((item) => User.fromMinimalJson(item as Map<String, dynamic>)).toList();
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

      return (response).map((item) => User.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }
}
