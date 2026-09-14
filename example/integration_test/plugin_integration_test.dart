import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_account_manager/account_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AccountManagerPlugin plugin;

  setUpAll(() async {
    plugin = AccountManagerPlugin.instance;
    await plugin.initialize().catchError((_) {});
  });

  tearDownAll(() async {
    await plugin.dispose();
  });

  group('End-to-end Account Flow', () {
    testWidgets('create, authenticate, sync, and remove account', (
      tester,
    ) async {
      final account = Account(
        username:
            'integration_test_${DateTime.now().millisecondsSinceEpoch}@example.com',
        accountType: 'com.lkrjangid.test',
        displayName: 'Integration Test User',
      );

      // Create account
      final createResult = await plugin.addAccount(account, 'TestPassword123!');
      expect(createResult, isTrue);

      // Verify account exists
      final retrieved = await plugin.getAccount(
        account.username,
        account.accountType,
      );
      expect(retrieved, isNotNull);
      expect(retrieved!.displayName, equals('Integration Test User'));

      // Set auth token
      final tokenSet = await plugin.setAuthToken(
        account,
        'api',
        'test_token_123',
      );
      expect(tokenSet, isTrue);

      // Trigger sync
      final syncResult = await plugin.syncNow(account);
      expect(syncResult.success, isTrue);

      // Remove account
      final removeResult = await plugin.removeAccount(account);
      expect(removeResult, isTrue);

      // Verify removed
      final removed = await plugin.getAccount(
        account.username,
        account.accountType,
      );
      expect(removed, isNull);
    });
  });
}
