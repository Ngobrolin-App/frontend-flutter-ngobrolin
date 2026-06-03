import '../models/user_model.dart';
import '../services/api/api_service.dart';
import 'package:dio/dio.dart';

/// Repository for user related operations
class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Get user profile by ID (backend expects POST /users/get-user with body)
  Future<UserModel> getUserById(String userId) async {
    return _apiService.post<UserModel>(
      '/users/get-user',
      data: {'userId': userId},
      parser: (data) => UserModel.fromMinimalJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// Update user profile details (name, bio, isPrivate)
  Future<UserModel> getCurrentProfile() async {
    return _apiService.post<UserModel>(
      '/users/profile/get',
      parser: (data) => UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? bio,
    bool? isPrivate,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (bio != null) data['bio'] = bio;
    if (isPrivate != null) data['isPrivate'] = isPrivate;

    return _apiService.post<UserModel>(
      '/users/profile/update',
      data: data,
      parser: (data) => UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// Update user password via the same edit-profile endpoint
  Future<bool> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiService.post<Map<String, dynamic>>(
      '/users/profile/update',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    return true;
  }

  /// Upload profile picture using multipart/form-data on edit-profile endpoint
  Future<String> uploadProfilePicture(String userId, String filePath) async {
    final formData = FormData.fromMap({'avatar': await MultipartFile.fromFile(filePath)});

    final response = await _apiService.post<Map<String, dynamic>>(
      '/users/profile/update',
      data: formData,
    );
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    return user.avatarUrl ?? '';
  }

  /// Search users with pagination
  Future<List<UserModel>> searchUsers(String query, {int page = 1, int limit = 20}) async {
    return _apiService.post<List<UserModel>>(
      '/users/search',
      data: {'q': query, 'page': page, 'limit': limit},
      parser: (data) {
        final usersList = data['users'] as List<dynamic>;
        return usersList
            .map((item) => UserModel.fromMinimalJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<void> registerFcmToken(String token) async {
    await _apiService.post<Map<String, dynamic>>(
      '/notifications/token/register',
      data: {'token': token},
    );
  }

  Future<void> deleteFcmToken(String token) async {
    await _apiService.post<Map<String, dynamic>>(
      '/notifications/token/delete',
      data: {'token': token},
    );
  }
}
