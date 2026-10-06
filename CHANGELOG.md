## 1.0.1

* Migrates Android build to built-in Kotlin (AGP 9+ compatibility).
* Applies `kotlin-android` plugin conditionally for AGP < 9 to support Flutter versions earlier than 3.44.

## 1.0.0

* Initial public release of the `flutter_account_manager` Flutter plugin.
* Added cross-platform account CRUD, credential, and auth token APIs.
* Added Android AccountManager authenticator and sync integration.
* Added iOS Keychain-backed account storage support.
* Added example app and generated Pigeon platform bindings.
