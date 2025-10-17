import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A singleton class that provides a configured Dio instance for API requests.
class DioClient {
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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );

    // Add logging interceptor
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

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token from secure storage or shared preferences
          // final token = await _getToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Handle common errors like 401 Unauthorized
          if (error.response?.statusCode == 401) {
            // Handle token refresh or logout
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Update authorization token
  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}
