// lib/core/api/api_exception.dart

sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException({required this.message, this.statusCode, this.code});
}

class AuthException extends ApiException {
  const AuthException({super.message = '认证失败', super.statusCode, super.code});
}

class ForbiddenException extends ApiException {
  const ForbiddenException({super.message = '无权限访问', super.statusCode, super.code});
}

class QuotaExceededException extends ApiException {
  const QuotaExceededException({super.message = '配额不足', super.statusCode, super.code});
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = '资源不存在', super.statusCode, super.code});
}

class ConflictException extends ApiException {
  const ConflictException({super.message = '数据冲突', super.statusCode, super.code});
}

class ValidationException extends ApiException {
  const ValidationException({super.message = '数据校验失败', super.statusCode, super.code});
}

class ServerException extends ApiException {
  const ServerException({super.message = '服务器异常', super.statusCode, super.code});
}

class NetworkException extends ApiException {
  const NetworkException({super.message = '网络连接失败', super.statusCode});
}
