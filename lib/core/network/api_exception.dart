import 'package:dio/dio.dart';

/// Normalized error thrown by repositories so screens/providers never
/// need to know about Dio internals.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final Map<String, String> errors;

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        final errors = data['errors'];
        return ApiException(
          errors is String ? '$message: $errors' : message,
          statusCode: response.statusCode,
          errors: errors is Map
              ? errors.map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                )
              : {},
        );
      }
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiException(
        'The request timed out. Please try again.',
      ),
      DioExceptionType.connectionError => ApiException(
        'Unable to reach the server. Check your connection.',
      ),
      _ => ApiException(
        response != null
            ? 'Something went wrong (${response.statusCode}).'
            : 'Something went wrong.',
        statusCode: response?.statusCode,
      ),
    };
  }

  @override
  String toString() => errors.isEmpty
      ? message
      : '$message\n${errors.entries.map((e) => '${e.key}: ${e.value}').join('\n')}';
}
