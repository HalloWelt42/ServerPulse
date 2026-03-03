import Foundation

struct ProcMeminfoParser {
    static func parse(_ raw: String) -> MemoryMetrics {
        var values: [String: UInt64] = [:]
        for line in raw.split(separator: "\n") {
            let parts = line.split(separator: ":")
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let numStr = parts[1].trimmingCharacters(in: .whitespaces)
                .split(separator: " ").first.map(String.init) ?? "0"
            if let val = UInt64(numStr) {
                values[key] = val * 1024 // kB to bytes
            }
        }

        let total = values["MemTotal"] ?? 0
        let free = values["MemFree"] ?? 0
        let available = values["MemAvailable"] ?? free
        let buffers = values["Buffers"] ?? 0
        let cached = values["Cached"] ?? 0
        let swapTotal = values["SwapTotal"] ?? 0
        let swapFree = values["SwapFree"] ?? 0

        // usedBytes = actual app usage (excludes buffers/cache that can be reclaimed)
        let appUsed: UInt64
        if total > free + buffers + cached {
            appUsed = total - free - buffers - cached
        } else {
            appUsed = total > available ? total - available : 0
        }

        return MemoryMetrics(
            totalBytes: total,
            usedBytes: appUsed,
            freeBytes: free,
            availableBytes: available,
            buffersBytes: buffers,
            cachedBytes: cached,
            swapTotalBytes: swapTotal,
            swapUsedBytes: swapTotal - swapFree,
            swapFreeBytes: swapFree
        )
    }
}
