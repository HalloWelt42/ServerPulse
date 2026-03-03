import Foundation
import Observation

@MainActor
@Observable
final class SSHConnectionManager {
    private var metricsConnections: [UUID: SSHSession] = [:]
    private var terminalConnections: [UUID: [SSHSession]] = [:]

    var serverStates: [UUID: Server.ConnectionState] = [:]

    func connect(to server: Server) async throws {
        serverStates[server.id] = .connecting

        let session = SSHSession(server: server)
        do {
            try await session.connect()
            metricsConnections[server.id] = session
            serverStates[server.id] = .connected
        } catch {
            serverStates[server.id] = .error
            throw error
        }
    }

    func disconnect(from serverId: UUID) async {
        if let session = metricsConnections[serverId] {
            await session.disconnect()
            metricsConnections.removeValue(forKey: serverId)
        }

        if let sessions = terminalConnections[serverId] {
            for session in sessions {
                await session.disconnect()
            }
            terminalConnections.removeValue(forKey: serverId)
        }

        serverStates[serverId] = .disconnected
    }

    func disconnectAll() async {
        for (id, _) in metricsConnections {
            await disconnect(from: id)
        }
    }

    func getMetricsSession(for serverId: UUID) -> SSHSession? {
        metricsConnections[serverId]
    }

    func isConnected(serverId: UUID) -> Bool {
        serverStates[serverId] == .connected
    }

    func createTerminalSession(for server: Server) async throws -> SSHSession {
        let session = SSHSession(server: server)
        try await session.connect()

        var sessions = terminalConnections[server.id] ?? []
        sessions.append(session)
        terminalConnections[server.id] = sessions

        return session
    }

    func releaseTerminalSession(_ session: SSHSession) async {
        await session.disconnect()
        let serverId = session.server.id
        terminalConnections[serverId]?.removeAll { $0.id == session.id }
    }
}
