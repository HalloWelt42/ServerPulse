import Foundation

enum AppVersion {
    static let current = "1.0.2"
    static let copyright = "© 2025 HalloWelt42"

    /// Formatted display string, e.g. "ServerPulse v1.0.1"
    static var displayString: String {
        "ServerPulse v\(current)"
    }

    /// Full footer line, e.g. "ServerPulse v1.0.1 · © 2025 HalloWelt42"
    static var footerString: String {
        "\(displayString) · \(copyright)"
    }
}
