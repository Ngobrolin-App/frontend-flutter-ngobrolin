import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'dio_client.dart';

/// Base class for all API services
class ApiService {
  final Dio _dio;

  ApiService() : _dio = DioClient().dio;

  /// Perform a GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? parser,
  }) async {
    return _request<T>(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  /// Perform a POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? parser,
  }) async {
    return _request<T>(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  /// Perform a PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? parser,
  }) async {
    return _request<T>(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  /// Perform a DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? parser,
  }) async {
    return _request<T>(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  /// Perform a PATCH request
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? parser,
  }) async {
    return _request<T>(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser,
    );
  }

  Future<T> _request<T>(
    Future<Response> Function() request,
    T Function(dynamic data)? parser,
  ) async {
    try {
      final response = await request();

      if (parser != null) {
        return parser(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
