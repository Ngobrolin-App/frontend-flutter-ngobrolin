import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/models/api_response.dart';
import 'package:ngobrolin_app/core/models/paginated_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';

/// Repository for settings related operations
class SettingsRepository {
  final ApiService _apiService;
  static const String _localeKey = 'app_locale';

  SettingsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Get app locale
  Future<Locale> getLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);
      if (localeString == null) {
        return const Locale('id'); // Default locale
      }
      return Locale(localeString);
    } catch (e) {
      return const Locale('id'); // Default locale on error
    }
  }

  /// Set app locale
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Get private account setting
  Future<ApiResponse<UserModel>> getPrivateAccountSetting() async {
    // Backend menggunakan POST /users/profile/get
    return _apiService.post<ApiResponse<UserModel>>(
      '/users/profile/get',
      parser: (response) {
        return ApiResponse<UserModel>.fromJson(response, (data) {
          final user = UserModel.fromJson(data as Map<String, dynamic>);
          return user;
        });
      },
    );
  }

  /// Update private account setting
  Future<ApiResponse<UserModel>> updatePrivateAccountSetting(
    bool isPrivate,
  ) async {
    // Backend menggunakan POST /users/profile/update
    return _apiService.post<ApiResponse<UserModel>>(
      '/users/profile/update',
      data: {'isPrivate': isPrivate},
      parser: (response) {
        return ApiResponse<UserModel>.fromJson(response, (data) {
          final user = UserModel.fromJson(data as Map<String, dynamic>);
          return user;
        });
      },
    );
  }

  /// Get blocked users (POST /users/blocked/list) with pagination
  Future<ApiResponse<PaginatedResult<UserModel>>> getBlockedUsers({
    int page = 1,
    int limit = 20,
  }) async {
    return _apiService.post<ApiResponse<PaginatedResult<UserModel>>>(
      '/users/blocked/list',
      data: {'page': page, 'limit': limit},
      parser: (response) {
        return ApiResponse<PaginatedResult<UserModel>>.fromJson(response, (
          data,
        ) {
          final blockedUsersList = data['blockedUsers'] as List<dynamic>? ?? [];
          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

          final items = blockedUsersList
              .map(
                (item) => UserModel.fromMinimalJson(
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
                ),
              )
              .toList();

          return PaginatedResult<UserModel>(
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

  /// Block a user (POST /users/block)
  Future<ApiResponse<void>> blockUser(String userId) async {
    return await _apiService.post<ApiResponse<void>>(
      '/users/block',
      data: {'userId': userId},
      parser: (response) {
        return ApiResponse<void>.fromJson(response, (data) => null);
      },
    );
  }

  /// Unblock a user (POST /users/unblock)
  Future<ApiResponse<void>> unblockUser(String userId) async {
    return await _apiService.post<ApiResponse<void>>(
      '/users/unblock',
      data: {'userId': userId},
      parser: (response) {
        return ApiResponse<void>.fromJson(response, (data) => null);
      },
    );
  }

  /// Check blocked (dua arah) via /users/get-user: 403 => blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      await _apiService.post<ApiResponse<UserModel>>(
        '/users/get-user',
        data: {'userId': userId},
        parser: (response) {
          return ApiResponse<UserModel>.fromJson(response, (data) {
            final user = UserModel.fromJson(data as Map<String, dynamic>);
            return user;
          });
        },
      );
      return false;
    } catch (e) {
      if (e is ApiException) {
        if (e.statusCode == 403) {
          return true;
        }
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }
}
