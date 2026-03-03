import Foundation

struct UptimeParser {
    static func parse(_ raw: String) -> TimeInterval {
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ").map(String.init)
        guard let first = parts.first else { return 0 }
        return Double(first) ?? 0
    }
}
