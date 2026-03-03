import Testing
@testable import ServerPulse

@Suite("Metrics Model Tests")
struct MetricsTests {
    @Test func testCPUMetricsZero() {
        let cpu = CPUMetrics.zero
        #expect(cpu.totalUsage == 0)
        #expect(cpu.idle == 1.0)
        #expect(cpu.perCore.isEmpty)
    }

    @Test func testMemoryUsagePercent() {
        let mem = MemoryMetrics(
            totalBytes: 8_000_000_000,
            usedBytes: 4_000_000_000,
            freeBytes: 1_000_000_000,
            availableBytes: 2_000_000_000,
            buffersBytes: 500_000_000,
            cachedBytes: 1_500_000_000,
            swapTotalBytes: 512_000_000,
            swapUsedBytes: 100_000_000,
            swapFreeBytes: 412_000_000
        )

        // usagePercent = (total - available) / total = (8G - 2G) / 8G = 0.75
        #expect(mem.usagePercent == 0.75)
    }

    @Test func testMemoryUsagePercentZeroTotal() {
        let mem = MemoryMetrics.zero
        #expect(mem.usagePercent == 0)
    }

    @Test func testSwapUsagePercent() {
        let mem = MemoryMetrics(
            totalBytes: 8_000_000_000,
            usedBytes: 4_000_000_000,
            freeBytes: 1_000_000_000,
            availableBytes: 2_000_000_000,
            buffersBytes: 0,
            cachedBytes: 0,
            swapTotalBytes: 1_000_000_000,
            swapUsedBytes: 250_000_000,
            swapFreeBytes: 750_000_000
        )

        #expect(mem.swapUsagePercent == 0.25)
    }

    @Test func testSwapUsagePercentZero() {
        let mem = MemoryMetrics.zero
        #expect(mem.swapUsagePercent == 0)
    }

    @Test func testDiskUsagePercent() {
        let disk = DiskMetrics(
            id: "/",
            mountPoint: "/",
            filesystem: "ext4",
            totalBytes: 1_000_000_000,
            usedBytes: 900_000_000,
            availableBytes: 100_000_000,
            readBytesPerSec: 0,
            writeBytesPerSec: 0,
            iopsRead: 0,
            iopsWrite: 0
        )

        #expect(disk.usagePercent == 0.9)
    }

    @Test func testDiskUsagePercentZero() {
        let disk = DiskMetrics(
            id: "/",
            mountPoint: "/",
            filesystem: "ext4",
            totalBytes: 0,
            usedBytes: 0,
            availableBytes: 0,
            readBytesPerSec: 0,
            writeBytesPerSec: 0,
            iopsRead: 0,
            iopsWrite: 0
        )

        #expect(disk.usagePercent == 0)
    }

    @Test func testLoadAverageZero() {
        let load = LoadAverage.zero
        #expect(load.oneMinute == 0)
        #expect(load.fiveMinute == 0)
        #expect(load.fifteenMinute == 0)
    }

    @Test func testTemperatureMax() {
        let temp = TemperatureMetrics(sensors: [
            .init(id: "cpu", label: "CPU", temperatureCelsius: 45, highThreshold: 80, criticalThreshold: 100),
            .init(id: "gpu", label: "GPU", temperatureCelsius: 62, highThreshold: 90, criticalThreshold: 105),
        ])

        #expect(temp.maxTemperature == 62)
    }

    @Test func testTemperatureMaxEmpty() {
        let temp = TemperatureMetrics(sensors: [])
        #expect(temp.maxTemperature == nil)
    }

    @Test func testCPURawTicksTotal() {
        let ticks = CPURawTicks(
            user: 100, nice: 10, system: 50, idle: 800,
            iowait: 20, irq: 5, softirq: 3, steal: 2
        )

        #expect(ticks.total == 990)
        #expect(ticks.active == 170) // total - idle - iowait
    }
}
