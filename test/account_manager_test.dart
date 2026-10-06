import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_account_manager/account_manager.dart';
import 'package:flutter_account_manager/src/generated/account_manager_api.g.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'account_manager_test.mocks.dart';

@GenerateMocks([AccountManagerHostApi])
void main() {
  late MockAccountManagerHostApi mockHostApi;
  late AccountManagerPlugin plugin;

  setUp(() {
    mockHostApi = MockAccountManagerHostApi();
    plugin = AccountManagerPlugin.withHostApi(mockHostApi);
  });

  group('Account Operations', () {
    final testAccount = Account(
      username: 'test@example.com',
      accountType: 'com.example.app',
      displayName: 'Test User',
    );

    test('addAccount returns true on success', () async {
      when(mockHostApi.addAccount(any, any)).thenAnswer((_) async => true);

      final result = await plugin.addAccount(testAccount, 'password123');

      expect(result, isTrue);
      verify(mockHostApi.addAccount(any, 'password123')).called(1);
    });

    test('getAccounts returns mapped Account list', () async {
      when(mockHostApi.getAccounts('com.example.app')).thenAnswer((_) async => [
            AccountData(
              username: 'user1@example.com',
              accountType: 'com.example.app',
            ),
            AccountData(
              username: 'user2@example.com',
              accountType: 'com.example.app',
            ),
          ]);

      final accounts = await plugin.getAccounts('com.example.app');

      expect(accounts.length, equals(2));
      expect(accounts[0].username, equals('user1@example.com'));
      expect(accounts[1].username, equals('user2@example.com'));
    });

    test('getAccount returns null when not found', () async {
      when(mockHostApi.getAccount(any, any)).thenAnswer((_) async => null);

      final result =
          await plugin.getAccount('nobody@example.com', 'com.example.app');

      expect(result, isNull);
    });

    test('removeAccount delegates to hostApi', () async {
      when(mockHostApi.removeAccount(any)).thenAnswer((_) async => true);

      final result = await plugin.removeAccount(testAccount);

      expect(result, isTrue);
    });

    test('accountExists returns correct boolean', () async {
      when(mockHostApi.accountExists(any, any)).thenAnswer((_) async => true);

      expect(
        await plugin.accountExists('test@example.com', 'com.example.app'),
        isTrue,
      );
    });
  });

  group('Auth Token Operations', () {
    final testAccount = Account(
      username: 'test@example.com',
      accountType: 'com.example.app',
    );

    test('getAuthToken returns token on success', () async {
      when(mockHostApi.getAuthToken(any, any)).thenAnswer((_) async =>
          AuthTokenResult(token: 'jwt_abc123', requiresUserInteraction: false));

      final token = await plugin.getAuthToken(testAccount, 'api');

      expect(token, equals('jwt_abc123'));
    });

    test(
        'getAuthToken throws AuthenticationRequiredException when interaction required',
        () async {
      when(mockHostApi.getAuthToken(any, any))
          .thenAnswer((_) async => AuthTokenResult(
                token: null,
                errorMessage: 'Re-auth required',
                requiresUserInteraction: true,
              ));

      expect(
        () => plugin.getAuthToken(testAccount, 'api'),
        throwsA(isA<AuthenticationRequiredException>()),
      );
    });

    test('setAuthToken delegates correctly', () async {
      when(mockHostApi.setAuthToken(any, any, any))
          .thenAnswer((_) async => true);

      final result = await plugin.setAuthToken(testAccount, 'api', 'new_token');

      expect(result, isTrue);
      verify(mockHostApi.setAuthToken(any, 'api', 'new_token')).called(1);
    });
  });

  group('Sync Operations', () {
    final testAccount = Account(
      username: 'test@example.com',
      accountType: 'com.example.app',
    );

    test('syncNow returns SyncResult on success', () async {
      when(mockHostApi.syncNow(any, any))
          .thenAnswer((_) async => SyncResultData(
                success: true,
                stats: SyncStatsData(
                  itemsUploaded: 5,
                  itemsDownloaded: 10,
                  conflicts: 0,
                  syncTimeMs: 1500,
                ),
              ));

      final result = await plugin.syncNow(testAccount);

      expect(result.success, isTrue);
      expect(result.stats?.itemsDownloaded, equals(10));
      expect(result.stats?.itemsUploaded, equals(5));
    });

    test('syncNow with expedited flag passes it through', () async {
      when(mockHostApi.syncNow(any, true))
          .thenAnswer((_) async => SyncResultData(
                success: true,
                stats: SyncStatsData(
                  itemsUploaded: 0,
                  itemsDownloaded: 0,
                  conflicts: 0,
                  syncTimeMs: 100,
                ),
              ));

      await plugin.syncNow(testAccount, expedited: true);

      verify(mockHostApi.syncNow(any, true)).called(1);
    });

    test('addPeriodicSync throws ArgumentError for interval < 15 minutes', () {
      when(mockHostApi.addPeriodicSync(any, any)).thenAnswer((_) async => true);

      expect(
        () => plugin.addPeriodicSync(testAccount, const Duration(minutes: 5)),
        throwsArgumentError,
      );
    });

    test('addPeriodicSync succeeds for interval >= 15 minutes', () async {
      when(mockHostApi.addPeriodicSync(any, any)).thenAnswer((_) async => true);

      final result = await plugin.addPeriodicSync(
        testAccount,
        const Duration(minutes: 30),
      );

      expect(result, isTrue);
    });

    test('getSyncStatus returns SyncStatus', () async {
      when(mockHostApi.getSyncStatus(any))
          .thenAnswer((_) async => SyncStatus.active);

      final status = await plugin.getSyncStatus(testAccount);

      expect(status, equals(SyncStatus.active));
    });
  });

  group('Exceptions', () {
    test('AccountAlreadyExistsException has correct errorCode', () {
      const e = AccountAlreadyExistsException(message: 'Already exists');
      expect(e.errorCode, equals(1001));
    });

    test('AuthenticationRequiredException has correct errorCode', () {
      const e = AuthenticationRequiredException(message: 'Auth required');
      expect(e.errorCode, equals(1100));
    });

    test('SyncConflictException stores conflict data', () {
      const e = SyncConflictException(
        message: 'Conflict detected',
        conflictId: 'c1',
        localData: '{"v":1}',
        remoteData: '{"v":2}',
      );
      expect(e.conflictId, equals('c1'));
      expect(e.localData, equals('{"v":1}'));
      expect(e.remoteData, equals('{"v":2}'));
    });
  });

  group('Account model', () {
    test('Account equality is based on username and accountType', () {
      const a1 = Account(username: 'u@x.com', accountType: 'com.x');
      const a2 = Account(
          username: 'u@x.com', accountType: 'com.x', displayName: 'Different');
      expect(a1, equals(a2));
    });

    test('Account toData / fromData roundtrip', () {
      const account = Account(
        username: 'u@x.com',
        accountType: 'com.x',
        displayName: 'User',
        userData: {'role': 'admin'},
      );
      final restored = Account.fromData(account.toData());
      expect(restored.username, equals(account.username));
      expect(restored.accountType, equals(account.accountType));
      expect(restored.displayName, equals(account.displayName));
      expect(restored.userData?['role'], equals('admin'));
    });
  });
}
