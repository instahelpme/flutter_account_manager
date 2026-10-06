import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_account_manager/account_manager.dart';

const _accountType = 'com.lkrjangid.account_manager';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AccountManagerPlugin.instance.initialize();
  } catch (e) {
    log('Plugin init error: $e');
  }
  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Manager Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account Manager'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.manage_accounts), text: 'Accounts'),
              Tab(icon: Icon(Icons.lock), text: 'Credentials'),
              Tab(icon: Icon(Icons.token), text: 'Tokens'),
              Tab(icon: Icon(Icons.sync), text: 'Sync'),
              Tab(icon: Icon(Icons.event), text: 'Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AccountsTab(),
            _CredentialsTab(),
            _TokensTab(),
            _EventsTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

final _am = AccountManagerPlugin.instance;

/// Displays a snackbar with [message].
void _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Colors.red[700] : null,
    behavior: SnackBarBehavior.floating,
  ));
}

/// Section card with a title and children.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A full-width elevated button with a label.
class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.chevron_right, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(42),
        ),
      ),
    );
  }
}

/// Key-value row used in detail displays.
class _KV extends StatelessWidget {
  const _KV(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13,
                      fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Accounts
// ─────────────────────────────────────────────────────────────────────────────

class _AccountsTab extends StatefulWidget {
  const _AccountsTab();

  @override
  State<_AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<_AccountsTab>
    with AutomaticKeepAliveClientMixin {
  List<Account> _accounts = [];
  bool _loading = false;

  final _usernameCtrl = TextEditingController(text: 'user@example.com');
  final _displayCtrl = TextEditingController(text: 'Demo User');
  final _passwordCtrl = TextEditingController(text: 'Secret123!');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loading = true);
    try {
      final list = await _am.getAccounts(_accountType);
      setState(() => _accounts = list);
    } catch (e) {
      if (mounted) _snack(context, 'Load failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addAccount() async {
    final username = _usernameCtrl.text.trim();
    final display = _displayCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      _snack(context, 'Username and password are required', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final account = Account(
        username: username,
        accountType: _accountType,
        displayName: display.isEmpty ? null : display,
        userData: {'createdFrom': 'demo_app', 'role': 'user'},
      );
      final ok = await _am.addAccount(account, password);
      if (mounted) {
        _snack(context, ok ? 'Account created' : 'Already exists');
      }
      await _loadAccounts();
    } on AccountAlreadyExistsException {
      if (mounted) _snack(context, 'Account already exists', error: true);
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, '[${e.errorCode}] ${e.message}', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkExists(Account account) async {
    final exists =
        await _am.accountExists(account.username, account.accountType);
    if (mounted) {
      _snack(context,
          '${account.username} → ${exists ? 'EXISTS' : 'NOT FOUND'}');
    }
  }

  Future<void> _updateAccount(Account account) async {
    try {
      final updated = account.copyWith(
        displayName: '${account.displayName ?? account.username} (updated)',
        userData: {...?account.userData, 'updatedAt': DateTime.now().toIso8601String()},
      );
      await _am.updateAccount(updated);
      if (mounted) _snack(context, 'Display name updated');
      await _loadAccounts();
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  Future<void> _removeAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text('Remove ${account.username}?\n'
            'This also deletes all tokens and sync data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final ok = await _am.removeAccount(account);
      if (mounted) _snack(context, ok ? 'Account removed' : 'Remove failed');
      await _loadAccounts();
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: [
        // ── Create account ──────────────────────────────────────────────────
        _Section(
          title: 'Create Account',
          children: [
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Username (email)',
                  prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _displayCtrl,
              decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
            ),
            _Btn(
              label: 'Add Account',
              icon: Icons.person_add,
              onPressed: _loading ? () {} : _addAccount,
            ),
          ],
        ),

        // ── Account list ────────────────────────────────────────────────────
        _Section(
          title: 'Accounts  (${_accounts.length})',
          children: [
            _Btn(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: _loadAccounts,
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No accounts found.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...(_accounts.map((acc) => _AccountTile(
                    account: acc,
                    onCheckExists: () => _checkExists(acc),
                    onUpdate: () => _updateAccount(acc),
                    onRemove: () => _removeAccount(acc),
                  ))),
          ],
        ),

        // ── Platform capabilities ───────────────────────────────────────────
        const _PlatformCapabilitiesCard(),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.onCheckExists,
    required this.onUpdate,
    required this.onRemove,
  });

  final Account account;
  final VoidCallback onCheckExists;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: CircleAvatar(
        child: Text(
          (account.displayName ?? account.username)[0].toUpperCase(),
        ),
      ),
      title: Text(account.displayName ?? account.username),
      subtitle: Text(account.username,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KV('Type', account.accountType),
              if (account.userData != null)
                ...account.userData!.entries
                    .where((e) => e.key.isNotEmpty)
                    .map((e) => _KV(e.key, e.value)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onCheckExists,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Exists?'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onUpdate,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlatformCapabilitiesCard extends StatefulWidget {
  const _PlatformCapabilitiesCard();

  @override
  State<_PlatformCapabilitiesCard> createState() =>
      _PlatformCapabilitiesCardState();
}

class _PlatformCapabilitiesCardState
    extends State<_PlatformCapabilitiesCard> {
  Map<String, bool>? _caps;

  Future<void> _load() async {
    final caps = await _am.getPlatformCapabilities();
    setState(() => _caps = caps);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Platform Capabilities',
      children: _caps == null
          ? [const Center(child: CircularProgressIndicator())]
          : _caps!.entries
              .map((e) => Row(
                    children: [
                      Icon(
                        e.value ? Icons.check_circle : Icons.cancel,
                        color: e.value ? Colors.green : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(e.key, style: const TextStyle(fontSize: 13)),
                    ],
                  ))
              .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Credentials
// ─────────────────────────────────────────────────────────────────────────────

class _CredentialsTab extends StatefulWidget {
  const _CredentialsTab();

  @override
  State<_CredentialsTab> createState() => _CredentialsTabState();
}

class _CredentialsTabState extends State<_CredentialsTab>
    with AutomaticKeepAliveClientMixin {
  List<Account> _accounts = [];
  Account? _selected;

  final _validatePwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController(text: 'NewPass456!');

  bool? _validateResult;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final list = await _am.getAccounts(_accountType);
    setState(() {
      _accounts = list;
      if (_selected != null &&
          !list.any((a) => a.username == _selected!.username)) {
        _selected = null;
      }
    });
  }

  Future<void> _validate() async {
    if (_selected == null || _validatePwdCtrl.text.isEmpty) return;
    final ok = await _am.validateCredentials(
      _selected!.username,
      _validatePwdCtrl.text,
      _accountType,
    );
    setState(() => _validateResult = ok);
    if (mounted) _snack(context, ok ? 'Credentials valid ✓' : 'Invalid password ✗');
  }

  Future<void> _updatePassword() async {
    if (_selected == null || _newPwdCtrl.text.isEmpty) return;
    try {
      await _am.updateCredentials(_selected!, _newPwdCtrl.text);
      if (mounted) _snack(context, 'Password updated');
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  Future<void> _clearCredentials() async {
    if (_selected == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Credentials'),
        content: const Text(
            'This removes the stored password but keeps the account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _am.clearCredentials(_selected!);
      if (mounted) _snack(context, 'Credentials cleared');
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: [
        // ── Account selector ────────────────────────────────────────────────
        _Section(
          title: 'Select Account',
          children: [
            _Btn(label: 'Refresh accounts', icon: Icons.refresh,
                onPressed: _loadAccounts),
            if (_accounts.isEmpty)
              const Text('No accounts. Add one in the Accounts tab.',
                  style: TextStyle(color: Colors.grey))
            else
              DropdownButton<Account>(
                isExpanded: true,
                value: _selected,
                hint: const Text('Pick an account'),
                items: _accounts
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.displayName ?? a.username),
                        ))
                    .toList(),
                onChanged: (a) => setState(() {
                  _selected = a;
                  _validateResult = null;
                }),
              ),
          ],
        ),

        // ── Validate credentials ────────────────────────────────────────────
        _Section(
          title: 'Validate Credentials',
          children: [
            TextField(
              controller: _validatePwdCtrl,
              decoration: InputDecoration(
                labelText: 'Password to test',
                prefixIcon: const Icon(Icons.password),
                suffixIcon: _validateResult == null
                    ? null
                    : Icon(
                        _validateResult!
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            _validateResult! ? Colors.green : Colors.red,
                      ),
              ),
              obscureText: true,
            ),
            _Btn(
              label: 'Validate',
              icon: Icons.verified_user,
              onPressed: _selected == null ? () {} : _validate,
            ),
          ],
        ),

        // ── Update password ─────────────────────────────────────────────────
        _Section(
          title: 'Update Password',
          children: [
            TextField(
              controller: _newPwdCtrl,
              decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_reset)),
              obscureText: true,
            ),
            _Btn(
              label: 'Update Password',
              icon: Icons.save,
              onPressed: _selected == null ? () {} : _updatePassword,
            ),
          ],
        ),

        // ── Clear credentials ───────────────────────────────────────────────
        _Section(
          title: 'Clear Credentials',
          children: [
            const Text(
              'Removes the stored password while keeping the account '
              'metadata intact.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            _Btn(
              label: 'Clear Credentials',
              icon: Icons.delete_sweep,
              onPressed: _selected == null ? () {} : _clearCredentials,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Auth Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _TokensTab extends StatefulWidget {
  const _TokensTab();

  @override
  State<_TokensTab> createState() => _TokensTabState();
}

class _TokensTabState extends State<_TokensTab>
    with AutomaticKeepAliveClientMixin {
  List<Account> _accounts = [];
  Account? _selected;
  String? _fetchedToken;

  final _tokenTypeCtrl = TextEditingController(text: 'api');
  final _tokenValueCtrl =
      TextEditingController(text: 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.demo');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final list = await _am.getAccounts(_accountType);
    setState(() => _accounts = list);
  }

  Future<void> _setToken() async {
    if (_selected == null) return;
    try {
      await _am.setAuthToken(
          _selected!, _tokenTypeCtrl.text.trim(), _tokenValueCtrl.text.trim());
      if (mounted) _snack(context, 'Token stored for "${_tokenTypeCtrl.text}"');
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  Future<void> _getToken() async {
    if (_selected == null) return;
    try {
      final token =
          await _am.getAuthToken(_selected!, _tokenTypeCtrl.text.trim());
      setState(() => _fetchedToken = token ?? '(no token stored)');
    } on AuthenticationRequiredException {
      setState(() =>
          _fetchedToken = '⚠ Re-authentication required — show login screen');
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  Future<void> _invalidateToken() async {
    if (_selected == null || _fetchedToken == null) return;
    try {
      await _am.invalidateAuthToken(_accountType, _fetchedToken!);
      setState(() => _fetchedToken = null);
      if (mounted) _snack(context, 'Token invalidated');
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  Future<void> _invalidateAllTokens() async {
    if (_selected == null) return;
    try {
      await _am.invalidateAllTokens(
          _selected!, _tokenTypeCtrl.text.trim());
      setState(() => _fetchedToken = null);
      if (mounted) {
        _snack(
            context, 'All "${_tokenTypeCtrl.text}" tokens invalidated');
      }
    } on AccountManagerException catch (e) {
      if (mounted) _snack(context, e.message, error: true);
    }
  }

  Future<void> _getAvailableTypes() async {
    if (_selected == null) return;
    final types = await _am.getAvailableTokenTypes(_selected!);
    if (mounted) {
      _snack(
          context,
          types.isEmpty
              ? 'No token types available'
              : 'Types: ${types.join(', ')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: [
        // ── Account + token type ────────────────────────────────────────────
        _Section(
          title: 'Select Account & Token Type',
          children: [
            _Btn(
                label: 'Refresh accounts',
                icon: Icons.refresh,
                onPressed: _loadAccounts),
            if (_accounts.isEmpty)
              const Text('No accounts. Add one in the Accounts tab.',
                  style: TextStyle(color: Colors.grey))
            else
              DropdownButton<Account>(
                isExpanded: true,
                value: _selected,
                hint: const Text('Pick an account'),
                items: _accounts
                    .map((a) => DropdownMenuItem(
                        value: a, child: Text(a.displayName ?? a.username)))
                    .toList(),
                onChanged: (a) =>
                    setState(() {
                      _selected = a;
                      _fetchedToken = null;
                    }),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenTypeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Token type (e.g. api, refresh)',
                  prefixIcon: Icon(Icons.label_outline)),
            ),
            _Btn(
                label: 'List Available Types',
                icon: Icons.list,
                onPressed:
                    _selected == null ? () {} : _getAvailableTypes),
          ],
        ),

        // ── Store token ─────────────────────────────────────────────────────
        _Section(
          title: 'Store Auth Token',
          children: [
            TextField(
              controller: _tokenValueCtrl,
              decoration: const InputDecoration(
                  labelText: 'Token value',
                  prefixIcon: Icon(Icons.vpn_key_outlined)),
              maxLines: 2,
            ),
            _Btn(
              label: 'Set Token',
              icon: Icons.save,
              onPressed: _selected == null ? () {} : _setToken,
            ),
          ],
        ),

        // ── Retrieve token ──────────────────────────────────────────────────
        _Section(
          title: 'Retrieve Auth Token',
          children: [
            _Btn(
              label: 'Get Token',
              icon: Icons.download,
              onPressed: _selected == null ? () {} : _getToken,
            ),
            if (_fetchedToken != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _fetchedToken!,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),

        // ── Invalidate ──────────────────────────────────────────────────────
        _Section(
          title: 'Invalidate Tokens',
          children: [
            _Btn(
              label: 'Invalidate Current Token',
              icon: Icons.block,
              onPressed: _selected == null || _fetchedToken == null
                  ? () {}
                  : _invalidateToken,
            ),
            _Btn(
              label: 'Invalidate ALL Tokens of This Type',
              icon: Icons.delete_forever,
              onPressed: _selected == null ? () {} : _invalidateAllTokens,
            ),
          ],
        ),
      ],
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Tab 5 — Events
// ─────────────────────────────────────────────────────────────────────────────

class _EventsTab extends StatefulWidget {
  const _EventsTab();

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab>
    with AutomaticKeepAliveClientMixin {
  final List<_EventEntry> _events = [];
  final List<_EventEntry> _accountEvents = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _am.accountEvents.listen(_onAccountEvent);
  }

  void _onAccountEvent(AccountEvent event) {
    final entry = switch (event) {
      AccountAddedEvent(:final account) => _EventEntry(
          icon: Icons.person_add_alt,
          color: Colors.green,
          title: 'Account Added',
          detail: account.username,
        ),
      AccountRemovedEvent(:final account) => _EventEntry(
          icon: Icons.person_remove_outlined,
          color: Colors.red,
          title: 'Account Removed',
          detail: account.username,
        ),
      AccountUpdatedEvent(:final account) => _EventEntry(
          icon: Icons.edit_outlined,
          color: Colors.blue,
          title: 'Account Updated',
          detail: account.username,
        ),
      AuthTokenExpiredEvent(:final account, :final tokenType) => _EventEntry(
          icon: Icons.token,
          color: Colors.orange,
          title: 'Token Expired',
          detail: '"$tokenType" — ${account.username}',
        ),
    };
    setState(() => _accountEvents.insert(0, entry));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: [
        // ── Sync events ─────────────────────────────────────────────────────
        _Section(
          title: 'Sync Events  (${_events.length})',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live stream from background sync callbacks',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                if (_events.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _events.clear()),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            if (_events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No sync events yet. Trigger a sync.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._events.take(20).map((e) => _EventTile(entry: e)),
          ],
        ),

        // ── Account events ──────────────────────────────────────────────────
        _Section(
          title: 'Account Events  (${_accountEvents.length})',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live stream of account lifecycle changes',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                if (_accountEvents.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        setState(() => _accountEvents.clear()),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            if (_accountEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No account events yet.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._accountEvents.take(20).map((e) => _EventTile(entry: e)),
          ],
        ),

        // ── Legend ──────────────────────────────────────────────────────────
        _Section(
          title: 'Legend',
          children: const [
            _KV('SyncStarted', 'Sync operation began'),
            _KV('SyncProgress', 'Phase update (upload / download / conflict)'),
            _KV('SyncCompleted', 'Sync finished (success or failure)'),
            _KV('SyncCancelled', 'Sync was cancelled by the app'),
            _KV('SyncConflict', 'Conflict requires manual resolution'),
            _KV('AccountAdded', 'New account registered'),
            _KV('AccountRemoved', 'Account deleted'),
            _KV('AccountUpdated', 'Account metadata changed'),
            _KV('TokenExpired', 'Auth token needs refresh'),
          ],
        ),
      ],
    );
  }
}

class _EventEntry {
  _EventEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  }) : time = DateTime.now();
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final DateTime time;
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.entry});
  final _EventEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(entry.icon, color: entry.color, size: 20),
      title: Text(entry.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(entry.detail,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
    );
  }
}
