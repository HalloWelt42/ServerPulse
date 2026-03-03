import SwiftData
import Foundation

@Model
final class Server {
    var id: UUID
    var name: String
    var hostname: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var credentialKeychainID: String?
    var sshKeyKeychainID: String?
    var group: ServerGroup?
    var isEnabled: Bool
    var pollingInterval: TimeInterval
    var notes: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    // Docker configuration
    var dockerEnabled: Bool
    var dockerSocketPath: String

    // Connection settings
    var connectionTimeout: TimeInterval
    var keepAliveInterval: TimeInterval

    @Transient var connectionState: ConnectionState = .disconnected
    @Transient var lastMetrics: ServerMetrics?
    @Transient var metricsHistory: MetricHistory = MetricHistory()

    enum AuthMethod: String, Codable {
        case password
        case key
        case keyAndPassword
    }

    enum ConnectionState: String, Sendable {
        case disconnected
        case connecting
        case connected
        case error
    }

    init(
        name: String,
        hostname: String,
        port: Int = 22,
        username: String = "pi",
        authMethod: AuthMethod = .password,
        dockerEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.hostname = hostname
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.credentialKeychainID = nil
        self.sshKeyKeychainID = nil
        self.group = nil
        self.isEnabled = true
        self.pollingInterval = 5
        self.notes = ""
        self.sortOrder = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        self.dockerEnabled = dockerEnabled
        self.dockerSocketPath = "/var/run/docker.sock"
        self.connectionTimeout = 10
        self.keepAliveInterval = 30
    }
}
