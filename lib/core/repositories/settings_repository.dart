import 'package:flutter/material.dart';
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
  Future<bool> getPrivateAccountSetting() async {
    // Backend menggunakan POST /users/profile/get
    return _apiService.post<bool>(
      '/users/profile/get',
      parser: (response) {
        final user = response['user'] as Map<String, dynamic>? ?? {};
        return (user['isPrivate'] as bool?) ?? false;
      },
    );
  }

  /// Update private account setting
  Future<bool> updatePrivateAccountSetting(bool isPrivate) async {
    // Backend menggunakan POST /users/profile/update
    await _apiService.post<Map<String, dynamic>>(
      '/users/profile/update',
      data: {'isPrivate': isPrivate},
    );
    return true;
  }

  /// Get blocked users (POST /users/blocked/list) with pagination
  Future<PaginatedResult<UserModel>> getBlockedUsers({
    int page = 1,
    int limit = 20,
  }) async {
    return _apiService.post<PaginatedResult<UserModel>>(
      '/users/blocked/list',
      data: {'page': page, 'limit': limit},
      parser: (response) {
        final blockedUsersList =
            response['blockedUsers'] as List<dynamic>? ?? [];
        final pagination =
            response['pagination'] as Map<String, dynamic>? ?? {};

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
      },
    );
  }

  /// Block a user (POST /users/block)
  Future<bool> blockUser(String userId) async {
    await _apiService.post<Map<String, dynamic>>(
      '/users/block',
      data: {'userId': userId},
    );
    return true;
  }

  /// Unblock a user (POST /users/unblock)
  Future<bool> unblockUser(String userId) async {
    await _apiService.post<Map<String, dynamic>>(
      '/users/unblock',
      data: {'userId': userId},
    );
    return true;
  }

  /// Check blocked (dua arah) via /users/get-user: 403 => blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        '/users/get-user',
        data: {'userId': userId},
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
