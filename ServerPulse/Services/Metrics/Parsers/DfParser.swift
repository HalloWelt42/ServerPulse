import Foundation

struct DfParser {
    static func parse(_ raw: String) -> [DiskUsageEntry] {
        var entries: [DiskUsageEntry] = []
        let lines = raw.split(separator: "\n").dropFirst() // Skip header

        for line in lines {
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count >= 6 else { continue }

            let filesystem = parts[0]
            // Skip virtual filesystems
            guard !filesystem.hasPrefix("tmpfs"),
                  !filesystem.hasPrefix("devtmpfs"),
                  !filesystem.hasPrefix("udev"),
                  !filesystem.hasPrefix("overlay"),
                  !filesystem.hasPrefix("shm") else { continue }

            let totalBlocks = UInt64(parts[1]) ?? 0
            let usedBlocks = UInt64(parts[2]) ?? 0
            let availableBlocks = UInt64(parts[3]) ?? 0
            let mountPoint = parts[5]

            // df -P reports in 1K blocks
            entries.append(DiskUsageEntry(
                device: filesystem,
                mountPoint: mountPoint,
                totalBytes: totalBlocks * 1024,
                usedBytes: usedBlocks * 1024,
                availableBytes: availableBlocks * 1024
            ))
        }

        return entries
    }

    struct DiskUsageEntry: Sendable {
        let device: String
        let mountPoint: String
        let totalBytes: UInt64
        let usedBytes: UInt64
        let availableBytes: UInt64
    }
}
