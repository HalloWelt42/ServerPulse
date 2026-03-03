import Foundation
import KeychainAccess

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case unexpectedData
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .itemNotFound: return "Keychain item not found"
        case .unexpectedData: return "Unexpected data format"
        case .saveFailed(let msg): return "Save failed: \(msg)"
        }
    }
}

final class KeychainService {
    static let shared = KeychainService()

    private let keychain: Keychain

    init() {
        keychain = Keychain(service: "com.serverpulse.ssh")
            .accessibility(.whenUnlocked)
    }

    // MARK: - Passwords

    func storePassword(_ password: String, for id: String) throws {
        try keychain.set(password, key: "pwd-\(id)")
    }

    func getPassword(id: String) -> String? {
        try? keychain.get("pwd-\(id)")
    }

    func deletePassword(id: String) throws {
        try keychain.remove("pwd-\(id)")
    }

    // MARK: - SSH Keys

    func storeSSHKey(_ keyData: Data, for id: String) throws {
        try keychain.set(keyData, key: "key-\(id)")
    }

    func getSSHKey(id: String) -> Data? {
        try? keychain.getData("key-\(id)")
    }

    func deleteSSHKey(id: String) throws {
        try keychain.remove("key-\(id)")
    }

    // MARK: - Cleanup

    func deleteAll(for id: String) {
        try? keychain.remove("pwd-\(id)")
        try? keychain.remove("key-\(id)")
    }

    // MARK: - Generate Credential ID

    static func newCredentialID() -> String {
        UUID().uuidString
    }
}
