import Foundation
import Observation

@MainActor
@Observable
final class DockerService {
    var containers: [UUID: [DockerContainer]] = [:]

    func fetchContainers(for server: Server, session: SSHSession) async {
        guard server.dockerEnabled else { return }

        do {
            let psOutput = try await session.execute(
                "docker ps -a --format '{{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.State}}\\t{{.Ports}}\\t{{.CreatedAt}}'"
            )
            let statsOutput = try await session.execute(
                "docker stats --no-stream --format '{{.Name}}\\t{{.CPUPerc}}\\t{{.MemUsage}}\\t{{.NetIO}}\\t{{.BlockIO}}\\t{{.PIDs}}'"
            )

            let statsByName = parseStats(statsOutput)
            var result: [DockerContainer] = []

            for line in psOutput.split(separator: "\n") {
                let parts = line.split(separator: "\t", maxSplits: 6).map(String.init)
                guard parts.count >= 5 else { continue }

                let name = parts[1]
                let metrics = statsByName[name]

                result.append(DockerContainer(
                    id: parts[0],
                    name: name,
                    image: parts[2],
                    status: parseStatus(parts[4]),
                    state: parts[4],
                    ports: parts.count > 5 ? parts[5] : "",
                    created: parts.count > 6 ? parts[6] : "",
                    metrics: metrics,
                    serverId: server.id
                ))
            }

            containers[server.id] = result
        } catch {
            containers[server.id] = []
        }
    }

    func startContainer(_ containerId: String, on session: SSHSession) async throws {
        _ = try await session.execute("docker start \(containerId)")
    }

    func stopContainer(_ containerId: String, on session: SSHSession) async throws {
        _ = try await session.execute("docker stop \(containerId)")
    }

    func restartContainer(_ containerId: String, on session: SSHSession) async throws {
        _ = try await session.execute("docker restart \(containerId)")
    }

    private func parseStatus(_ state: String) -> DockerContainer.ContainerStatus {
        switch state.lowercased() {
        case "running": return .running
        case "paused": return .paused
        case "exited": return .exited
        case "restarting": return .restarting
        case "dead": return .dead
        case "created": return .created
        default: return .unknown
        }
    }

    private func parseStats(_ output: String) -> [String: ContainerMetrics] {
        var result: [String: ContainerMetrics] = [:]

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 5).map(String.init)
            guard parts.count >= 6 else { continue }

            let name = parts[0]
            let cpuStr = parts[1].replacingOccurrences(of: "%", with: "")
            let cpuPercent = Double(cpuStr) ?? 0

            let memParts = parts[2].split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            let memUsage = parseByteString(memParts.first ?? "0")
            let memLimit = parseByteString(memParts.count > 1 ? memParts[1] : "0")

            let netParts = parts[3].split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            let netRx = parseByteString(netParts.first ?? "0")
            let netTx = parseByteString(netParts.count > 1 ? netParts[1] : "0")

            let blockParts = parts[4].split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            let blockRead = parseByteString(blockParts.first ?? "0")
            let blockWrite = parseByteString(blockParts.count > 1 ? blockParts[1] : "0")

            let pids = Int(parts[5]) ?? 0

            result[name] = ContainerMetrics(
                cpuPercent: cpuPercent,
                memoryUsageBytes: memUsage,
                memoryLimitBytes: memLimit,
                networkRxBytes: netRx,
                networkTxBytes: netTx,
                blockReadBytes: blockRead,
                blockWriteBytes: blockWrite,
                pids: pids
            )
        }

        return result
    }

    private func parseByteString(_ str: String) -> UInt64 {
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        let number: Double
        let multiplier: UInt64

        if trimmed.hasSuffix("GiB") || trimmed.hasSuffix("GB") {
            number = Double(trimmed.dropLast(3)) ?? 0
            multiplier = 1_073_741_824
        } else if trimmed.hasSuffix("MiB") || trimmed.hasSuffix("MB") {
            number = Double(trimmed.dropLast(3)) ?? 0
            multiplier = 1_048_576
        } else if trimmed.hasSuffix("KiB") || trimmed.hasSuffix("KB") || trimmed.hasSuffix("kB") {
            number = Double(trimmed.dropLast(2)) ?? 0
            multiplier = 1_024
        } else if trimmed.hasSuffix("B") {
            number = Double(trimmed.dropLast(1)) ?? 0
            multiplier = 1
        } else {
            number = Double(trimmed) ?? 0
            multiplier = 1
        }

        return UInt64(number * Double(multiplier))
    }
}
