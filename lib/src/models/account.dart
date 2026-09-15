import '../../src/generated/account_manager_api.g.dart';

/// A user account with associated metadata.
class Account {
  const Account({
    required this.username,
    required this.accountType,
    this.displayName,
    this.userData,
  });

  /// Unique identifier (e.g. email address).
  final String username;

  /// Account type identifier (e.g. "com.example.app").
  final String accountType;

  /// Human-readable display name.
  final String? displayName;

  /// Additional metadata as key-value pairs.
  final Map<String, String>? userData;

  AccountData toData() => AccountData(
        username: username,
        accountType: accountType,
        displayName: displayName,
        userData: userData?.cast<String?, String?>(),
      );

  factory Account.fromData(AccountData data) => Account(
        username: data.username,
        accountType: data.accountType,
        displayName: data.displayName,
        userData: data.userData == null
            ? null
            : Map.fromEntries(
                data.userData!.entries
                    .where((e) => e.key != null && e.value != null)
                    .map((e) => MapEntry(e.key!, e.value!)),
              ),
      );

  Account copyWith({
    String? username,
    String? accountType,
    String? displayName,
    Map<String, String>? userData,
  }) =>
      Account(
        username: username ?? this.username,
        accountType: accountType ?? this.accountType,
        displayName: displayName ?? this.displayName,
        userData: userData ?? this.userData,
      );

  @override
  String toString() =>
      'Account(username: $username, accountType: $accountType, displayName: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          accountType == other.accountType;

  @override
  int get hashCode => username.hashCode ^ accountType.hashCode;
}
