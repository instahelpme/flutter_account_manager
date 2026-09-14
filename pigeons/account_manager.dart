// ignore_for_file: one_member_abstracts

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/account_manager_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/com/lkrjangid/account_manager/AccountManagerApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.lkrjangid.account_manager',
  ),
  swiftOut: 'ios/Classes/AccountManagerApi.g.swift',
  swiftOptions: SwiftOptions(),
))

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
  @async
  bool addAccount(AccountData account, String password);

  @async
  List<AccountData> getAccounts(String accountType);

  @async
  AccountData? getAccount(String username, String accountType);

  @async
  bool updateAccount(AccountData account);

  @async
  bool removeAccount(AccountData account);

  @async
  bool accountExists(String username, String accountType);

  // Credential Operations
  @async
  bool updateCredentials(AccountData account, String newPassword);

  @async
  bool validateCredentials(
      String username, String password, String accountType);

  @async
  bool clearCredentials(AccountData account);

  // Auth Token Operations
  @async
  AuthTokenResult getAuthToken(AccountData account, String tokenType);

  @async
  bool setAuthToken(AccountData account, String tokenType, String token);

  @async
  bool invalidateAuthToken(String accountType, String token);

  @async
  bool invalidateAllTokens(AccountData account, String tokenType);

  @async
  List<String> getAvailableTokenTypes(AccountData account);

  // Platform-Specific
  @async
  bool openAccountSettings();

  @async
  bool isConfigured();

  @async
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
