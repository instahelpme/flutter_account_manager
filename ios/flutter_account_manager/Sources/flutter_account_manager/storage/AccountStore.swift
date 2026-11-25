import Foundation

private let kAccountsKey = "com.lkrjangid.account_manager.accounts"

/// Stores account metadata.
///
/// Metadata always lives in `UserDefaults` (JSON encoded). When the Keychain manager has
/// an access group configured, it is additionally written to the Keychain as a generic
/// password item `<accountType>:<username>:account` so that other apps sharing the group
/// can see the account. Reads check the Keychain first and fall back to `UserDefaults`
/// (installs that predate the access group). With a group configured an account is also
/// reported as existing when only `<accountType>:<username>:token:*` items exist.
class AccountStore {

    private let keychain: KeychainManager
    private let defaults: UserDefaults

    init(keychain: KeychainManager, defaults: UserDefaults = .standard) {
        self.keychain = keychain
        self.defaults = defaults
    }

    private var usesKeychain: Bool { keychain.accessGroup != nil }

    // MARK: - Internal Model

    struct StoredAccount: Codable {
        let username: String
        let accountType: String
        var displayName: String?
        var userData: [String: String]?
        let createdAt: Date
        var updatedAt: Date
    }

    // MARK: - CRUD

    func saveAccount(_ account: AccountData) throws {
        var all = loadAll()
        let key = accountKey(username: account.username, accountType: account.accountType)
        let existing = try resolve(username: account.username, accountType: account.accountType)
        let stored = StoredAccount(
            username: account.username,
            accountType: account.accountType,
            displayName: account.displayName,
            userData: compactStringDict(account.userData),
            createdAt: existing?.createdAt ?? Date(),
            updatedAt: Date()
        )
        all[key] = stored
        try persist(all)
        try writeKeychainMetadata(stored)
    }

    func getAccounts(ofType accountType: String) throws -> [AccountData] {
        var byKey: [String: StoredAccount] = [:]
        for stored in loadAll().values where stored.accountType == accountType {
            byKey[accountKey(username: stored.username, accountType: stored.accountType)] = stored
        }
        if usesKeychain {
            // Keychain entries win over UserDefaults entries.
            for item in try keychain.listAccountMetadata(accountType: accountType) {
                guard let stored = decodeMetadata(item.data),
                      stored.accountType == accountType,
                      keychain.metadataKey(username: stored.username, accountType: accountType) == item.key
                else { continue }
                byKey[accountKey(username: stored.username, accountType: accountType)] = stored
            }
        }
        return byKey.values.map { toAccountData($0) }
    }

    func getAccount(username: String, accountType: String) throws -> AccountData? {
        guard let stored = try resolve(username: username, accountType: accountType) else { return nil }
        return toAccountData(stored)
    }

    func updateAccount(_ account: AccountData) throws {
        guard var stored = try resolve(username: account.username, accountType: account.accountType) else {
            return
        }
        stored.displayName = account.displayName
        stored.userData = compactStringDict(account.userData)
        stored.updatedAt = Date()

        var all = loadAll()
        let key = accountKey(username: account.username, accountType: account.accountType)
        if all[key] != nil || !usesKeychain {
            all[key] = stored
            try persist(all)
        }
        try writeKeychainMetadata(stored)
    }

    func removeAccount(username: String, accountType: String) throws {
        var all = loadAll()
        let key = accountKey(username: username, accountType: accountType)
        all.removeValue(forKey: key)
        try persist(all)
        // Harmless when no metadata item exists.
        try keychain.deleteAccountMetadata(username: username, accountType: accountType)
    }

    func accountExists(username: String, accountType: String) -> Bool {
        return (try? resolve(username: username, accountType: accountType)) != nil
    }

    // MARK: - Resolution

    /// Keychain metadata first, then UserDefaults, then (access group only) an account
    /// synthesised from existing token items.
    private func resolve(username: String, accountType: String) throws -> StoredAccount? {
        if usesKeychain {
            if let data = try keychain.retrieveAccountMetadata(username: username, accountType: accountType),
               let stored = decodeMetadata(data) {
                return stored
            }
        }
        let key = accountKey(username: username, accountType: accountType)
        if let stored = loadAll()[key] { return stored }
        if usesKeychain, try keychain.hasAnyToken(username: username, accountType: accountType) {
            let now = Date()
            return StoredAccount(
                username: username,
                accountType: accountType,
                displayName: nil,
                userData: nil,
                createdAt: now,
                updatedAt: now
            )
        }
        return nil
    }

    private func writeKeychainMetadata(_ stored: StoredAccount) throws {
        guard usesKeychain else { return }
        let data = try JSONEncoder().encode(stored)
        try keychain.storeAccountMetadata(
            username: stored.username,
            accountType: stored.accountType,
            data: data
        )
    }

    private func decodeMetadata(_ data: Data) -> StoredAccount? {
        try? JSONDecoder().decode(StoredAccount.self, from: data)
    }

    // MARK: - Private

    /// Converts a Pigeon-generated `[String?: String?]?` dictionary (which uses optional
    /// keys and optional values) into a plain `[String: String]?`, dropping any entries
    /// where the key or value is nil. An empty dictionary stays empty (not nil).
    private func compactStringDict(_ dict: [String?: String?]?) -> [String: String]? {
        guard let dict = dict else { return nil }
        let result = dict.reduce(into: [String: String]()) { acc, pair in
            if let key = pair.key, let value = pair.value {
                acc[key] = value
            }
        }
        return result
    }

    private func accountKey(username: String, accountType: String) -> String {
        "\(accountType):\(username)"
    }

    private func loadAll() -> [String: StoredAccount] {
        guard let data = defaults.data(forKey: kAccountsKey),
              let decoded = try? JSONDecoder().decode([String: StoredAccount].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func persist(_ accounts: [String: StoredAccount]) throws {
        let data = try JSONEncoder().encode(accounts)
        defaults.set(data, forKey: kAccountsKey)
    }

    private func toAccountData(_ stored: StoredAccount) -> AccountData {
        AccountData(
            username: stored.username,
            accountType: stored.accountType,
            displayName: stored.displayName,
            userData: stored.userData.map { dict in
                Dictionary(uniqueKeysWithValues: dict.map { (Optional($0.key), Optional($0.value)) })
            }
        )
    }
}
