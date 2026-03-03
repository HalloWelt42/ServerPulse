import Foundation
import Observation

@MainActor
@Observable
final class TerminalSessionManager {
    var activeSessions: [TerminalSessionInfo] = []
    var selectedSessionId: UUID?
    /// Set to true when a session is opened from outside the terminal view (e.g. detail view)
    /// MainContentView observes this and switches to the terminal section
    var shouldNavigateToTerminal: Bool = false

    struct TerminalSessionInfo: Identifiable {
        let id: UUID
        let serverName: String
        let serverId: UUID
        let session: SSHSession
        var title: String
        var isConnected: Bool
    }

    func openSession(for server: Server, connectionManager: SSHConnectionManager) async throws -> UUID {
        let session = try await connectionManager.createTerminalSession(for: server)
        let info = TerminalSessionInfo(
            id: session.id,
            serverName: server.name,
            serverId: server.id,
            session: session,
            title: "\(server.name) - bash",
            isConnected: true
        )
        activeSessions.append(info)
        selectedSessionId = info.id
        shouldNavigateToTerminal = true
        return info.id
    }

    func closeSession(id: UUID) async {
        if let index = activeSessions.firstIndex(where: { $0.id == id }) {
            let session = activeSessions[index].session
            await session.disconnect()
            activeSessions.remove(at: index)

            if selectedSessionId == id {
                selectedSessionId = activeSessions.last?.id
            }
        }
    }

    func closeAll() async {
        for info in activeSessions {
            await info.session.disconnect()
        }
        activeSessions.removeAll()
        selectedSessionId = nil
    }

    var selectedSession: TerminalSessionInfo? {
        activeSessions.first { $0.id == selectedSessionId }
    }
}
