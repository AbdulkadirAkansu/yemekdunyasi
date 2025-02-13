class AuthException implements Exception {
  final String message;
  final String statusCode;
  final String errorCode;

  const AuthException({
    required this.message,
    this.statusCode = '400',
    this.errorCode = 'auth_error',
  });

  @override
  String toString() => message;
} 