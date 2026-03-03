import Testing
import Foundation
@testable import ServerPulse

@Suite("Docker Models Tests")
struct DockerModelsTests {
    @Test func testContainerStatusIsRunning() {
        #expect(DockerContainer.ContainerStatus.running.isRunning == true)
        #expect(DockerContainer.ContainerStatus.paused.isRunning == false)
        #expect(DockerContainer.ContainerStatus.exited.isRunning == false)
        #expect(DockerContainer.ContainerStatus.dead.isRunning == false)
    }

    @Test func testContainerMetricsMemoryPercent() {
        let metrics = ContainerMetrics(
            cpuPercent: 5.0,
            memoryUsageBytes: 500_000_000,
            memoryLimitBytes: 1_000_000_000,
            networkRxBytes: 0,
            networkTxBytes: 0,
            blockReadBytes: 0,
            blockWriteBytes: 0,
            pids: 10
        )

        #expect(metrics.memoryPercent == 0.5)
    }

    @Test func testContainerMetricsMemoryPercentZeroLimit() {
        let metrics = ContainerMetrics(
            cpuPercent: 0,
            memoryUsageBytes: 0,
            memoryLimitBytes: 0,
            networkRxBytes: 0,
            networkTxBytes: 0,
            blockReadBytes: 0,
            blockWriteBytes: 0,
            pids: 0
        )

        #expect(metrics.memoryPercent == 0)
    }

    @Test func testCommandExecution() {
        var exec = CommandExecution(
            serverId: UUID(),
            serverName: "TestServer",
            command: "uptime"
        )

        #expect(exec.isRunning == true)
        #expect(exec.output.isEmpty)

        exec.output = "up 7 days"
        exec.exitCode = 0
        exec.completedAt = Date()

        #expect(exec.isRunning == false)
        #expect(exec.succeeded == true)
    }

    @Test func testCommandExecutionFailed() {
        var exec = CommandExecution(
            serverId: UUID(),
            serverName: "TestServer",
            command: "invalid"
        )

        exec.exitCode = 127
        exec.error = "command not found"
        exec.completedAt = Date()

        #expect(exec.succeeded == false)
    }
}
