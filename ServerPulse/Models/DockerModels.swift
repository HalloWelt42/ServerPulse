import Foundation

struct DockerContainer: Sendable, Identifiable {
    let id: String
    let name: String
    let image: String
    let status: ContainerStatus
    let state: String
    let ports: String
    let created: String
    let metrics: ContainerMetrics?
    let serverId: UUID

    enum ContainerStatus: String, Sendable {
        case running
        case paused
        case exited
        case restarting
        case dead
        case created
        case unknown

        var isRunning: Bool { self == .running }
    }
}

struct ContainerMetrics: Sendable {
    let cpuPercent: Double
    let memoryUsageBytes: UInt64
    let memoryLimitBytes: UInt64
    let networkRxBytes: UInt64
    let networkTxBytes: UInt64
    let blockReadBytes: UInt64
    let blockWriteBytes: UInt64
    let pids: Int

    var memoryPercent: Double {
        guard memoryLimitBytes > 0 else { return 0 }
        return Double(memoryUsageBytes) / Double(memoryLimitBytes)
    }
}

struct CommandExecution: Identifiable, Sendable {
    let id: UUID
    let serverId: UUID
    let serverName: String
    let command: String
    let startedAt: Date
    var completedAt: Date?
    var output: String
    var exitCode: Int?
    var error: String?

    var isRunning: Bool { completedAt == nil }
    var succeeded: Bool { exitCode == 0 }

    init(serverId: UUID, serverName: String, command: String) {
        self.id = UUID()
        self.serverId = serverId
        self.serverName = serverName
        self.command = command
        self.startedAt = Date()
        self.output = ""
    }
}
