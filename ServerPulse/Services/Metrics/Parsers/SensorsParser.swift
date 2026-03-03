import Foundation

struct SensorsParser {
    static func parse(_ raw: String) -> TemperatureMetrics? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != "N/A", !trimmed.isEmpty else { return nil }

        var sensors: [TemperatureMetrics.TemperatureSensor] = []
        let lines = trimmed.split(separator: "\n")

        for (index, line) in lines.enumerated() {
            let value = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            if let millidegrees = Double(value) {
                let celsius = millidegrees / 1000.0
                sensors.append(TemperatureMetrics.TemperatureSensor(
                    id: "zone\(index)",
                    label: "Thermal Zone \(index)",
                    temperatureCelsius: celsius,
                    highThreshold: 80,
                    criticalThreshold: 90
                ))
            }
        }

        return sensors.isEmpty ? nil : TemperatureMetrics(sensors: sensors)
    }
}
