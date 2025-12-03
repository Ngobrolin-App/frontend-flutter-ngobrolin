import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';

/// Repository for settings related operations
class SettingsRepository {
  final ApiService _apiService;
  static const String _localeKey = 'app_locale';

  SettingsRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

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
  Future<List<User>> getBlockedUsers({int page = 1, int limit = 20}) async {
    return _apiService.post<List<User>>(
      '/users/blocked/list',
      data: {
        'page': page,
        'limit': limit,
      },
      parser: (response) {
        // Tahan terhadap variasi payload: `blockedUsers`, `users`, atau `data`
        final dynamicRawList =
            response['blockedUsers'] ?? response['users'] ?? response['data'] ?? [];

        final list = (dynamicRawList is List) ? dynamicRawList : <dynamic>[];

        return list
            .map((item) {
              final map = (item is Map<String, dynamic>) ? item : <String, dynamic>{};
              // Item mungkin langsung user, atau dibungkus dalam `blockedUser`
              final userJson = map.containsKey('blockedUser')
                  ? (map['blockedUser'] as Map<String, dynamic>? ?? <String, dynamic>{})
                  : map;
              return User.fromMinimalJson(userJson);
            })
            .toList();
      },
    );
  }

  /// Block a user (POST /users/block)
  Future<bool> blockUser(String userId) async {
    await _apiService.post<Map<String, dynamic>>('/users/block', data: {'userId': userId});
    return true;
  }

  /// Unblock a user (POST /users/unblock)
  Future<bool> unblockUser(String userId) async {
    await _apiService.post<Map<String, dynamic>>('/users/unblock', data: {'userId': userId});
    return true;
  }

  /// Check blocked (dua arah) via /users/get-user: 403 => blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      await _apiService.post<Map<String, dynamic>>('/users/get-user', data: {'userId': userId});
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
