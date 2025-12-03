import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A singleton class that provides a configured Dio instance for API requests.
class DioClient {
  static const Duration _kTimeout = Duration(seconds: 30);
  static const Map<String, String> _kDefaultHeaders = {'Accept': 'application/json'};
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  /// Factory constructor to return the singleton instance
  factory DioClient() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  DioClient._internal() {
    _dio = Dio();
    _configureDio();
  }

  /// Get the configured Dio instance
  Dio get dio => _dio;

  /// Configure Dio with base options and interceptors
  void _configureDio() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _kTimeout,
      receiveTimeout: _kTimeout,
      sendTimeout: _kTimeout,
      headers: _kDefaultHeaders,
    );

    // Add logging interceptor only in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // Optionally handle token refresh/logout
          }
          return handler.next(error);
        },
      ),
    );
  }
}
