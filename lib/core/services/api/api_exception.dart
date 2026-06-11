import 'package:dio/dio.dart';
import 'dart:developer' as developer;

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  /// Factory constructor to create ApiException from DioException
  factory ApiException.fromDioException(DioException exception) {
    developer.log('''
    ========== API ERROR ==========
    ${exception.response?.statusCode}
    ${exception.response?.data}
    ${exception.response.toString()}
    ===============================
    ''', name: 'ApiException');

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
        message = data?['message'] ?? 'unknown_error';
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

    return ApiException(message: message, statusCode: statusCode, data: data);
  }

  @override
  String toString() => message;
}
