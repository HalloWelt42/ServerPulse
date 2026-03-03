import Foundation

struct ServerMetrics: Sendable {
    let timestamp: Date
    let cpu: CPUMetrics
    let memory: MemoryMetrics
    let disks: [DiskMetrics]
    let networks: [NetworkInterfaceMetrics]
    let temperature: TemperatureMetrics?
    let loadAverage: LoadAverage
    let uptime: TimeInterval
    let processes: [RemoteProcess]
}

struct CPUMetrics: Sendable {
    let totalUsage: Double
    let userUsage: Double
    let systemUsage: Double
    let ioWait: Double
    let idle: Double
    let steal: Double
    let perCore: [CoreMetrics]

    struct CoreMetrics: Sendable, Identifiable {
        let id: Int
        let usage: Double
        let user: Double
        let system: Double
        let idle: Double
    }

    static let zero = CPUMetrics(
        totalUsage: 0, userUsage: 0, systemUsage: 0,
        ioWait: 0, idle: 1.0, steal: 0, perCore: []
    )
}

struct CPURawTicks: Sendable {
    let user: UInt64
    let nice: UInt64
    let system: UInt64
    let idle: UInt64
    let iowait: UInt64
    let irq: UInt64
    let softirq: UInt64
    let steal: UInt64

    var total: UInt64 { user + nice + system + idle + iowait + irq + softirq + steal }
    var active: UInt64 { total - idle - iowait }
}

struct MemoryMetrics: Sendable {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let freeBytes: UInt64
    let availableBytes: UInt64
    let buffersBytes: UInt64
    let cachedBytes: UInt64
    let swapTotalBytes: UInt64
    let swapUsedBytes: UInt64
    let swapFreeBytes: UInt64

    var usagePercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(totalBytes - availableBytes) / Double(totalBytes)
    }

    var swapUsagePercent: Double {
        guard swapTotalBytes > 0 else { return 0 }
        return Double(swapUsedBytes) / Double(swapTotalBytes)
    }

    static let zero = MemoryMetrics(
        totalBytes: 0, usedBytes: 0, freeBytes: 0,
        availableBytes: 0, buffersBytes: 0, cachedBytes: 0,
        swapTotalBytes: 0, swapUsedBytes: 0, swapFreeBytes: 0
    )
}

struct DiskMetrics: Sendable, Identifiable {
    let id: String
    let mountPoint: String
    let filesystem: String
    let totalBytes: UInt64
    let usedBytes: UInt64
    let availableBytes: UInt64
    let readBytesPerSec: Double
    let writeBytesPerSec: Double
    let iopsRead: Double
    let iopsWrite: Double

    var usagePercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

struct NetworkInterfaceMetrics: Sendable, Identifiable {
    let id: String
    let rxBytesPerSec: Double
    let txBytesPerSec: Double
    let rxPacketsPerSec: Double
    let txPacketsPerSec: Double
    let rxErrors: UInt64
    let txErrors: UInt64
    let totalRxBytes: UInt64
    let totalTxBytes: UInt64
}

struct TemperatureMetrics: Sendable {
    let sensors: [TemperatureSensor]

    struct TemperatureSensor: Sendable, Identifiable {
        let id: String
        let label: String
        let temperatureCelsius: Double
        let highThreshold: Double?
        let criticalThreshold: Double?
    }

    var maxTemperature: Double? {
        sensors.map(\.temperatureCelsius).max()
    }
}

struct LoadAverage: Sendable {
    let oneMinute: Double
    let fiveMinute: Double
    let fifteenMinute: Double

    static let zero = LoadAverage(oneMinute: 0, fiveMinute: 0, fifteenMinute: 0)
}

struct RemoteProcess: Sendable, Identifiable {
    let id: Int // PID
    let user: String
    let cpuPercent: Double
    let memPercent: Double
    let vsz: UInt64
    let rss: UInt64
    let tty: String
    let state: String
    let startTime: String
    let command: String
}
