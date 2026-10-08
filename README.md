# flutter_account_manager

A Flutter plugin for **cross-platform account management, authentication, and credential storage** using native platform APIs.

| Platform | Account Storage | Token Storage |
|----------|----------------|---------------|
| Android  | `AccountManager` system service | `AccountManager` auth token cache |
| iOS      | Keychain Services | Keychain Services |

---

## Why This Plugin?

Managing user accounts in a cross-platform Flutter app typically means rolling your own secure storage, and token refresh logic — separately for Android and iOS. This plugin removes that burden by wrapping each platform's native account framework behind a single, type-safe Dart API.

**Android `AccountManager` advantages:**
- Credentials stored at the OS level (survive app reinstalls when configured)
- Single sign-on (SSO) across apps from the same developer
- Visible to users in **Settings → Accounts**

**iOS Keychain advantages:**
- Hardware-backed encryption (Secure Enclave on modern devices)
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — available after first unlock, never backed up to iCloud

**Pigeon for platform channels:**
- Compile-time type safety — no stringly-typed method channel maps
- Null-safe Dart, generated Kotlin, and generated Swift bindings from a single schema

---

## Features

- **Account CRUD** — add, get, update, remove, check existence
- **Secure credential management** — update, validate, clear passwords
- **Auth token lifecycle** — get, set, invalidate, refresh tokens by type
- **Account change events** — `Stream<AccountEvent>` (added, removed, updated, token expired)
- **Platform capabilities** — query what each platform supports at runtime

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_account_manager: ^2.0.0
```

Then run:

```sh
flutter pub get
```

---

## Platform Setup

### Android

#### 1. `android/app/src/main/AndroidManifest.xml`

Add these permissions inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.AUTHENTICATE_ACCOUNTS" />
<uses-permission android:name="android.permission.GET_ACCOUNTS" />
<uses-permission android:name="android.permission.MANAGE_ACCOUNTS" />
```

#### 2. Minimum SDK

In `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        minSdkVersion 23   // Android 6.0 minimum
    }
}
```

#### 3. Account type string

Your account type is a reverse-domain identifier, e.g. `com.example.app`. Use this consistently across all API calls. It maps to the `android:accountType` used by the plugin's `AuthenticatorService`.

#### 4. Customising the Settings → Accounts entry

By default, the plugin shows **"Account Manager"** as the account label and a generic person icon in **Settings → Accounts**. You can override both with your own app's name and icon using Android's resource override mechanism — no code changes required, just add resources with the same name in your app.

##### Option A — Resource override (recommended, zero code)

The plugin defines two overrideable resources. Declare resources with the **same names** in your app and Android will automatically use yours instead of the plugin's defaults.

**Label** — add to `android/app/src/main/res/values/strings.xml`:

```xml
<!-- Shows your actual app name in Settings → Accounts -->
<string name="account_manager_label">My App Name</string>

<!-- Or reference your existing app_name automatically: -->
<string name="account_manager_label">@string/app_name</string>
```

**Icon** — add `android/app/src/main/res/drawable/ic_account_manager.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Redirect to your launcher icon -->
<bitmap xmlns:android="http://schemas.android.com/apk/res/android"
    android:src="@mipmap/ic_launcher" />
```

Or simply copy/symlink your existing launcher PNG into the drawable folder:

```
android/app/src/main/res/drawable/ic_account_manager.png
```

After these changes, **Settings → Accounts** will show your app's real name and icon — exactly like Gmail or Google Calendar do.

##### Complete working example

The following three files are all you need. Add them to your app's Android source tree exactly as shown.

**`android/app/src/main/res/values/strings.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- App name shown in the launcher, app switcher, and Settings → Accounts -->
    <string name="app_name">My App</string>

    <!--
        Overrides the plugin's default "Account Manager" label.
        Referencing @string/app_name keeps both in sync automatically.
    -->
    <string name="account_manager_label">@string/app_name</string>
</resources>
```

**`android/app/src/main/res/drawable/ic_account_manager.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!--
    Overrides the plugin's default person icon shown in Settings → Accounts.
    Points to the app's own launcher icon so the account entry looks native.

    android:src references the mipmap-* PNGs already present in every Flutter
    project (mipmap-mdpi/ic_launcher.png through mipmap-xxxhdpi/ic_launcher.png).
-->
<bitmap xmlns:android="http://schemas.android.com/apk/res/android"
    android:src="@mipmap/ic_launcher" />
```

**`android/app/src/main/AndroidManifest.xml`** — use the string resource for the app label so it stays in sync:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="@string/app_name"   <!-- was: android:label="my_app" -->
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of your manifest ... -->
    </application>
</manifest>
```

> **How it works:** Android's resource merge system gives the app's resources higher priority than library resources. Because the plugin already references `@drawable/ic_account_manager` and `@string/account_manager_label` in `res/xml/authenticator.xml`, declaring resources with those exact names in your app is all it takes — the build tooling resolves them to yours automatically. No code changes, no manifest service overrides required.

##### Option B — Full manual control (advanced)

If you need complete control (e.g. different icons per build flavour), move the authenticator configuration entirely to your app by following these steps:

**Step 1.** Suppress the plugin's built-in service registration in `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- Remove the plugin's AuthenticatorService so you can re-declare it -->
    <service
        android:name="com.lkrjangid.account_manager.authenticator.AuthenticatorService"
        android:enabled="false"
        tools:node="remove" />
</application>
```

**Step 2.** Create `android/app/src/main/res/xml/authenticator.xml` with your own values:

```xml
<?xml version="1.0" encoding="utf-8"?>
<account-authenticator xmlns:android="http://schemas.android.com/apk/res/android"
    android:accountType="com.example.myapp"
    android:icon="@mipmap/ic_launcher"
    android:smallIcon="@mipmap/ic_launcher"
    android:label="@string/app_name" />
```

**Step 3.** Re-declare the service in your manifest pointing to your XML:

```xml
<service
    android:name="com.lkrjangid.account_manager.authenticator.AuthenticatorService"
    android:exported="true">
    <intent-filter>
        <action android:name="android.accounts.AccountAuthenticator" />
    </intent-filter>
    <meta-data
        android:name="android.accounts.AccountAuthenticator"
        android:resource="@xml/authenticator" />
</service>
```

---

### iOS

#### 1. Deployment target

In `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

---

## Quick Start

```dart
import 'package:flutter_account_manager/account_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be called once before any other operation
  await AccountManagerPlugin.instance.initialize();

  runApp(const MyApp());
}
```

---

## API Reference

### Initialisation

```dart
final am = AccountManagerPlugin.instance;

// Registers native callbacks, verifies configuration.
// Throws PluginNotConfiguredException if manifest/plist is missing required entries.
await am.initialize();

// Release stream controllers when done (e.g. in app dispose)
await am.dispose();
```

---

### Account Management

#### Add an account

```dart
final account = Account(
  username: 'user@example.com',
  accountType: 'com.example.app',    // your reverse-domain identifier
  displayName: 'Jane Doe',
  userData: {'role': 'premium', 'tier': '2'},
);

final success = await am.addAccount(account, 'securePassword123');
// Returns true if created, false if it already existed (Android)
// Throws AccountAlreadyExistsException on iOS if account exists
```

#### Retrieve accounts

```dart
// All accounts of a given type
final List<Account> accounts = await am.getAccounts('com.example.app');

// A specific account
final Account? account = await am.getAccount('user@example.com', 'com.example.app');
// Returns null if not found

// Check existence without fetching
final bool exists = await am.accountExists('user@example.com', 'com.example.app');
```

#### Update account metadata

```dart
final updated = account.copyWith(displayName: 'Jane Smith');
await am.updateAccount(updated);
// Updates displayName and userData; username and accountType are immutable
```

#### Remove an account

```dart
final removed = await am.removeAccount(account);
// Also removes all associated auth tokens
```

---

### Credential Management

```dart
// Change password
await am.updateCredentials(account, 'newPassword456');

// Validate credentials without storing them
final valid = await am.validateCredentials(
  'user@example.com',
  'password',
  'com.example.app',
);

// Wipe password while keeping account metadata
await am.clearCredentials(account);
```

---

### Auth Token Management

Auth tokens are typed string values (e.g. `'api'`, `'refresh'`, `'read'`). Android caches them in `AccountManager`; iOS stores them in the Keychain.

#### Get a token

```dart
try {
  final String? token = await am.getAuthToken(account, 'api');
  // token is null if none is stored
} on AuthenticationRequiredException {
  // User must re-authenticate — show a login screen
}
```

#### Store / refresh a token

```dart
// After your server returns a new JWT:
await am.setAuthToken(account, 'api', 'eyJhbGci...');
```

#### Invalidate tokens

```dart
// Invalidate a single known token value (useful after a 401 response)
await am.invalidateAuthToken('com.example.app', expiredToken);

// Invalidate all tokens of a type for an account (forces re-auth)
await am.invalidateAllTokens(account, 'api');
```

#### List available token types

```dart
final List<String> types = await am.getAvailableTokenTypes(account);
```

---

### Event Streams

#### Account events

```dart
final subscription = am.accountEvents.listen((event) {
  switch (event) {
    case AccountAddedEvent(:final account):
      print('Account added: ${account.username}');
    case AccountRemovedEvent(:final account):
      print('Account removed: ${account.username}');
    case AccountUpdatedEvent(:final account):
      print('Account updated: ${account.username}');
    case AuthTokenExpiredEvent(:final account, :final tokenType):
      print('Token "$tokenType" expired for ${account.username}');
      // Trigger re-authentication
  }
});
```

---

### Platform-Specific

```dart
// Open system Accounts settings (Android only, no-op on iOS)
await am.openAccountSettings();

// Query what the current platform supports
final Map<String, bool> caps = await am.getPlatformCapabilities();
// Android: { systemAccountSettings: true, backgroundSync: false, ... }
// iOS:     { keychainStorage: true, biometricAuth: true, ... }
```

---

## Integration with State Management

### Bloc / Cubit

```dart
class AuthCubit extends Cubit<AuthState> {
  final AccountManagerPlugin _am;

  AuthCubit(this._am) : super(AuthInitial()) {
    _am.accountEvents.listen((event) {
      if (event is AuthTokenExpiredEvent) {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final account = Account(
        username: email,
        accountType: 'com.example.app',
      );
      await _am.addAccount(account, password);
      emit(AuthAuthenticated(account: account));
    } on AccountManagerException catch (e) {
      emit(AuthError(message: e.message, code: e.errorCode));
    }
  }

  Future<void> logout(Account account) async {
    await _am.removeAccount(account);
    emit(AuthUnauthenticated());
  }
}
```

### Riverpod

```dart
final accountManagerProvider = Provider<AccountManagerPlugin>(
  (ref) => AccountManagerPlugin.instance,
);

final accountsProvider = FutureProvider.family<List<Account>, String>(
  (ref, accountType) async {
    final am = ref.read(accountManagerProvider);
    return am.getAccounts(accountType);
  },
);
```

---

## Error Handling

All errors thrown by this plugin extend `AccountManagerException`:

| Exception | Error Code | When |
|-----------|-----------|------|
| `AccountAlreadyExistsException` | 1001 | `addAccount` called for an existing account |
| `AccountNotFoundException` | 1002 | Account not found for an operation |
| `AuthenticationRequiredException` | 1100 | `getAuthToken` requires user interaction |
| `CredentialException` | 1300 | Keychain / AccountManager credential error |
| `PluginNotConfiguredException` | 1500 | Missing `AndroidManifest.xml` or `Info.plist` entries |
| `UnsupportedOperationException` | 1501 | Operation not supported on this platform |

```dart
try {
  await am.addAccount(account, password);
} on AccountAlreadyExistsException {
  // Show "account already exists" message
} on PluginNotConfiguredException catch (e) {
  // Missing manifest/plist entries — developer error
  debugPrint(e.message);
} on AccountManagerException catch (e) {
  // Generic fallback
  debugPrint('[${e.errorCode}] ${e.message}');
}
```

---

## How It Works Internally

### Architecture

```
┌──────────────────────────────────────────────────┐
│                 Flutter App                       │
│                                                   │
│  AccountManagerPlugin (singleton)                 │
│  └── accountEvents: Stream<AccountEvent>          │
│                     │                             │
│  Pigeon-generated interfaces                      │
│  ├── AccountManagerHostApi  (Flutter → Native)    │
│  └── AccountCallbackFlutterApi (Native → Flutter) │
└──────────────────────────────────────────────────-┘
                     │ Platform Channel (binary)
        ┌────────────┴────────────┐
        ▼                         ▼
  Android                        iOS
  ├── AccountManagerHostApiImpl  ├── AccountManagerHostApiImpl
  ├── AccountAuthenticator       ├── KeychainManager
  ├── AuthenticatorService       └── AccountStore (UserDefaults+JSON)
  └── AddAccountActivity
```

### Account creation flow

```
Flutter                    Pigeon                   Android Native
  │                           │                           │
  │  addAccount(account, pwd) │                           │
  │──────────────────────────>│                           │
  │                           │  addAccount()             │
  │                           │──────────────────────────>│
  │                           │              accountManager.addAccountExplicitly()
  │                           │              setUserData("displayName", ...)
  │                           │<──────────────────────────│
  │<──────────────────────────│  Result<bool>             │
```

### Token lifecycle

1. **First call** — `getAuthToken()` checks the AccountManager cache / Keychain. Returns cached token if valid.
2. **Cache miss** — On Android, triggers `AccountAuthenticator.getAuthToken()`. On iOS, returns `requiresUserInteraction: true`.
3. **Token refresh** — Your app calls `setAuthToken()` with the new token from your server.
4. **Token invalidation** — Call `invalidateAuthToken()` after a 401 response to force a fresh token on the next `getAuthToken()`.

---

## Security

| Concern | Android | iOS |
|---------|---------|-----|
| Password storage | `AccountManager` (kernel-level) | Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) |
| Token storage | `AccountManager` auth token cache | Keychain |
| Network | HTTPS required; certificate pinning recommended | HTTPS required |
| Memory | Sensitive strings are not logged | Sensitive strings are not logged |
| Backup | Android backup rules apply | `ThisDeviceOnly` — no iCloud backup |

---

## Performance Targets

| Operation | P95 target | Max |
|-----------|-----------|-----|
| `addAccount` | 50 ms | 200 ms |
| `getAccounts` | 30 ms | 100 ms |
| `getAuthToken` (cached) | 10 ms | 50 ms |
| `getAuthToken` (network) | 100 ms | 500 ms |

---

## Compatibility

| | Requirement |
|--|--|
| Flutter | ≥ 3.19.0 |
| Dart | ≥ 3.3.0 |
| Android minSdk | 23 (Android 6.0 Marshmallow) |
| Android targetSdk | 34 (Android 14) |
| iOS deployment target | 13.0 |
| Kotlin | ≥ 1.9.0 |
| Swift | ≥ 5.9 |
| Xcode | ≥ 15.0 |

---

## Generating Platform Code (contributors)

The Pigeon schema lives in `pigeons/account_manager.dart`. After editing it:

```sh
dart run pigeon --input pigeons/account_manager.dart
```

This regenerates:
- `lib/src/generated/account_manager_api.g.dart`
- `android/src/main/kotlin/com/lkrjangid/account_manager/AccountManagerApi.g.kt`
- `ios/Classes/AccountManagerApi.g.swift`

After changing method signatures, regenerate mockito mocks:

```sh
dart run build_runner build --delete-conflicting-outputs
```

---

## Running Tests

```sh
# Unit tests (no device required)
flutter test

# Integration tests (requires a connected device or emulator)
flutter test integration_test/
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Update the Pigeon schema if adding/changing API methods
4. Run `dart run pigeon --input pigeons/account_manager.dart`
5. Implement on both platforms
6. Add tests (`flutter test`)
7. Open a pull request

---

## License

MIT License — see [LICENSE](LICENSE).

---

**Author:** Lokesh Jangid  
**Package:** `flutter_account_manager`  
**Version:** 2.0.0
