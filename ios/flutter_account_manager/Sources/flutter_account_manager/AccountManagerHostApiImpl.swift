import Foundation

/// Implements [AccountManagerHostApi] using iOS Keychain and the
/// UserDefaults-backed AccountStore.
class AccountManagerHostApiImpl: AccountManagerHostApi {

    private let lock = NSLock()
    private var _keychainManager: KeychainManager
    private var _accountStore: AccountStore

    private var keychainManager: KeychainManager {
        lock.lock(); defer { lock.unlock() }
        return _keychainManager
    }

    private var accountStore: AccountStore {
        lock.lock(); defer { lock.unlock() }
        return _accountStore
    }

    init(accessGroup: String? = nil) {
        let keychain = KeychainManager(accessGroup: accessGroup)
        _keychainManager = keychain
        _accountStore = AccountStore(keychain: keychain)
    }

    // MARK: - Configuration

    /// Sets the Keychain access group (nil = default behaviour).
    func initialize(keychainAccessGroup: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let group = (keychainAccessGroup?.isEmpty ?? true) ? nil : keychainAccessGroup
        let keychain = KeychainManager(accessGroup: group)
        lock.lock()
        _keychainManager = keychain
        _accountStore = AccountStore(keychain: keychain)
        lock.unlock()
        completion(.success(()))
    }

    // MARK: - Account Operations

    func addAccount(account: AccountData, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.keychainManager.storeCredentials(
                    username: account.username,
                    password: password,
                    accountType: account.accountType
                )
                try self.accountStore.saveAccount(account)
                DispatchQueue.main.async { completion(.success(true)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func getAccounts(accountType: String, completion: @escaping (Result<[AccountData], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let accounts = try self.accountStore.getAccounts(ofType: accountType)
                DispatchQueue.main.async { completion(.success(accounts)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func getAccount(username: String, accountType: String, completion: @escaping (Result<AccountData?, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let account = try self.accountStore.getAccount(username: username, accountType: accountType)
                DispatchQueue.main.async { completion(.success(account)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func updateAccount(account: AccountData, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.accountStore.updateAccount(account)
                DispatchQueue.main.async { completion(.success(true)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func removeAccount(account: AccountData, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let keychain = self.keychainManager
                try keychain.deleteCredentials(
                    username: account.username,
                    accountType: account.accountType
                )
                // Delete every token regardless of its type.
                try keychain.deleteEveryToken(
                    username: account.username,
                    accountType: account.accountType
                )
                try self.accountStore.removeAccount(
                    username: account.username,
                    accountType: account.accountType
                )
                DispatchQueue.main.async { completion(.success(true)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func accountExists(username: String, accountType: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let exists = self.accountStore.accountExists(username: username, accountType: accountType)
            DispatchQueue.main.async { completion(.success(exists)) }
        }
    }

    // MARK: - Credential Operations

    func updateCredentials(account: AccountData, newPassword: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.keychainManager.storeCredentials(
                    username: account.username,
                    password: newPassword,
                    accountType: account.accountType
                )
                DispatchQueue.main.async { completion(.success(true)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func validateCredentials(username: String, password: String, accountType: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let stored = try self.keychainManager.retrieveCredentials(
                    username: username,
                    accountType: accountType
                )
                DispatchQueue.main.async { completion(.success(stored == password)) }
            } catch {
                DispatchQueue.main.async { completion(.success(false)) }
            }
        }
    }

    func clearCredentials(account: AccountData, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.keychainManager.deleteCredentials(
                    username: account.username,
                    accountType: account.accountType
                )
                DispatchQueue.main.async { completion(.success(true)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Auth Token Operations

    func getAuthToken(account: AccountData, tokenType: String, completion: @escaping (Result<AuthTokenResult, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let token = try self.keychainManager.retrieveAuthToken(
                    username: account.username,
                    accountType: account.accountType,
                    tokenType: tokenType
                )
                let result = AuthTokenResult(
                    token: token,
                    errorCode: token == nil ? -1 : nil,
                    errorMessage: token == nil ? "No token available" : nil,
                    requiresUserInteraction: token == nil ? true : nil
                )
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                let result = AuthTokenResult(
                    token: nil,
                    errorCode: -1,
                    errorMessage: error.localizedDescription,
                    requiresUserInteraction: nil
                )
                DispatchQueue.main.async { completion(.success(result)) }
            }
        }
    }

    func peekAuthToken(account: AccountData, tokenType: String, completion: @escaping (Result<String?, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let token = try self.keychainManager.retrieveAuthToken(
                    username: account.username,
                    accountType: account.accountType,
                    tokenType: tokenType
                )
                // Empty is treated like missing.
                let value = (token?.isEmpty ?? true) ? nil : token
                DispatchQueue.main.async { completion(.success(value)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func setAuthToken(account: AccountData, tokenType: String, token: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.keychainManager.storeAuthToken(
                    username: account.username,
                    accountType: account.accountType,
                    tokenType: tokenType,
                    token: token
                )
                DispatchQueue.main.async { completion(.success(true)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func invalidateAuthToken(accountType: String, token: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // iOS Keychain doesn't provide a direct way to look up by token value;
        // invalidation by type is handled via invalidateAllTokens.
        completion(.success(true))
    }

    func invalidateAllTokens(account: AccountData, tokenType: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.keychainManager.deleteAllTokens(
                    username: account.username,
                    accountType: account.accountType,
                    tokenType: tokenType
                )
                DispatchQueue.main.async { completion(.success(true)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func getAvailableTokenTypes(account: AccountData, completion: @escaping (Result<[String], Error>) -> Void) {
        completion(.success([]))
    }


    // MARK: - Platform-Specific

    func openAccountSettings(completion: @escaping (Result<Bool, Error>) -> Void) {
        // iOS doesn't have a centralised account settings page
        completion(.success(false))
    }

    func isConfigured(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    func getPlatformCapabilities(completion: @escaping (Result<[String: Bool], Error>) -> Void) {
        let caps: [String: Bool] = [
            "systemAccountSettings": false,
            "backgroundSync": false,
            "keychainStorage": true,
            "cloudKitSync": false,
            "pushNotificationSync": false,
            "biometricAuth": true,
        ]
        completion(.success(caps))
    }
}
