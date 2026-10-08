/// Base exception for all account manager plugin errors.
sealed class AccountManagerException implements Exception {
  const AccountManagerException({
    required this.message,
    this.errorCode,
    this.details,
  });

  final String message;
  final int? errorCode;
  final String? details;

  @override
  String toString() => '$runtimeType(message: $message, errorCode: $errorCode)';
}

/// Account with the same username+type already exists. Code range: 1000–1099.
class AccountAlreadyExistsException extends AccountManagerException {
  const AccountAlreadyExistsException({
    required super.message,
    super.errorCode = 1001,
  });
}

/// No account found matching the given criteria. Code range: 1000–1099.
class AccountNotFoundException extends AccountManagerException {
  const AccountNotFoundException({
    required super.message,
    super.errorCode = 1002,
  });
}

/// Re-authentication required (user interaction needed). Code range: 1100–1199.
class AuthenticationRequiredException extends AccountManagerException {
  const AuthenticationRequiredException({
    required super.message,
    super.errorCode = 1100,
  });
}

/// Plugin is not properly configured (missing manifest/plist entries). Code range: 1500–1599.
class PluginNotConfiguredException extends AccountManagerException {
  const PluginNotConfiguredException({
    required super.message,
    super.errorCode = 1500,
  });
}

/// Credential storage or retrieval failure. Code range: 1300–1399.
class CredentialException extends AccountManagerException {
  const CredentialException({
    required super.message,
    super.errorCode = 1300,
  });
}

/// Requested operation is not supported on this platform. Code range: 1500–1599.
class UnsupportedOperationException extends AccountManagerException {
  const UnsupportedOperationException({
    required super.message,
    super.errorCode = 1501,
  });
}
