import Foundation

struct MetricDataPoint: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let value: Double

    init(timestamp: Date = Date(), value: Double) {
        self.id = UUID()
        self.timestamp = timestamp
        self.value = value
    }
}

struct MetricHistory: Sendable {
    var cpuHistory: RingBuffer<MetricDataPoint>
    var memoryHistory: RingBuffer<MetricDataPoint>
    var networkRxHistory: RingBuffer<MetricDataPoint>
    var networkTxHistory: RingBuffer<MetricDataPoint>
    var diskReadHistory: RingBuffer<MetricDataPoint>
    var diskWriteHistory: RingBuffer<MetricDataPoint>

    init(capacity: Int = 300) {
        cpuHistory = RingBuffer(capacity: capacity)
        memoryHistory = RingBuffer(capacity: capacity)
        networkRxHistory = RingBuffer(capacity: capacity)
        networkTxHistory = RingBuffer(capacity: capacity)
        diskReadHistory = RingBuffer(capacity: capacity)
        diskWriteHistory = RingBuffer(capacity: capacity)
    }

    mutating func append(metrics: ServerMetrics) {
        let now = metrics.timestamp
        cpuHistory.append(MetricDataPoint(timestamp: now, value: metrics.cpu.totalUsage))
        memoryHistory.append(MetricDataPoint(timestamp: now, value: metrics.memory.usagePercent))

        let totalRx = metrics.networks.reduce(0.0) { $0 + $1.rxBytesPerSec }
        let totalTx = metrics.networks.reduce(0.0) { $0 + $1.txBytesPerSec }
        networkRxHistory.append(MetricDataPoint(timestamp: now, value: totalRx))
        networkTxHistory.append(MetricDataPoint(timestamp: now, value: totalTx))

        let totalRead = metrics.disks.reduce(0.0) { $0 + $1.readBytesPerSec }
        let totalWrite = metrics.disks.reduce(0.0) { $0 + $1.writeBytesPerSec }
        diskReadHistory.append(MetricDataPoint(timestamp: now, value: totalRead))
        diskWriteHistory.append(MetricDataPoint(timestamp: now, value: totalWrite))
    }
}
