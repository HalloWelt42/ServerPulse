import Foundation

struct PsAuxParser {
    static func parse(_ raw: String) -> [RemoteProcess] {
        var processes: [RemoteProcess] = []
        let lines = raw.split(separator: "\n").dropFirst() // Skip header

        for line in lines {
            let parts = line.split(maxSplits: 10, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count >= 11 else { continue }

            let pid = Int(parts[1]) ?? 0
            let cpuPercent = Double(parts[2]) ?? 0
            let memPercent = Double(parts[3]) ?? 0
            let vsz = UInt64(parts[4]) ?? 0
            let rss = UInt64(parts[5]) ?? 0

            processes.append(RemoteProcess(
                id: pid,
                user: parts[0],
                cpuPercent: cpuPercent,
                memPercent: memPercent,
                vsz: vsz * 1024, // KB to bytes
                rss: rss * 1024,
                tty: parts[6],
                state: parts[7],
                startTime: parts[8],
                command: parts[10]
            ))
        }

        return processes
    }
}
