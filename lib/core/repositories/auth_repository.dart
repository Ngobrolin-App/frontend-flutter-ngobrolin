import 'package:ngobrolin_app/core/models/api_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/api/api_service.dart';

/// Repository for authentication related operations
class AuthRepository {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Sign in with username or email and password
  Future<ApiResponse<AuthResponse>> signIn(
    String usernameOrEmail,
    String password,
  ) async {
    final response = await _apiService.post<ApiResponse<AuthResponse>>(
      '/auth/login',
      data: {'usernameOrEmail': usernameOrEmail, 'password': password},
      parser: (response) {
        // print('AuthRepository - /auth/login response: $response');
        return ApiResponse<AuthResponse>.fromJson(response, (data) {
          final authResponse = AuthResponse.fromJson(
            data as Map<String, dynamic>,
          );
          return authResponse;
        });
      },
    );

    if (response.data != null) {
      await _saveAuthData(response.data!);
    }

    return response;
  }

  /// Register a new user
  Future<ApiResponse<AuthResponse>> signUp({
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
      parser: (response) {
        // print('AuthRepository - /auth/register response: $response');
        return ApiResponse<AuthResponse>.fromJson(response, (data) {
          final authResponse = AuthResponse.fromJson(
            data as Map<String, dynamic>,
          );
          return authResponse;
        });
      },
    );

    if (response.data != null) {
      await _saveAuthData(response.data!);
    }

    return response;
  }

  /// Request password reset
  Future<ApiResponse> forgotPassword(String email) async {
    return await _apiService.post<ApiResponse>(
      '/auth/forgot-password',
      data: {'email': email},
      parser: (response) => ApiResponse.fromJson(response, null),
    );
  }

  /// Reset password
  Future<ApiResponse> resetPassword(String token, String newPassword) async {
    return await _apiService.post<ApiResponse>(
      '/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
      parser: (response) => ApiResponse.fromJson(response, null),
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    // Clear stored token and user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Get the current authentication token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get the current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userKey);
      if (userJsonStr == null) return null;

      final Map<String, dynamic> decoded =
          jsonDecode(userJsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authResponse.token);
    await prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));
  }

  /// Check if the user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}
