class ApiResponse<T> {
  final int code;
  final String statusCode;
  final String message;
  final T? data;
  final List<dynamic>? errors;

  const ApiResponse({
    required this.code,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int,
      statusCode: json['statusCode'] as String,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'] as List<dynamic>?,
    );
  }

  bool get isSuccess => code >= 200 && code < 300;
}
