import Foundation

enum ByteFormatter {
    private static let units: [(String, Double)] = [
        ("B", 1),
        ("K", 1_024),
        ("M", 1_048_576),
        ("G", 1_073_741_824),
        ("T", 1_099_511_627_776),
    ]

    static func format(_ bytes: UInt64) -> String {
        format(Double(bytes))
    }

    static func format(_ bytes: Double) -> String {
        let absBytes = abs(bytes)
        for i in stride(from: units.count - 1, through: 0, by: -1) {
            if absBytes >= units[i].1 {
                let value = bytes / units[i].1
                if value >= 100 {
                    return String(format: "%.0f %@", value, units[i].0)
                } else if value >= 10 {
                    return String(format: "%.1f %@", value, units[i].0)
                } else {
                    return String(format: "%.1f %@", value, units[i].0)
                }
            }
        }
        return "0 B"
    }

    static func formatRate(_ bytesPerSec: Double) -> String {
        "\(format(bytesPerSec))/s"
    }

    static func formatShort(_ bytes: UInt64) -> String {
        let absBytes = Double(bytes)
        for i in stride(from: units.count - 1, through: 0, by: -1) {
            if absBytes >= units[i].1 {
                let value = absBytes / units[i].1
                if value >= 100 {
                    return "\(Int(value)) \(units[i].0)"
                }
                return String(format: "%.0f \(units[i].0)", value)
            }
        }
        return "0 B"
    }
}

enum TimeFormatter {
    static func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

}
