## 2.1.0

All changes are additive and backward compatible; without a keychain access group the
behaviour is unchanged.

* Adds `initialize({String? keychainAccessGroup})`. On iOS every keychain query carries
  `kSecAttrAccessGroup` when set (full group including the app identifier prefix, e.g.
  `ABCDE12345.com.example.shared`), so apps of the same team can share accounts and tokens.
  Android accepts and ignores the parameter.
* iOS: with an access group, `addAccount` / `updateAccount` also write the account metadata to
  the keychain (`<accountType>:<username>:account`). `getAccount`, `getAccounts` and
  `accountExists` check the keychain first and fall back to `UserDefaults`; `accountExists` and
  `getAccount` also report an account when only `<accountType>:<username>:token:*` items exist.
* iOS: `removeAccount` now deletes all `<accountType>:<username>:token:*` items and the metadata
  item (tokens used to survive).
* Adds `peekAuthToken(account, tokenType)` (Android + iOS): returns the stored token or `null`
  (also for an empty value) without the authenticator fallback that hands out the password.
* Android: `getAccount` / `getAccounts` no longer drop `userData` keys written via the plugin.
* Removes the stale `com.example.account_manager` Android plugin and test; points the package
  metadata to `instahelpme`; runs `flutter test` in CI.

## 2.0.0

**Breaking:** background sync support has been removed.

* Removed `syncNow`, `addPeriodicSync`, `removePeriodicSync`, `isSyncAutomatically`,
  `setSyncAutomatically`, `getSyncStatus`, `cancelSync` and the `syncEvents` stream.
* Removed the `SyncResult`, `SyncStatus` and `SyncEvent` models and the
  `SyncNetworkException` / `SyncConflictException` exceptions.
* Removed the `SyncCallbackFlutterApi` Pigeon channel.
* Android: removed the `SyncAdapter`, `SyncService` and `AppContentProvider`, and the
  `READ_SYNC_SETTINGS`, `WRITE_SYNC_SETTINGS` and `READ_SYNC_STATS` permissions.
  Apps that declared the sync adapter / provider in their own manifest should remove those entries.
* iOS: removed the BGTaskScheduler-based background sync. The
  `BGTaskSchedulerPermittedIdentifiers` entry for the plugin is no longer needed.
* `getPlatformCapabilities()` now reports `backgroundSync: false` on both platforms, and
  `pushNotificationSync: false` on iOS.
* iOS: `updateAccount` / `addAccount` with an empty `userData` map now store an empty map
  instead of `null`, matching Android.
* iOS: adds Swift Package Manager support. Sources moved to
  `ios/flutter_account_manager/Sources/flutter_account_manager`; CocoaPods remains supported.
* Migrates Android build to built-in Kotlin (AGP 9+ compatibility).
* Applies the `kotlin-android` plugin when AGP < 9 or when the host app sets
  `android.builtInKotlin=false`, to support Flutter versions earlier than 3.44.

## 1.0.0

* Initial public release of the `flutter_account_manager` Flutter plugin.
* Added cross-platform account CRUD, credential, and auth token APIs.
* Added Android AccountManager authenticator and sync integration.
* Added iOS Keychain-backed account storage support.
* Added example app and generated Pigeon platform bindings.
