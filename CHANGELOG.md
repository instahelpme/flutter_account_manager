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
