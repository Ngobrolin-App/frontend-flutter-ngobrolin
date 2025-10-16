import 'package:dio/dio.dart';

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  /// Factory constructor to create ApiException from DioException
  factory ApiException.fromDioException(DioException exception) {
    String message = 'Something went wrong';
    int? statusCode = exception.response?.statusCode;
    dynamic data = exception.response?.data;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              message = data?['message'] ?? 'Bad request';
              break;
            case 401:
              message = 'Unauthorized. Please login again.';
              break;
            case 403:
              message = 'Forbidden. You don\'t have permission to access this resource.';
              break;
            case 404:
              message = 'Resource not found.';
              break;
            case 500:
            case 501:
            case 502:
            case 503:
              message = 'Server error. Please try again later.';
              break;
            default:
              message = data?['message'] ?? 'Server error with status code: $statusCode';
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.badCertificate:
        message = 'Bad certificate. Please check your connection security.';
        break;
      case DioExceptionType.unknown:
      default:
        if (exception.message != null) {
          message = exception.message!;
        }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  @override
  String toString() => 'ApiException: $message';
}