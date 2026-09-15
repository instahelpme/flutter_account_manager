import 'account.dart';

/// Base class for account-related events emitted by [AccountManagerPlugin.accountEvents].
sealed class AccountEvent {
  const AccountEvent();
}

class AccountAddedEvent extends AccountEvent {
  const AccountAddedEvent({required this.account});
  final Account account;
}

class AccountRemovedEvent extends AccountEvent {
  const AccountRemovedEvent({required this.account});
  final Account account;
}

class AccountUpdatedEvent extends AccountEvent {
  const AccountUpdatedEvent({required this.account});
  final Account account;
}

class AuthTokenExpiredEvent extends AccountEvent {
  const AuthTokenExpiredEvent({
    required this.account,
    required this.tokenType,
  });
  final Account account;
  final String tokenType;
}
