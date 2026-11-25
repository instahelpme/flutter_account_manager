import Foundation
import Security

/// Provides secure credential and auth token storage using iOS Keychain Services.
///
/// Pass a non-nil `accessGroup` to store and retrieve items in a shared Keychain
/// Access Group (cross-app credential sharing). When `accessGroup` is nil, the
/// queries carry no `kSecAttrAccessGroup` and behave exactly as before.
class KeychainManager {

    private let serviceName = "com.lkrjangid.account_manager"

    /// The full Keychain Access Group (including the app identifier prefix) used for
    /// all operations, or nil for the default behaviour.
    let accessGroup: String?

    init(accessGroup: String? = nil) {
        self.accessGroup = accessGroup
    }

    // MARK: - Credential Operations

    func storeCredentials(username: String, password: String, accountType: String) throws {
        let key = credentialKey(username: username, accountType: accountType)
        let data = password.data(using: .utf8)!
        try storeItem(key: key, data: data)
    }

    func retrieveCredentials(username: String, accountType: String) throws -> String? {
        let key = credentialKey(username: username, accountType: accountType)
        guard let data = try retrieveItem(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteCredentials(username: String, accountType: String) throws {
        let key = credentialKey(username: username, accountType: accountType)
        try deleteItem(key: key)
    }

    // MARK: - Auth Token Operations

    func storeAuthToken(username: String, accountType: String, tokenType: String, token: String) throws {
        let key = tokenKey(username: username, accountType: accountType, tokenType: tokenType)
        let data = token.data(using: .utf8)!
        try storeItem(key: key, data: data)
    }

    func retrieveAuthToken(username: String, accountType: String, tokenType: String) throws -> String? {
        let key = tokenKey(username: username, accountType: accountType, tokenType: tokenType)
        guard let data = try retrieveItem(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteAuthToken(username: String, accountType: String, tokenType: String) throws {
        let key = tokenKey(username: username, accountType: accountType, tokenType: tokenType)
        try deleteItem(key: key)
    }

    func deleteAllTokens(username: String, accountType: String, tokenType: String) throws {
        try deleteAuthToken(username: username, accountType: accountType, tokenType: tokenType)
    }

    /// Deletes every `<accountType>:<username>:token:*` item, whatever its token type.
    func deleteEveryToken(username: String, accountType: String) throws {
        let prefix = tokenKeyPrefix(username: username, accountType: accountType)
        for item in try listItems(accountPrefix: prefix, returnData: false) {
            try deleteItem(key: item.key)
        }
    }

    /// Returns true if at least one `<accountType>:<username>:token:*` item exists.
    func hasAnyToken(username: String, accountType: String) throws -> Bool {
        let prefix = tokenKeyPrefix(username: username, accountType: accountType)
        return !(try listItems(accountPrefix: prefix, returnData: false)).isEmpty
    }

    // MARK: - Account Metadata Operations

    func storeAccountMetadata(username: String, accountType: String, data: Data) throws {
        try storeItem(key: metadataKey(username: username, accountType: accountType), data: data)
    }

    func retrieveAccountMetadata(username: String, accountType: String) throws -> Data? {
        try retrieveItem(key: metadataKey(username: username, accountType: accountType))
    }

    func deleteAccountMetadata(username: String, accountType: String) throws {
        try deleteItem(key: metadataKey(username: username, accountType: accountType))
    }

    /// Returns `(key, data)` of every item that may be account metadata for `accountType`.
    /// Callers must verify that the decoded content matches the key, because token
    /// items can also end in `:account` (token type "account").
    func listAccountMetadata(accountType: String) throws -> [(key: String, data: Data)] {
        try listItems(accountPrefix: "\(accountType):", returnData: true)
            .filter { $0.key.hasSuffix(KeychainManager.metadataSuffix) }
            .compactMap { item in item.data.map { (key: item.key, data: $0) } }
    }

    /// The Keychain key under which account metadata is stored.
    func metadataKey(username: String, accountType: String) -> String {
        "\(accountType):\(username)\(KeychainManager.metadataSuffix)"
    }

    // MARK: - Private Helpers

    private func credentialKey(username: String, accountType: String) -> String {
        "\(accountType):\(username)"
    }

    static let metadataSuffix = ":account"

    private func tokenKeyPrefix(username: String, accountType: String) -> String {
        "\(accountType):\(username):token:"
    }

    private func tokenKey(username: String, accountType: String, tokenType: String) -> String {
        tokenKeyPrefix(username: username, accountType: accountType) + tokenType
    }

    /// Base query for generic-password items of this plugin's service.
    /// Includes `kSecAttrAccessGroup` when an access group is configured.
    func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    /// Base query for the item with the given account key.
    func baseQuery(key: String) -> [String: Any] {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key
        return query
    }

    /// Lists all items whose account key starts with `accountPrefix`. The Keychain has
    /// no prefix matching, so all items of the service are fetched and filtered here.
    private func listItems(accountPrefix: String, returnData: Bool) throws -> [(key: String, data: Data?)] {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        if returnData {
            query[kSecReturnData as String] = true
        }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else {
            throw KeychainError.unableToRetrieve(status: status)
        }
        guard let rows = result as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let key = row[kSecAttrAccount as String] as? String,
                  key.hasPrefix(accountPrefix) else { return nil }
            return (key: key, data: row[kSecValueData as String] as? Data)
        }
    }

    private func storeItem(key: String, data: Data) throws {
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status: status)
        }
    }

    private func retrieveItem(key: String) throws -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.unableToRetrieve(status: status)
        }
        return result as? Data
    }

    private func deleteItem(key: String) throws {
        let query = baseQuery(key: key)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status: status)
        }
    }
}
