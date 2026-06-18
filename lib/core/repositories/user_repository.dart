import 'package:ngobrolin_app/core/models/api_response.dart';
import 'package:ngobrolin_app/core/models/paginated_result.dart';
import '../models/user_model.dart';
import '../services/api/api_service.dart';
import 'package:dio/dio.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<ApiResponse<UserModel>> getUserById(String userId) async {
    return _apiService.post<ApiResponse<UserModel>>(
      '/users/get-user',
      data: {'userId': userId},
      parser: (response) {
        return ApiResponse<UserModel>.fromJson(response, (data) {
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          return UserModel.fromJson(mappedData);
        });
      },
    );
  }

  Future<ApiResponse<UserModel>> getCurrentProfile() async {
    return _apiService.post<ApiResponse<UserModel>>(
      '/users/profile/get',
      parser: (response) {
        return ApiResponse<UserModel>.fromJson(response, (data) {
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          return UserModel.fromJson(mappedData);
        });
      },
    );
  }

  Future<ApiResponse<UserModel>> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? bio,
    bool? isPrivate,
    String? currentPassword,
    String? newPassword,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (bio != null) data['bio'] = bio;
    if (isPrivate != null) data['isPrivate'] = isPrivate;
    if (currentPassword != null && newPassword != null) {
      data['currentPassword'] = currentPassword;
      data['newPassword'] = newPassword;
    }

    return _apiService.post<ApiResponse<UserModel>>(
      '/users/profile/update',
      data: data,
      parser: (response) {
        return ApiResponse<UserModel>.fromJson(response, (data) {
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          return UserModel.fromJson(mappedData);
        });
      },
    );
  }

  Future<ApiResponse<UserModel>> uploadProfilePicture(
    String userId,
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });

    return _apiService.post<ApiResponse<UserModel>>(
      '/users/profile/update',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      parser: (response) {
        return ApiResponse<UserModel>.fromJson(response, (data) {
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          return UserModel.fromJson(mappedData);
        });
      },
    );
  }

  Future<ApiResponse<PaginatedResult<UserModel>>> searchUsers(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    return _apiService.post<ApiResponse<PaginatedResult<UserModel>>>(
      '/users/search',
      data: {'q': query, 'page': page, 'limit': limit},
      parser: (response) {
        return ApiResponse<PaginatedResult<UserModel>>.fromJson(response, (
          data,
        ) {
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          final users = mappedData['users'] as List<dynamic>? ?? [];
          final pagination =
              mappedData['pagination'] as Map<String, dynamic>? ?? {};

          final result = users
              .map(
                (item) => UserModel.fromMinimalJson(
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
                ),
              )
              .toList();

          return PaginatedResult<UserModel>(
            items: result,
            total: (pagination['total'] as int?) ?? 0,
            page: (pagination['page'] as int?) ?? 1,
            limit: (pagination['limit'] as int?) ?? 20,
            totalPages: (pagination['totalPages'] as int?) ?? 1,
          );
        });
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
