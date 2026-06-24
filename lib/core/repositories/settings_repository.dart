import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/api_response.dart';
import 'package:ngobrolin_app/core/models/paginated_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';

class SettingsRepository {
  final ApiService _apiService;
  static const String _localeLanguageCodeKey = 'app_locale_language_code';
  static const String _localeCountryCodeKey = 'app_locale_country_code';

  SettingsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Locale> getLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeLanguageCodeString = prefs.getString(_localeLanguageCodeKey);
      final localeCountryCodeString = prefs.getString(_localeCountryCodeKey);
      if (localeLanguageCodeString == null ||
          localeLanguageCodeString.isEmpty ||
          localeCountryCodeString == null ||
          localeCountryCodeString.isEmpty) {
        return AppLocalizations.defaultLocale; // Default locale
      }
      return Locale(localeLanguageCodeString, localeCountryCodeString);
    } catch (_) {
      return AppLocalizations.defaultLocale;
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeLanguageCodeKey, locale.languageCode);
      await prefs.setString(_localeCountryCodeKey, locale.countryCode ?? '');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<ApiResponse<UserModel>> getPrivateAccountSetting() async {
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

  Future<ApiResponse<UserModel>> updatePrivateAccountSetting(
    bool isPrivate,
  ) async {
    return _apiService.post<ApiResponse<UserModel>>(
      '/users/profile/update',
      data: {'isPrivate': isPrivate},
      parser: (response) {
        return ApiResponse<UserModel>.fromJson(response, (data) {
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          return UserModel.fromJson(mappedData);
        });
      },
    );
  }

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
          final mappedData =
              data as Map<String, dynamic>? ?? <String, dynamic>{};
          final blockedUsersList =
              mappedData['blockedUsers'] as List<dynamic>? ?? [];
          final pagination =
              mappedData['pagination'] as Map<String, dynamic>? ?? {};

          final items = blockedUsersList
              .map(
                (item) => UserModel.fromMinimalJson(
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
                ),
              )
              .toList();

          return PaginatedResult<UserModel>(
            items: items,
            total: (pagination['total'] as int?) ?? 0,
            page: (pagination['page'] as int?) ?? 1,
            limit: (pagination['limit'] as int?) ?? 20,
            totalPages: (pagination['totalPages'] as int?) ?? 1,
          );
        });
      },
    );
  }

  Future<ApiResponse<void>> blockUser(String userId) async {
    return await _apiService.post<ApiResponse<void>>(
      '/users/block',
      data: {'userId': userId},
      parser: (response) {
        return ApiResponse<void>.fromJson(response, (data) => null);
      },
    );
  }

  Future<ApiResponse<void>> unblockUser(String userId) async {
    return await _apiService.post<ApiResponse<void>>(
      '/users/unblock',
      data: {'userId': userId},
      parser: (response) {
        return ApiResponse<void>.fromJson(response, (data) => null);
      },
    );
  }

  Future<bool> isUserBlocked(String userId) async {
    try {
      await _apiService.post<ApiResponse<UserModel>>(
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
