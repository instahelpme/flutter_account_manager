import 'dart:async';

import 'package:flutter/services.dart';
import 'generated/account_manager_api.g.dart';
import 'exceptions.dart';
import 'models/account.dart';
import 'models/account_event.dart';

/// Main entry point for the Account Manager Plugin.
///
/// Use [AccountManagerPlugin.instance] to access the singleton.
///
/// ```dart
/// final am = AccountManagerPlugin.instance;
/// await am.initialize();
/// await am.addAccount(Account(username: 'user@example.com', accountType: 'com.example.app'), 'password');
/// ```
class AccountManagerPlugin {
  AccountManagerPlugin._() : _hostApi = AccountManagerHostApi();

  /// For testing — inject a custom [AccountManagerHostApi].
  AccountManagerPlugin.withHostApi(AccountManagerHostApi hostApi)
      : _hostApi = hostApi;

  static final AccountManagerPlugin _instance = AccountManagerPlugin._();

  /// Singleton instance.
  static AccountManagerPlugin get instance => _instance;

  final AccountManagerHostApi _hostApi;

  final StreamController<AccountEvent> _accountEventController =
      StreamController<AccountEvent>.broadcast();

  /// Stream of account-related events (added, removed, updated, token expired).
  Stream<AccountEvent> get accountEvents => _accountEventController.stream;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  static const _configChannel =
      MethodChannel('flutter_account_manager/config');

  /// Initialises the plugin. Must be called before any other operations.
  ///
  /// [keychainAccessGroup] (iOS only) sets the Keychain Access Group used for
  /// all subsequent Keychain operations. Pass the group that matches the
  /// entitlement in your app — e.g. `'me.instahelp'` — to enable cross-app
  /// credential sharing. Has no effect on Android.
  Future<void> initialize({String? keychainAccessGroup}) async {
    if (keychainAccessGroup != null) {
      try {
        await _configChannel.invokeMethod<void>('configure', {
          'keychainAccessGroup': keychainAccessGroup,
        });
      } catch (_) {
        // Silently ignore — Android has no keychain access groups, and the
        // channel handler may not be registered on all platforms.
      }
    }

    AccountCallbackFlutterApi.setUp(
        _AccountCallbackHandler(_accountEventController));

    final configured = await _hostApi.isConfigured();
    if (!configured) {
      throw const PluginNotConfiguredException(
        message:
            'Plugin not properly configured. Check AndroidManifest.xml and Info.plist.',
      );
    }
  }

  /// Releases resources. Call when the plugin is no longer needed.
  Future<void> dispose() async {
    await _accountEventController.close();
  }

  // ---------------------------------------------------------------------------
  // Account Management
  // ---------------------------------------------------------------------------

  /// Creates a new account with the given [password].
  ///
  /// Returns `true` if the account was created successfully.
  /// Throws [AccountAlreadyExistsException] if the account already exists.
  Future<bool> addAccount(Account account, String password) {
    return _hostApi.addAccount(account.toData(), password);
  }

  /// Retrieves all accounts of the specified [accountType].
  Future<List<Account>> getAccounts(String accountType) async {
    final list = await _hostApi.getAccounts(accountType);
    return list.map(Account.fromData).toList();
  }

  /// Retrieves a specific account by [username] and [accountType].
  /// Returns `null` if no matching account exists.
  Future<Account?> getAccount(String username, String accountType) async {
    final data = await _hostApi.getAccount(username, accountType);
    return data != null ? Account.fromData(data) : null;
  }

  /// Updates an existing account's metadata.
  Future<bool> updateAccount(Account account) {
    return _hostApi.updateAccount(account.toData());
  }

  /// Removes an account from the system (including its tokens and sync data).
  Future<bool> removeAccount(Account account) {
    return _hostApi.removeAccount(account.toData());
  }

  /// Returns `true` if an account with [username] and [accountType] exists.
  Future<bool> accountExists(String username, String accountType) {
    return _hostApi.accountExists(username, accountType);
  }

  // ---------------------------------------------------------------------------
  // Credentials
  // ---------------------------------------------------------------------------

  /// Updates the password for an existing account.
  Future<bool> updateCredentials(Account account, String newPassword) {
    return _hostApi.updateCredentials(account.toData(), newPassword);
  }

  /// Validates credentials without storing them.
  Future<bool> validateCredentials(
      String username, String password, String accountType) {
    return _hostApi.validateCredentials(username, password, accountType);
  }

  /// Clears stored credentials while keeping account metadata.
  Future<bool> clearCredentials(Account account) {
    return _hostApi.clearCredentials(account.toData());
  }

  // ---------------------------------------------------------------------------
  // Auth Tokens
  // ---------------------------------------------------------------------------

  /// Retrieves an auth token for [account] of [tokenType].
  ///
  /// Returns the token string, or `null` if no token is available.
  /// Throws [AuthenticationRequiredException] if user interaction is needed.
  Future<String?> getAuthToken(Account account, String tokenType) async {
    final result = await _hostApi.getAuthToken(account.toData(), tokenType);
    if (result.requiresUserInteraction == true) {
      throw AuthenticationRequiredException(
        message: result.errorMessage ?? 'User authentication required',
      );
    }
    return result.token;
  }

  /// Stores or updates an auth token for [account].
  Future<bool> setAuthToken(Account account, String tokenType, String token) {
    return _hostApi.setAuthToken(account.toData(), tokenType, token);
  }

  /// Invalidates a specific [token] of [accountType].
  Future<bool> invalidateAuthToken(String accountType, String token) {
    return _hostApi.invalidateAuthToken(accountType, token);
  }

  /// Invalidates all tokens of [tokenType] for [account].
  Future<bool> invalidateAllTokens(Account account, String tokenType) {
    return _hostApi.invalidateAllTokens(account.toData(), tokenType);
  }

  /// Returns all available token types for [account].
  Future<List<String>> getAvailableTokenTypes(Account account) {
    return _hostApi.getAvailableTokenTypes(account.toData());
  }

  // ---------------------------------------------------------------------------
  // Platform-Specific
  // ---------------------------------------------------------------------------

  /// Opens the system account settings screen (Android only).
  /// Returns `false` on iOS.
  Future<bool> openAccountSettings() {
    return _hostApi.openAccountSettings();
  }

  /// Returns a map of platform-specific capability flags.
  Future<Map<String, bool>> getPlatformCapabilities() {
    return _hostApi.getPlatformCapabilities();
  }
}

// ---------------------------------------------------------------------------
// Internal FlutterApi implementations
// ---------------------------------------------------------------------------


class _AccountCallbackHandler implements AccountCallbackFlutterApi {
  _AccountCallbackHandler(this._controller);

  final StreamController<AccountEvent> _controller;

  @override
  void onAccountAdded(AccountData account) {
    _controller.add(AccountAddedEvent(account: Account.fromData(account)));
  }

  @override
  void onAccountRemoved(AccountData account) {
    _controller.add(AccountRemovedEvent(account: Account.fromData(account)));
  }

  @override
  void onAccountUpdated(AccountData account) {
    _controller.add(AccountUpdatedEvent(account: Account.fromData(account)));
  }

  @override
  void onAuthTokenExpired(AccountData account, String tokenType) {
    _controller.add(AuthTokenExpiredEvent(
      account: Account.fromData(account),
      tokenType: tokenType,
    ));
  }
}
