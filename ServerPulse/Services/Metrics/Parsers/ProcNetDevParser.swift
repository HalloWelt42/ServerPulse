import Foundation

struct ProcNetDevParser {
    struct PreviousNetData: Sendable {
        let timestamp: Date
        let interfaces: [String: (rxBytes: UInt64, txBytes: UInt64, rxPackets: UInt64, txPackets: UInt64)]
    }

    static func parse(_ raw: String, previous: PreviousNetData?) -> ([NetworkInterfaceMetrics], PreviousNetData) {
        var interfaces: [NetworkInterfaceMetrics] = []
        var currentData: [String: (rxBytes: UInt64, txBytes: UInt64, rxPackets: UInt64, txPackets: UInt64)] = [:]
        let now = Date()
        let elapsed = previous.map { now.timeIntervalSince($0.timestamp) } ?? 1.0

        let lines = raw.split(separator: "\n").dropFirst(2) // Skip headers

        for line in lines {
            let colonParts = line.split(separator: ":", maxSplits: 1)
            guard colonParts.count == 2 else { continue }
            let name = String(colonParts[0]).trimmingCharacters(in: .whitespaces)

            // Skip loopback
            guard !name.hasPrefix("lo") else { continue }

            let nums = colonParts[1].trimmingCharacters(in: .whitespaces)
                .split(separator: " ").compactMap { UInt64($0) }
            guard nums.count >= 16 else { continue }

            let rxBytes = nums[0]
            let rxPackets = nums[1]
            let rxErrors = nums[2]
            let txBytes = nums[8]
            let txPackets = nums[9]
            let txErrors = nums[10]

            currentData[name] = (rxBytes, txBytes, rxPackets, txPackets)

            var rxBps: Double = 0
            var txBps: Double = 0
            var rxPps: Double = 0
            var txPps: Double = 0

            if let prev = previous?.interfaces[name], elapsed > 0 {
                rxBps = Double(rxBytes - prev.rxBytes) / elapsed
                txBps = Double(txBytes - prev.txBytes) / elapsed
                rxPps = Double(rxPackets - prev.rxPackets) / elapsed
                txPps = Double(txPackets - prev.txPackets) / elapsed
            }

            interfaces.append(NetworkInterfaceMetrics(
                id: name,
                rxBytesPerSec: max(0, rxBps),
                txBytesPerSec: max(0, txBps),
                rxPacketsPerSec: max(0, rxPps),
                txPacketsPerSec: max(0, txPps),
                rxErrors: rxErrors,
                txErrors: txErrors,
                totalRxBytes: rxBytes,
                totalTxBytes: txBytes
            ))
        }

        return (interfaces, PreviousNetData(timestamp: now, interfaces: currentData))
    }
}
