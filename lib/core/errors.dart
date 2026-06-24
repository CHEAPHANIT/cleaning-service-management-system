class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class ServerException extends AppException {
  ServerException(super.message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class CacheException extends AppException {
  CacheException(super.message);
}

class UnknownException extends AppException {
  UnknownException(super.message);
}
