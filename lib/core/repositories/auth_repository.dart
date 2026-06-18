import 'package:ngobrolin_app/core/models/api_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/api/api_service.dart';
import 'dart:developer' as developer;

/// Repository handling infrastructure calls for remote network authentication,
/// registration pipelines, and local cache session storage keys.
class AuthRepository {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Authenticates credentials and automatically caches structural tokens on success.
  Future<ApiResponse<AuthResponse>> login(
    String usernameOrEmail,
    String password,
  ) async {
    final response = await _apiService.post<ApiResponse<AuthResponse>>(
      '/auth/login',
      data: {'usernameOrEmail': usernameOrEmail, 'password': password},
      parser: (json) {
        return ApiResponse<AuthResponse>.fromJson(json, (data) {
          return AuthResponse.fromJson(data as Map<String, dynamic>);
        });
      },
    );

    if (response.data != null) {
      await _saveAuthData(response.data!);
    }

    return response;
  }

  /// Registers a new user account profile and caches session entities.
  Future<ApiResponse<AuthResponse>> register({
    required String username,
    required String email,
    required String name,
    required String password,
  }) async {
    final response = await _apiService.post<ApiResponse<AuthResponse>>(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'name': name,
        'password': password,
      },
      parser: (json) {
        return ApiResponse<AuthResponse>.fromJson(json, (data) {
          return AuthResponse.fromJson(data as Map<String, dynamic>);
        });
      },
    );

    if (response.data != null) {
      await _saveAuthData(response.data!);
    }

    return response;
  }

  /// Dispatches a standard password adjustment email distribution request link.
  Future<ApiResponse> forgotPassword(String email) async {
    return await _apiService.post<ApiResponse>(
      '/auth/forgot-password',
      data: {'email': email},
      parser: (json) => ApiResponse.fromJson(json, null),
    );
  }

  /// Submits updated token credentials alongside new password constraints.
  Future<ApiResponse> resetPassword(String token, String newPassword) async {
    return await _apiService.post<ApiResponse>(
      '/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
      parser: (json) => ApiResponse.fromJson(json, null),
    );
  }

  /// Purges local stored session keys and invalidates structural persistence.
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      developer.log(
        'AuthRepository: Auth data successfully cleared from storage.',
        name: 'AuthRepository',
      );
    } catch (e) {
      developer.log(
        'AuthRepository: Failed to clear auth data: $e',
        name: 'AuthRepository',
      );
      rethrow;
    }
  }

  /// Reads the active authorization token sequence string from local disks.
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      developer.log(
        'AuthRepository: Error reading token: $e',
        name: 'AuthRepository',
      );
      return null;
    }
  }

  /// Decodes and returns structural current user model schemas from device memory.
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userKey);
      if (userJsonStr == null) return null;

      final Map<String, dynamic> decoded =
          jsonDecode(userJsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(decoded);
    } catch (e) {
      developer.log(
        'AuthRepository: Error reading user model: $e',
        name: 'AuthRepository',
      );
      return null;
    }
  }

  /// Internally writes token packets and mapped JSON parameters to hardware devices securely.
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, authResponse.token);
      await prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));
      developer.log(
        'AuthRepository: Token and user data encrypted & stored.',
        name: 'AuthRepository',
      );
    } catch (e) {
      developer.log(
        'AuthRepository: Critical failure saving auth tokens: $e',
        name: 'AuthRepository',
      );
    }
  }

  /// Verifies if an operational token exists locally inside the preference layers.
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
