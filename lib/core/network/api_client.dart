import 'package:dio/dio.dart';

import '../error/app_exception.dart';

abstract final class ApiClient {
  static const baseUrl = 'https://taskmanager.uat-lplusltd.com';

  static Dio create() => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      )
        ..interceptors.add(
          InterceptorsWrapper(
            onError: (error, handler) => handler.reject(
              error.copyWith(error: _mapError(error)),
            ),
          ),
        );

  static AppException _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Check your internet connection and try again.', cause: error);
    }
    return ServerException(
      'The server could not complete your request. Please try again.',
      statusCode: error.response?.statusCode,
      cause: error,
    );
  }
}
