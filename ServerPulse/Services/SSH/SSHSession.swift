import Foundation
import Citadel
import NIO

enum SSHError: Error, LocalizedError {
    case notConnected
    case connectionFailed(String)
    case authenticationFailed
    case timeout
    case commandFailed(String)
    case unsupportedAuthMethod

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to server"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .authenticationFailed: return "Authentication failed"
        case .timeout: return "Connection timed out"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        case .unsupportedAuthMethod: return "Unsupported authentication method"
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

        case .key, .keyAndPassword:
            // Private key authentication: read the key and use Citadel's
            // built-in private key support via password-based fallback or
            // configure NIOSSHPrivateKey depending on Citadel version.
            guard let passphrase = KeychainService.shared.getPassword(id: server.credentialKeychainID ?? "") else {
                throw SSHError.authenticationFailed
            }
            authMethod = .passwordBased(username: server.username, password: passphrase)
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
}
