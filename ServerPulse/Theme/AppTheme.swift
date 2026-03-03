import SwiftUI

enum AppTheme {
    // MARK: - Material Design Dark Theme Colors

    // Surfaces (Material Design dark)
    static let background = Color(red: 0.07, green: 0.07, blue: 0.07)             // #121212
    static let surfacePrimary = Color(red: 0.12, green: 0.12, blue: 0.12)         // #1E1E1E
    static let surfaceSecondary = Color(red: 0.09, green: 0.09, blue: 0.09)       // #171717
    static let border = Color(red: 0.20, green: 0.20, blue: 0.20)                 // #333333
    static let borderLight = Color(red: 0.27, green: 0.27, blue: 0.27)            // #444444

    // Text (Material Design dark)
    static let textPrimary = Color(red: 0.93, green: 0.93, blue: 0.93)            // #EDEDED (87%)
    static let textSecondary = Color(red: 0.70, green: 0.70, blue: 0.70)          // #B3B3B3 (60%)
    static let textTertiary = Color(red: 0.40, green: 0.40, blue: 0.40)           // #666666
    static let textMuted = Color(red: 0.53, green: 0.53, blue: 0.53)              // #888888

    // MARK: - Material Design Status Colors
    static let statusOnline = Color(red: 0.30, green: 0.69, blue: 0.31)           // #4CAF50 Green 500
    static let statusOffline = Color(red: 0.94, green: 0.33, blue: 0.31)          // #EF5350 Red 400
    static let statusWarning = Color(red: 1.00, green: 0.65, blue: 0.15)          // #FFA726 Orange 400

    // MARK: - Material Design Semantic Colors (gauges & indicators)
    static let cpuColor = Color(red: 0.30, green: 0.69, blue: 0.31)              // #4CAF50 Green 500
    static let memoryColor = Color(red: 0.94, green: 0.33, blue: 0.31)           // #EF5350 Red 400
    static let swapColor = Color(red: 1.00, green: 0.65, blue: 0.15)             // #FFA726 Orange 400
    static let networkRxColor = Color(red: 0.30, green: 0.69, blue: 0.31)        // #4CAF50 Green 500
    static let networkTxColor = Color(red: 0.12, green: 0.53, blue: 0.90)        // #1E88E5 Blue 600
    static let diskColor = Color(red: 1.00, green: 0.65, blue: 0.15)             // #FFA726 Orange 400
    static let buffersColor = Color(red: 1.00, green: 0.65, blue: 0.15)          // #FFA726 Orange 400
    static let cachedColor = Color(red: 0.12, green: 0.53, blue: 0.90)           // #1E88E5 Blue 600

    // MARK: - Material Design Button Colors
    static let buttonPrimary = Color(red: 0.10, green: 0.46, blue: 0.82)         // #1976D2 Blue 700
    static let buttonPrimaryHover = Color(red: 0.12, green: 0.53, blue: 0.90)    // #1E88E5 Blue 600
    static let buttonSecondary = Color(red: 0.33, green: 0.33, blue: 0.37)       // #54545E neutral
    static let buttonSecondaryHover = Color(red: 0.42, green: 0.42, blue: 0.46)  // #6B6B75 lighter
    static let buttonDanger = Color(red: 0.94, green: 0.33, blue: 0.31)          // #EF5350 Red 400
    static let buttonDangerHover = Color(red: 0.90, green: 0.22, blue: 0.21)     // #E53935 Red 600
    static let buttonDangerBg = Color(red: 0.94, green: 0.33, blue: 0.31).opacity(0.12) // subtle red bg
    static let infoColor = Color(red: 0.10, green: 0.46, blue: 0.82)             // #1976D2 Blue 700

    // Legacy alias - kept for compatibility but should not be used in new code
    static let accent = buttonPrimary

    // MARK: - Dynamic Utilization Colors
    /// Returns a color based on utilization level: green (low) → orange (medium) → red (high)
    static func utilizationColor(_ value: Double) -> Color {
        if value >= 0.8 { return statusOffline }   // Red 400 — critical
        if value >= 0.5 { return statusWarning }    // Orange 400 — warning
        return statusOnline                         // Green 500 — healthy
    }

    /// Returns a color for network/disk activity: colored when active, neutral when idle
    static func activityUploadColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusOnline : textTertiary   // green when active
    }

    static func activityDownloadColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusOffline : textTertiary   // red when active
    }

    static func activityReadColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusOnline : textTertiary
    }

    static func activityWriteColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusWarning : textTertiary   // orange when writing
    }

    // MARK: - Fonts
    static let monoFont = Font.system(.body, design: .monospaced)
    static let monoSmall = Font.system(.caption, design: .monospaced)

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 8
    static let cardSpacing: CGFloat = 16

    // MARK: - UI Scale
    static var uiScale: CGFloat {
        CGFloat(UserDefaults.standard.double(forKey: "uiScale").clamped(to: 0.8...1.5, default: 1.0))
    }

    /// Scale a base font size by the global UI scale factor
    static func scaled(_ base: CGFloat) -> CGFloat {
        base * uiScale
    }
}

// MARK: - Double Clamping Helper
private extension Double {
    func clamped(to range: ClosedRange<Double>, default fallback: Double) -> Double {
        self == 0 ? fallback : min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Hand Cursor on Hover
extension View {
    /// Shows a pointing hand cursor when hovering, like web links
    func handCursorOnHover() -> some View {
        self.onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
