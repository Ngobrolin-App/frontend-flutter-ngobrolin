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
        return const Locale('en'); // Default locale
      }
      return Locale(localeString);
    } catch (e) {
      return const Locale('en'); // Default locale on error
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
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/settings/privacy',
      );
      return response['isPrivate'] as bool;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Update private account setting
  Future<bool> updatePrivateAccountSetting(bool isPrivate) async {
    try {
      await _apiService.put<Map<String, dynamic>>(
        '/settings/privacy',
        data: {
          'isPrivate': isPrivate,
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

  /// Get blocked users
  Future<List<User>> getBlockedUsers() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/settings/blocked-users',
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

  /// Block a user
  Future<bool> blockUser(String userId) async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        '/settings/blocked-users',
        data: {
          'userId': userId,
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

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    try {
      await _apiService.delete<Map<String, dynamic>>(
        '/settings/blocked-users/$userId',
      );
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/settings/blocked-users/$userId/status',
      );
      return response['isBlocked'] as bool;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }
}