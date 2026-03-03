import Testing
import Foundation
@testable import ServerPulse

@Suite("MetricHistory Tests")
struct MetricHistoryTests {
    @Test func testEmptyHistory() {
        let history = MetricHistory(capacity: 10)
        #expect(history.cpuHistory.elements.isEmpty)
        #expect(history.memoryHistory.elements.isEmpty)
        #expect(history.networkRxHistory.elements.isEmpty)
        #expect(history.networkTxHistory.elements.isEmpty)
        #expect(history.diskReadHistory.elements.isEmpty)
        #expect(history.diskWriteHistory.elements.isEmpty)
    }

    @Test func testAppendMetrics() {
        var history = MetricHistory(capacity: 10)

        let metrics = ServerMetrics(
            timestamp: Date(),
            cpu: CPUMetrics(
                totalUsage: 0.5, userUsage: 0.3, systemUsage: 0.15,
                ioWait: 0.05, idle: 0.5, steal: 0, perCore: []
            ),
            memory: MemoryMetrics(
                totalBytes: 8_000_000_000, usedBytes: 4_000_000_000,
                freeBytes: 1_000_000_000, availableBytes: 2_000_000_000,
                buffersBytes: 0, cachedBytes: 0,
                swapTotalBytes: 0, swapUsedBytes: 0, swapFreeBytes: 0
            ),
            disks: [
                DiskMetrics(
                    id: "/", mountPoint: "/", filesystem: "ext4",
                    totalBytes: 100_000_000, usedBytes: 50_000_000,
                    availableBytes: 50_000_000,
                    readBytesPerSec: 1000, writeBytesPerSec: 2000,
                    iopsRead: 10, iopsWrite: 20
                )
            ],
            networks: [
                NetworkInterfaceMetrics(
                    id: "eth0",
                    rxBytesPerSec: 5000, txBytesPerSec: 3000,
                    rxPacketsPerSec: 50, txPacketsPerSec: 30,
                    rxErrors: 0, txErrors: 0,
                    totalRxBytes: 1_000_000, totalTxBytes: 500_000
                )
            ],
            temperature: nil,
            loadAverage: LoadAverage(oneMinute: 1.5, fiveMinute: 1.2, fifteenMinute: 1.0),
            uptime: 86400,
            processes: []
        )

        history.append(metrics: metrics)

        #expect(history.cpuHistory.elements.count == 1)
        #expect(history.cpuHistory.elements.first?.value == 0.5)
        #expect(history.networkRxHistory.elements.first?.value == 5000)
        #expect(history.networkTxHistory.elements.first?.value == 3000)
        #expect(history.diskReadHistory.elements.first?.value == 1000)
        #expect(history.diskWriteHistory.elements.first?.value == 2000)
    }
}
