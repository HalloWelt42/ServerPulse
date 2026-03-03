import Foundation

struct ProcDiskstatsParser {
    struct PreviousDiskData: Sendable {
        let timestamp: Date
        let devices: [String: (readSectors: UInt64, writeSectors: UInt64, readOps: UInt64, writeOps: UInt64)]
    }

    static func parse(_ raw: String, previous: PreviousDiskData?) -> ([String: (readBps: Double, writeBps: Double, readIops: Double, writeIops: Double)], PreviousDiskData) {
        var results: [String: (readBps: Double, writeBps: Double, readIops: Double, writeIops: Double)] = [:]
        var currentData: [String: (readSectors: UInt64, writeSectors: UInt64, readOps: UInt64, writeOps: UInt64)] = [:]
        let now = Date()
        let elapsed = previous.map { now.timeIntervalSince($0.timestamp) } ?? 1.0
        let sectorSize: Double = 512

        for line in raw.split(separator: "\n") {
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count >= 14 else { continue }

            let deviceName = parts[2]
            // Skip partition devices (only keep whole disks and meaningful partitions)
            guard !deviceName.hasPrefix("loop"), !deviceName.hasPrefix("ram") else { continue }

            let readOps = UInt64(parts[3]) ?? 0
            let readSectors = UInt64(parts[5]) ?? 0
            let writeOps = UInt64(parts[7]) ?? 0
            let writeSectors = UInt64(parts[9]) ?? 0

            currentData[deviceName] = (readSectors, writeSectors, readOps, writeOps)

            if let prev = previous?.devices[deviceName], elapsed > 0 {
                let readBps = Double(readSectors - prev.readSectors) * sectorSize / elapsed
                let writeBps = Double(writeSectors - prev.writeSectors) * sectorSize / elapsed
                let readIops = Double(readOps - prev.readOps) / elapsed
                let writeIops = Double(writeOps - prev.writeOps) / elapsed
                results[deviceName] = (max(0, readBps), max(0, writeBps), max(0, readIops), max(0, writeIops))
            }
        }

        return (results, PreviousDiskData(timestamp: now, devices: currentData))
    }
}
