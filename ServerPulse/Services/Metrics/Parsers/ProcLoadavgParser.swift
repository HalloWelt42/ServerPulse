import Foundation

struct ProcLoadavgParser {
    static func parse(_ raw: String) -> LoadAverage {
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ").map(String.init)
        guard parts.count >= 3 else { return .zero }

        return LoadAverage(
            oneMinute: Double(parts[0]) ?? 0,
            fiveMinute: Double(parts[1]) ?? 0,
            fifteenMinute: Double(parts[2]) ?? 0
        )
    }
}
