import Foundation
import Citadel
import Crypto
import NIOSSH
import NIO

enum SSHError: Error, LocalizedError {
    case notConnected
    case connectionFailed(String)
    case authenticationFailed
    case timeout
    case commandFailed(String)
    case unsupportedAuthMethod
    case privateKeyNotFound
    case privateKeyInvalid(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to server"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .authenticationFailed: return "Authentication failed"
        case .timeout: return "Connection timed out"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        case .unsupportedAuthMethod: return "Unsupported authentication method"
        case .privateKeyNotFound: return "SSH private key not found in keychain"
        case .privateKeyInvalid(let msg): return "Invalid SSH key: \(msg)"
        }
    }
}

actor SSHSession {
    let id: UUID
    let server: Server
    private var client: SSHClient?
    private(set) var isConnected: Bool = false
    private var lastActivity: Date = Date()

    init(server: Server) {
        self.id = UUID()
        self.server = server
    }

    func connect() async throws {
        let authMethod: SSHAuthenticationMethod

        switch server.authMethod {
        case .password:
            guard let password = KeychainService.shared.getPassword(id: server.credentialKeychainID ?? "") else {
                throw SSHError.authenticationFailed
            }
            authMethod = .passwordBased(username: server.username, password: password)

        case .key:
            authMethod = try buildKeyAuth(passphrase: nil)

        case .keyAndPassword:
            let passphrase = KeychainService.shared.getPassword(id: server.credentialKeychainID ?? "")
            authMethod = try buildKeyAuth(passphrase: passphrase)
        }

        do {
            client = try await SSHClient.connect(
                host: server.hostname,
                port: server.port,
                authenticationMethod: authMethod,
                hostKeyValidator: .acceptAnything(),
                reconnect: .never
            )
            isConnected = true
            lastActivity = Date()
        } catch {
            isConnected = false
            throw SSHError.connectionFailed(error.localizedDescription)
        }
    }

    func execute(_ command: String) async throws -> String {
        guard let client, isConnected else { throw SSHError.notConnected }
        lastActivity = Date()

        let buffer = try await client.executeCommand(command)
        return String(buffer: buffer)
    }

    func disconnect() async {
        try? await client?.close()
        client = nil
        isConnected = false
    }

    // MARK: - Private Key Authentication

    private func buildKeyAuth(passphrase: String?) throws -> SSHAuthenticationMethod {
        guard let keyData = KeychainService.shared.getSSHKey(id: server.sshKeyKeychainID ?? "") else {
            throw SSHError.privateKeyNotFound
        }

        guard let keyString = String(data: keyData, encoding: .utf8) else {
            throw SSHError.privateKeyInvalid("Key is not valid UTF-8")
        }

        let decryptionKey = passphrase?.data(using: .utf8)
        let username = server.username

        // Try Ed25519 first (most common modern key type)
        if let method = try? ed25519Auth(keyString: keyString, decryptionKey: decryptionKey, username: username) {
            return method
        }

        // Try RSA
        if let method = try? rsaAuth(keyString: keyString, decryptionKey: decryptionKey, username: username) {
            return method
        }

        throw SSHError.privateKeyInvalid("Unsupported key type (supported: Ed25519, RSA)")
    }

    private func ed25519Auth(keyString: String, decryptionKey: Data?, username: String) throws -> SSHAuthenticationMethod {
        let privateKey = try Curve25519.Signing.PrivateKey(sshEd25519: keyString, decryptionKey: decryptionKey)
        return .ed25519(username: username, privateKey: privateKey)
    }

    private func rsaAuth(keyString: String, decryptionKey: Data?, username: String) throws -> SSHAuthenticationMethod {
        let privateKey = try Insecure.RSA.PrivateKey(sshRsa: keyString, decryptionKey: decryptionKey)
        return .rsa(username: username, privateKey: privateKey)
    }
}
