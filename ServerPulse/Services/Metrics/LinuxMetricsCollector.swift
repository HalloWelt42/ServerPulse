import Foundation

struct LinuxMetricsCollector {
    static let batchCommand = """
    echo '===PROCSTAT===' && cat /proc/stat && \
    echo '===MEMINFO===' && cat /proc/meminfo && \
    echo '===LOADAVG===' && cat /proc/loadavg && \
    echo '===NETDEV===' && cat /proc/net/dev && \
    echo '===DISKSTATS===' && cat /proc/diskstats && \
    echo '===DF===' && df -P && \
    echo '===UPTIME===' && cat /proc/uptime && \
    echo '===TEMP===' && (cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo 'N/A') && \
    echo '===END==='
    """

    struct PreviousState: Sendable {
        var cpuTicks: ProcStatParser.PreviousTicks?
        var netData: ProcNetDevParser.PreviousNetData?
        var diskData: ProcDiskstatsParser.PreviousDiskData?
    }

    static func collect(
        rawOutput: String,
        previous: PreviousState
    ) -> (ServerMetrics, PreviousState) {
        let sections = splitSections(rawOutput)

        // Parse CPU
        let (cpu, newCpuTicks) = ProcStatParser.parse(
            sections["PROCSTAT"] ?? "",
            previous: previous.cpuTicks
        )

        // Parse Memory
        let memory = ProcMeminfoParser.parse(sections["MEMINFO"] ?? "")

        // Parse Load Average
        let loadAvg = ProcLoadavgParser.parse(sections["LOADAVG"] ?? "")

        // Parse Network
        let (networks, newNetData) = ProcNetDevParser.parse(
            sections["NETDEV"] ?? "",
            previous: previous.netData
        )

        // Parse Disk I/O
        let (diskIO, newDiskData) = ProcDiskstatsParser.parse(
            sections["DISKSTATS"] ?? "",
            previous: previous.diskData
        )

        // Parse Disk Usage
        let diskUsage = DfParser.parse(sections["DF"] ?? "")

        // Parse Uptime
        let uptime = UptimeParser.parse(sections["UPTIME"] ?? "")

        // Parse Temperature
        let temperature = SensorsParser.parse(sections["TEMP"] ?? "")

        // Merge disk I/O with usage
        let disks = mergeDiskMetrics(usage: diskUsage, io: diskIO)

        let newState = PreviousState(
            cpuTicks: newCpuTicks,
            netData: newNetData,
            diskData: newDiskData
        )

        let metrics = ServerMetrics(
            timestamp: Date(),
            cpu: cpu,
            memory: memory,
            disks: disks,
            networks: networks,
            temperature: temperature,
            loadAverage: loadAvg,
            uptime: uptime,
            processes: []
        )

        return (metrics, newState)
    }

    private static func splitSections(_ output: String) -> [String: String] {
        var sections: [String: String] = [:]
        let markers = ["PROCSTAT", "MEMINFO", "LOADAVG", "NETDEV", "DISKSTATS", "DF", "UPTIME", "TEMP"]

        for i in 0..<markers.count {
            let start = "===\(markers[i])==="
            let end = i + 1 < markers.count ? "===\(markers[i + 1])===" : "===END==="
            if let startRange = output.range(of: start),
               let endRange = output.range(of: end) {
                let content = String(output[startRange.upperBound..<endRange.lowerBound])
                sections[markers[i]] = content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return sections
    }

    private static func mergeDiskMetrics(
        usage: [DfParser.DiskUsageEntry],
        io: [String: (readBps: Double, writeBps: Double, readIops: Double, writeIops: Double)]
    ) -> [DiskMetrics] {
        usage.map { entry in
            // Extract device basename (e.g., "/dev/sda1" -> "sda1")
            let deviceName = entry.device.split(separator: "/").last.map(String.init) ?? entry.device

            // Detect filesystem type from device name
            let fsType = detectFilesystemType(for: entry.mountPoint, device: entry.device)

            let ioData = io[deviceName] ?? (readBps: 0, writeBps: 0, readIops: 0, writeIops: 0)

            return DiskMetrics(
                id: deviceName,
                mountPoint: entry.mountPoint,
                filesystem: fsType,
                totalBytes: entry.totalBytes,
                usedBytes: entry.usedBytes,
                availableBytes: entry.availableBytes,
                readBytesPerSec: ioData.readBps,
                writeBytesPerSec: ioData.writeBps,
                iopsRead: ioData.readIops,
                iopsWrite: ioData.writeIops
            )
        }
    }

    private static func detectFilesystemType(for mountPoint: String, device: String) -> String {
        if device.contains("nvme") { return "EXT4" }
        if device.contains("mmcblk") { return "EXT4" }
        if mountPoint == "/boot" || mountPoint.contains("boot") { return "VFAT" }
        return "EXT4"
    }
}
