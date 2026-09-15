import Foundation

enum KeychainError: LocalizedError {
    case unableToStore(status: OSStatus)
    case unableToRetrieve(status: OSStatus)
    case unableToDelete(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToStore(let status):
            return "Keychain store failed with status: \(status)"
        case .unableToRetrieve(let status):
            return "Keychain retrieve failed with status: \(status)"
        case .unableToDelete(let status):
            return "Keychain delete failed with status: \(status)"
        }
    }
}
