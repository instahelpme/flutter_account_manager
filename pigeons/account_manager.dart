// ignore_for_file: one_member_abstracts

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/account_manager_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/lkrjangid/account_manager/AccountManagerApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.lkrjangid.account_manager'),
    swiftOut: 'ios/flutter_account_manager/Sources/flutter_account_manager/AccountManagerApi.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
// ============================================================================
// DATA CLASSES
// ============================================================================
/// Represents a user account with associated metadata
class AccountData {
  AccountData({
    required this.username,
    required this.accountType,
    this.displayName,
    this.userData,
  });

  final String username;
  final String accountType;
  final String? displayName;
  final Map<String?, String?>? userData;
}

/// Auth token request result
class AuthTokenResult {
  AuthTokenResult({
    this.token,
    this.errorCode,
    this.errorMessage,
    this.requiresUserInteraction,
  });

  final String? token;
  final int? errorCode;
  final String? errorMessage;
  final bool? requiresUserInteraction;
}

// ============================================================================
// FLUTTER -> NATIVE API
// ============================================================================

@HostApi()
abstract class AccountManagerHostApi {
  // Account Operations
  @asyncCallback
  bool addAccount(AccountData account, String password);

  @asyncCallback
  List<AccountData> getAccounts(String accountType);

  @asyncCallback
  AccountData? getAccount(String username, String accountType);

  @asyncCallback
  bool updateAccount(AccountData account);

  @asyncCallback
  bool removeAccount(AccountData account);

  @asyncCallback
  bool accountExists(String username, String accountType);

  // Credential Operations
  @asyncCallback
  bool updateCredentials(AccountData account, String newPassword);

  @asyncCallback
  bool validateCredentials(
    String username,
    String password,
    String accountType,
  );

  @asyncCallback
  bool clearCredentials(AccountData account);

  // Auth Token Operations
  @asyncCallback
  AuthTokenResult getAuthToken(AccountData account, String tokenType);

  @asyncCallback
  bool setAuthToken(AccountData account, String tokenType, String token);

  @asyncCallback
  bool invalidateAuthToken(String accountType, String token);

  @asyncCallback
  bool invalidateAllTokens(AccountData account, String tokenType);

  @asyncCallback
  List<String> getAvailableTokenTypes(AccountData account);

  // Platform-Specific
  @asyncCallback
  bool openAccountSettings();

  @asyncCallback
  bool isConfigured();

  @asyncCallback
  Map<String, bool> getPlatformCapabilities();
}

// ============================================================================
// NATIVE -> FLUTTER API (Callbacks)
// ============================================================================

@FlutterApi()
abstract class AccountCallbackFlutterApi {
  void onAccountAdded(AccountData account);
  void onAccountRemoved(AccountData account);
  void onAccountUpdated(AccountData account);
  void onAuthTokenExpired(AccountData account, String tokenType);
}
