sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode, super.cause});

  final int? statusCode;
}

final class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}
