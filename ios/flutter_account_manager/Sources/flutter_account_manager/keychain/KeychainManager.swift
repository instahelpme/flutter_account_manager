import Foundation
import Security

/// Provides secure credential and auth token storage using iOS Keychain Services.
///
/// Pass a non-nil `accessGroup` to store and retrieve items in a shared Keychain
/// Access Group (useful for cross-app credential sharing). When `accessGroup` is
/// nil, items are stored in the app's private partition (default behaviour).
class KeychainManager {

    /// Convenience singleton with no access group — retains backward compatibility
    /// for apps that do not need cross-app credential sharing.
    static let shared = KeychainManager()

    private let serviceName = "com.lkrjangid.account_manager"

    /// The Keychain Access Group used for all operations, or nil for the app's
    /// private partition.
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

    // MARK: - Private Helpers

    private func credentialKey(username: String, accountType: String) -> String {
        "\(accountType):\(username)"
    }

    private func tokenKey(username: String, accountType: String, tokenType: String) -> String {
        "\(accountType):\(username):token:\(tokenType)"
    }

    /// Base Keychain query dictionary for the given key.
    /// Includes `kSecAttrAccessGroup` when an access group is configured.
    private func baseQuery(key: String) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]
        if let group = accessGroup {
            q[kSecAttrAccessGroup as String] = group
        }
        return q
    }

    private func storeItem(key: String, data: Data) throws {
        let query = baseQuery(key: key)
        // Delete any existing item first (handles both insert and update).
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
