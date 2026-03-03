import Foundation
import Observation

@MainActor
@Observable
final class MetricsEngine {
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]
    private var previousStates: [UUID: LinuxMetricsCollector.PreviousState] = [:]

    var serverMetrics: [UUID: ServerMetrics] = [:]
    var serverHistories: [UUID: MetricHistory] = [:]

    private let connectionManager: SSHConnectionManager

    init(connectionManager: SSHConnectionManager) {
        self.connectionManager = connectionManager
    }

    func startPolling(server: Server) {
        guard pollingTasks[server.id] == nil else { return }
        serverHistories[server.id] = MetricHistory()

        let task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.pollOnce(server: server)
                try? await Task.sleep(for: .seconds(server.pollingInterval))
            }
        }
        pollingTasks[server.id] = task
    }

    func stopPolling(serverId: UUID) {
        pollingTasks[serverId]?.cancel()
        pollingTasks.removeValue(forKey: serverId)
        previousStates.removeValue(forKey: serverId)
    }

    func stopAll() {
        for (id, _) in pollingTasks {
            stopPolling(serverId: id)
        }
    }

    func isPolling(serverId: UUID) -> Bool {
        pollingTasks[serverId] != nil
    }

    private func pollOnce(server: Server) async {
        guard let session = connectionManager.getMetricsSession(for: server.id) else { return }

        do {
            let rawOutput = try await session.execute(LinuxMetricsCollector.batchCommand)

            let previousState = previousStates[server.id] ?? LinuxMetricsCollector.PreviousState()
            let (metrics, newState) = LinuxMetricsCollector.collect(
                rawOutput: rawOutput,
                previous: previousState
            )

            previousStates[server.id] = newState
            serverMetrics[server.id] = metrics

            var history = serverHistories[server.id] ?? MetricHistory()
            history.append(metrics: metrics)
            serverHistories[server.id] = history

        } catch {
            // Connection may have dropped
            connectionManager.serverStates[server.id] = .error
        }
    }

    func fetchProcesses(for server: Server) async -> [RemoteProcess] {
        guard let session = connectionManager.getMetricsSession(for: server.id) else { return [] }

        do {
            let output = try await session.execute("ps aux --sort=-%cpu | head -50")
            return PsAuxParser.parse(output)
        } catch {
            return []
        }
    }
}
