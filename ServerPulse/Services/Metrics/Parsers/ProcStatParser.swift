import Foundation

struct ProcStatParser {
    struct PreviousTicks: Sendable {
        let total: CPURawTicks
        let perCore: [CPURawTicks]
    }

    static func parse(_ raw: String, previous: PreviousTicks?) -> (CPUMetrics, PreviousTicks) {
        let lines = raw.split(separator: "\n")
        var totalTicks: CPURawTicks?
        var coreTicks: [CPURawTicks] = []
        var cores: [CPUMetrics.CoreMetrics] = []

        for line in lines {
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count >= 8 else { continue }

            if parts[0] == "cpu" {
                totalTicks = parseTicks(parts)
            } else if parts[0].hasPrefix("cpu") {
                let coreIndex = Int(parts[0].dropFirst(3)) ?? coreTicks.count
                let ticks = parseTicks(parts)
                coreTicks.append(ticks)

                let prevCore = previous?.perCore.indices.contains(coreIndex) == true
                    ? previous?.perCore[coreIndex] : nil
                let usage = calculateUsage(current: ticks, previous: prevCore)

                cores.append(CPUMetrics.CoreMetrics(
                    id: coreIndex,
                    usage: usage.total,
                    user: usage.user,
                    system: usage.system,
                    idle: usage.idle
                ))
            }
        }

        let currentTicks = PreviousTicks(total: totalTicks ?? CPURawTicks(user: 0, nice: 0, system: 0, idle: 0, iowait: 0, irq: 0, softirq: 0, steal: 0), perCore: coreTicks)

        let usage = calculateUsage(current: totalTicks, previous: previous?.total)

        let metrics = CPUMetrics(
            totalUsage: usage.total,
            userUsage: usage.user,
            systemUsage: usage.system,
            ioWait: usage.iowait,
            idle: usage.idle,
            steal: usage.steal,
            perCore: cores
        )

        return (metrics, currentTicks)
    }

    private static func parseTicks(_ parts: [String]) -> CPURawTicks {
        let vals = parts.dropFirst().prefix(8).compactMap { UInt64($0) }
        return CPURawTicks(
            user: vals.count > 0 ? vals[0] : 0,
            nice: vals.count > 1 ? vals[1] : 0,
            system: vals.count > 2 ? vals[2] : 0,
            idle: vals.count > 3 ? vals[3] : 0,
            iowait: vals.count > 4 ? vals[4] : 0,
            irq: vals.count > 5 ? vals[5] : 0,
            softirq: vals.count > 6 ? vals[6] : 0,
            steal: vals.count > 7 ? vals[7] : 0
        )
    }

    private struct UsageResult {
        let total: Double
        let user: Double
        let system: Double
        let iowait: Double
        let idle: Double
        let steal: Double
    }

    private static func calculateUsage(current: CPURawTicks?, previous: CPURawTicks?) -> UsageResult {
        guard let current else { return UsageResult(total: 0, user: 0, system: 0, iowait: 0, idle: 1, steal: 0) }
        guard let previous else { return UsageResult(total: 0, user: 0, system: 0, iowait: 0, idle: 1, steal: 0) }

        let totalDelta = Double(current.total) - Double(previous.total)
        guard totalDelta > 0 else { return UsageResult(total: 0, user: 0, system: 0, iowait: 0, idle: 1, steal: 0) }

        let userDelta = Double(current.user + current.nice) - Double(previous.user + previous.nice)
        let systemDelta = Double(current.system + current.irq + current.softirq) - Double(previous.system + previous.irq + previous.softirq)
        let iowaitDelta = Double(current.iowait) - Double(previous.iowait)
        let idleDelta = Double(current.idle) - Double(previous.idle)
        let stealDelta = Double(current.steal) - Double(previous.steal)

        return UsageResult(
            total: 1.0 - (idleDelta / totalDelta),
            user: userDelta / totalDelta,
            system: systemDelta / totalDelta,
            iowait: iowaitDelta / totalDelta,
            idle: idleDelta / totalDelta,
            steal: stealDelta / totalDelta
        )
    }
}
