import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/api/api_exception.dart';
import '../services/api/api_service.dart';
import '../services/api/dio_client.dart';

/// Repository for authentication related operations
class AuthRepository {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Sign in with username and password
  Future<AuthResponse> signIn(String username, String password) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response);

      // Save token and user data
      await _saveAuthData(authResponse);

      // Update Dio client with token
      DioClient().updateToken(authResponse.token);

      return authResponse;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Register a new user
  Future<AuthResponse> signUp({
    required String username,
    required String name,
    required String password,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'username': username, 'name': name, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response);

      // Save token and user data
      await _saveAuthData(authResponse);

      // Update Dio client with token
      DioClient().updateToken(authResponse.token);

      return authResponse;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Request password reset
  Future<bool> forgotPassword(String email) async {
    try {
      await _apiService.post<Map<String, dynamic>>('/auth/forgot-password', data: {'email': email});
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Clear token from API client
      DioClient().clearToken();

      // Clear stored token and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
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
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userKey);
      if (userJsonStr == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(userJsonStr) as Map<String, dynamic>;
      return User.fromJson(decoded);
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
