import SwiftUI

// MARK: - Theme Color Definition

struct ThemeColors: Equatable, Identifiable {
    let id: String
    let displayName: String
    let nativeName: String

    // Surfaces
    let background: Color
    let surfacePrimary: Color
    let surfaceSecondary: Color
    let border: Color
    let borderLight: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textMuted: Color

    // Status
    let statusOnline: Color
    let statusOffline: Color
    let statusWarning: Color

    // Semantic (gauges & indicators)
    let cpuColor: Color
    let memoryColor: Color
    let swapColor: Color
    let networkRxColor: Color
    let networkTxColor: Color
    let diskColor: Color
    let buffersColor: Color
    let cachedColor: Color

    // Buttons
    let buttonPrimary: Color
    let buttonPrimaryHover: Color
    let buttonSecondary: Color
    let buttonSecondaryHover: Color
    let buttonDanger: Color
    let buttonDangerHover: Color
    let buttonDangerBg: Color
    let infoColor: Color
}

// MARK: - Built-in Theme Presets

extension ThemeColors {
    static let allPresets: [ThemeColors] = [materialDark, nord, dracula, catppuccinMocha, tokyoNight]

    // Material Design Dark (default)
    static let materialDark = ThemeColors(
        id: "materialDark",
        displayName: "Material Dark",
        nativeName: "Material Dark",
        background:        Color(red: 0.07, green: 0.07, blue: 0.07),         // #121212
        surfacePrimary:    Color(red: 0.12, green: 0.12, blue: 0.12),         // #1E1E1E
        surfaceSecondary:  Color(red: 0.09, green: 0.09, blue: 0.09),         // #171717
        border:            Color(red: 0.20, green: 0.20, blue: 0.20),         // #333333
        borderLight:       Color(red: 0.27, green: 0.27, blue: 0.27),         // #444444
        textPrimary:       Color(red: 0.93, green: 0.93, blue: 0.93),         // #EDEDED
        textSecondary:     Color(red: 0.70, green: 0.70, blue: 0.70),         // #B3B3B3
        textTertiary:      Color(red: 0.40, green: 0.40, blue: 0.40),         // #666666
        textMuted:         Color(red: 0.53, green: 0.53, blue: 0.53),         // #888888
        statusOnline:      Color(red: 0.30, green: 0.69, blue: 0.31),         // #4CAF50
        statusOffline:     Color(red: 0.94, green: 0.33, blue: 0.31),         // #EF5350
        statusWarning:     Color(red: 1.00, green: 0.65, blue: 0.15),         // #FFA726
        cpuColor:          Color(red: 0.30, green: 0.69, blue: 0.31),         // #4CAF50
        memoryColor:       Color(red: 0.94, green: 0.33, blue: 0.31),         // #EF5350
        swapColor:         Color(red: 1.00, green: 0.65, blue: 0.15),         // #FFA726
        networkRxColor:    Color(red: 0.30, green: 0.69, blue: 0.31),         // #4CAF50
        networkTxColor:    Color(red: 0.12, green: 0.53, blue: 0.90),         // #1E88E5
        diskColor:         Color(red: 1.00, green: 0.65, blue: 0.15),         // #FFA726
        buffersColor:      Color(red: 1.00, green: 0.65, blue: 0.15),         // #FFA726
        cachedColor:       Color(red: 0.12, green: 0.53, blue: 0.90),         // #1E88E5
        buttonPrimary:     Color(red: 0.10, green: 0.46, blue: 0.82),         // #1976D2
        buttonPrimaryHover:Color(red: 0.12, green: 0.53, blue: 0.90),         // #1E88E5
        buttonSecondary:   Color(red: 0.33, green: 0.33, blue: 0.37),         // #54545E
        buttonSecondaryHover: Color(red: 0.42, green: 0.42, blue: 0.46),      // #6B6B75
        buttonDanger:      Color(red: 0.94, green: 0.33, blue: 0.31),         // #EF5350
        buttonDangerHover: Color(red: 0.90, green: 0.22, blue: 0.21),         // #E53935
        buttonDangerBg:    Color(red: 0.94, green: 0.33, blue: 0.31).opacity(0.12),
        infoColor:         Color(red: 0.10, green: 0.46, blue: 0.82)          // #1976D2
    )

    // Nord
    static let nord = ThemeColors(
        id: "nord",
        displayName: "Nord",
        nativeName: "Nord",
        background:        Color(red: 0.18, green: 0.20, blue: 0.25),         // #2E3440
        surfacePrimary:    Color(red: 0.23, green: 0.26, blue: 0.32),         // #3B4252
        surfaceSecondary:  Color(red: 0.20, green: 0.23, blue: 0.28),         // #343A48
        border:            Color(red: 0.30, green: 0.34, blue: 0.42),         // #4C566A
        borderLight:       Color(red: 0.37, green: 0.40, blue: 0.47),         // #5E6779
        textPrimary:       Color(red: 0.93, green: 0.94, blue: 0.96),         // #ECEFF4
        textSecondary:     Color(red: 0.85, green: 0.87, blue: 0.91),         // #D8DEE9
        textTertiary:      Color(red: 0.51, green: 0.58, blue: 0.68),         // #8293AD
        textMuted:         Color(red: 0.60, green: 0.67, blue: 0.76),         // #99ABC2
        statusOnline:      Color(red: 0.64, green: 0.75, blue: 0.55),         // #A3BE8C
        statusOffline:     Color(red: 0.75, green: 0.38, blue: 0.42),         // #BF616A
        statusWarning:     Color(red: 0.82, green: 0.53, blue: 0.44),         // #D08770
        cpuColor:          Color(red: 0.64, green: 0.75, blue: 0.55),         // #A3BE8C
        memoryColor:       Color(red: 0.75, green: 0.38, blue: 0.42),         // #BF616A
        swapColor:         Color(red: 0.82, green: 0.53, blue: 0.44),         // #D08770
        networkRxColor:    Color(red: 0.64, green: 0.75, blue: 0.55),         // #A3BE8C
        networkTxColor:    Color(red: 0.51, green: 0.63, blue: 0.76),         // #81A1C1
        diskColor:         Color(red: 0.82, green: 0.53, blue: 0.44),         // #D08770
        buffersColor:      Color(red: 0.82, green: 0.53, blue: 0.44),         // #D08770
        cachedColor:       Color(red: 0.51, green: 0.63, blue: 0.76),         // #81A1C1
        buttonPrimary:     Color(red: 0.37, green: 0.51, blue: 0.67),         // #5E81AC
        buttonPrimaryHover:Color(red: 0.51, green: 0.63, blue: 0.76),         // #81A1C1
        buttonSecondary:   Color(red: 0.30, green: 0.34, blue: 0.42),         // #4C566A
        buttonSecondaryHover: Color(red: 0.37, green: 0.40, blue: 0.47),      // #5E6779
        buttonDanger:      Color(red: 0.75, green: 0.38, blue: 0.42),         // #BF616A
        buttonDangerHover: Color(red: 0.65, green: 0.28, blue: 0.32),         // #A54751
        buttonDangerBg:    Color(red: 0.75, green: 0.38, blue: 0.42).opacity(0.12),
        infoColor:         Color(red: 0.37, green: 0.51, blue: 0.67)          // #5E81AC
    )

    // Dracula
    static let dracula = ThemeColors(
        id: "dracula",
        displayName: "Dracula",
        nativeName: "Dracula",
        background:        Color(red: 0.16, green: 0.16, blue: 0.21),         // #282A36
        surfacePrimary:    Color(red: 0.27, green: 0.28, blue: 0.35),         // #44475A
        surfaceSecondary:  Color(red: 0.21, green: 0.22, blue: 0.28),         // #363848
        border:            Color(red: 0.38, green: 0.45, blue: 0.64),         // #6272A4
        borderLight:       Color(red: 0.48, green: 0.55, blue: 0.74),         // #7A8CBD
        textPrimary:       Color(red: 0.97, green: 0.97, blue: 0.95),         // #F8F8F2
        textSecondary:     Color(red: 0.75, green: 0.75, blue: 0.75),         // #BFBFBF
        textTertiary:      Color(red: 0.48, green: 0.55, blue: 0.74),         // #7A8CBD
        textMuted:         Color(red: 0.38, green: 0.45, blue: 0.64),         // #6272A4
        statusOnline:      Color(red: 0.31, green: 0.98, blue: 0.48),         // #50FA7B
        statusOffline:     Color(red: 1.00, green: 0.33, blue: 0.33),         // #FF5555
        statusWarning:     Color(red: 1.00, green: 0.72, blue: 0.42),         // #FFB86C
        cpuColor:          Color(red: 0.31, green: 0.98, blue: 0.48),         // #50FA7B
        memoryColor:       Color(red: 1.00, green: 0.33, blue: 0.33),         // #FF5555
        swapColor:         Color(red: 1.00, green: 0.72, blue: 0.42),         // #FFB86C
        networkRxColor:    Color(red: 0.31, green: 0.98, blue: 0.48),         // #50FA7B
        networkTxColor:    Color(red: 0.55, green: 0.91, blue: 0.99),         // #8BE9FD
        diskColor:         Color(red: 1.00, green: 0.72, blue: 0.42),         // #FFB86C
        buffersColor:      Color(red: 1.00, green: 0.72, blue: 0.42),         // #FFB86C
        cachedColor:       Color(red: 0.55, green: 0.91, blue: 0.99),         // #8BE9FD
        buttonPrimary:     Color(red: 0.74, green: 0.58, blue: 0.98),         // #BD93F9
        buttonPrimaryHover:Color(red: 1.00, green: 0.47, blue: 0.78),         // #FF79C6
        buttonSecondary:   Color(red: 0.38, green: 0.45, blue: 0.64),         // #6272A4
        buttonSecondaryHover: Color(red: 0.48, green: 0.55, blue: 0.74),      // #7A8CBD
        buttonDanger:      Color(red: 1.00, green: 0.33, blue: 0.33),         // #FF5555
        buttonDangerHover: Color(red: 0.90, green: 0.23, blue: 0.23),         // #E63B3B
        buttonDangerBg:    Color(red: 1.00, green: 0.33, blue: 0.33).opacity(0.12),
        infoColor:         Color(red: 0.55, green: 0.91, blue: 0.99)          // #8BE9FD
    )

    // Catppuccin Mocha
    static let catppuccinMocha = ThemeColors(
        id: "catppuccinMocha",
        displayName: "Catppuccin Mocha",
        nativeName: "Catppuccin Mocha",
        background:        Color(red: 0.12, green: 0.12, blue: 0.18),         // #1E1E2E
        surfacePrimary:    Color(red: 0.18, green: 0.18, blue: 0.25),         // #302D41 Surface0
        surfaceSecondary:  Color(red: 0.15, green: 0.15, blue: 0.21),         // #262637
        border:            Color(red: 0.27, green: 0.27, blue: 0.35),         // #45475A Surface1
        borderLight:       Color(red: 0.35, green: 0.35, blue: 0.44),         // #585B70 Surface2
        textPrimary:       Color(red: 0.80, green: 0.84, blue: 0.96),         // #CDD6F4 Text
        textSecondary:     Color(red: 0.70, green: 0.74, blue: 0.86),         // #BAC2DE Subtext1
        textTertiary:      Color(red: 0.42, green: 0.44, blue: 0.55),         // #6C7086 Overlay0
        textMuted:         Color(red: 0.57, green: 0.60, blue: 0.71),         // #9399B2 Overlay2
        statusOnline:      Color(red: 0.65, green: 0.89, blue: 0.63),         // #A6E3A1 Green
        statusOffline:     Color(red: 0.95, green: 0.55, blue: 0.55),         // #F38BA8 Red
        statusWarning:     Color(red: 0.98, green: 0.74, blue: 0.48),         // #FAB387 Peach
        cpuColor:          Color(red: 0.65, green: 0.89, blue: 0.63),         // #A6E3A1 Green
        memoryColor:       Color(red: 0.95, green: 0.55, blue: 0.55),         // #F38BA8 Red
        swapColor:         Color(red: 0.98, green: 0.74, blue: 0.48),         // #FAB387 Peach
        networkRxColor:    Color(red: 0.65, green: 0.89, blue: 0.63),         // #A6E3A1 Green
        networkTxColor:    Color(red: 0.54, green: 0.80, blue: 0.98),         // #89B4FA Blue
        diskColor:         Color(red: 0.98, green: 0.74, blue: 0.48),         // #FAB387 Peach
        buffersColor:      Color(red: 0.98, green: 0.74, blue: 0.48),         // #FAB387 Peach
        cachedColor:       Color(red: 0.54, green: 0.80, blue: 0.98),         // #89B4FA Blue
        buttonPrimary:     Color(red: 0.54, green: 0.80, blue: 0.98),         // #89B4FA Blue
        buttonPrimaryHover:Color(red: 0.45, green: 0.71, blue: 0.96),         // #74C7EC Sapphire
        buttonSecondary:   Color(red: 0.27, green: 0.27, blue: 0.35),         // #45475A Surface1
        buttonSecondaryHover: Color(red: 0.35, green: 0.35, blue: 0.44),      // #585B70 Surface2
        buttonDanger:      Color(red: 0.95, green: 0.55, blue: 0.55),         // #F38BA8 Red
        buttonDangerHover: Color(red: 0.92, green: 0.40, blue: 0.45),         // #EB6F7A
        buttonDangerBg:    Color(red: 0.95, green: 0.55, blue: 0.55).opacity(0.12),
        infoColor:         Color(red: 0.54, green: 0.80, blue: 0.98)          // #89B4FA Blue
    )

    // Tokyo Night
    static let tokyoNight = ThemeColors(
        id: "tokyoNight",
        displayName: "Tokyo Night",
        nativeName: "Tokyo Night",
        background:        Color(red: 0.10, green: 0.11, blue: 0.17),         // #1A1B2C
        surfacePrimary:    Color(red: 0.15, green: 0.16, blue: 0.24),         // #24283B
        surfaceSecondary:  Color(red: 0.12, green: 0.13, blue: 0.20),         // #1F2133
        border:            Color(red: 0.22, green: 0.24, blue: 0.36),         // #3B3D5C
        borderLight:       Color(red: 0.30, green: 0.32, blue: 0.45),         // #4D5173
        textPrimary:       Color(red: 0.66, green: 0.71, blue: 0.93),         // #A9B1EC
        textSecondary:     Color(red: 0.53, green: 0.58, blue: 0.80),         // #8790CC
        textTertiary:      Color(red: 0.33, green: 0.37, blue: 0.55),         // #545E8C
        textMuted:         Color(red: 0.42, green: 0.47, blue: 0.67),         // #6B78AB
        statusOnline:      Color(red: 0.58, green: 0.84, blue: 0.64),         // #9ECE6A
        statusOffline:     Color(red: 0.96, green: 0.44, blue: 0.52),         // #F7708A
        statusWarning:     Color(red: 0.88, green: 0.65, blue: 0.32),         // #E0A652
        cpuColor:          Color(red: 0.58, green: 0.84, blue: 0.64),         // #9ECE6A
        memoryColor:       Color(red: 0.96, green: 0.44, blue: 0.52),         // #F7708A
        swapColor:         Color(red: 0.88, green: 0.65, blue: 0.32),         // #E0A652
        networkRxColor:    Color(red: 0.58, green: 0.84, blue: 0.64),         // #9ECE6A
        networkTxColor:    Color(red: 0.49, green: 0.65, blue: 0.95),         // #7AA2F7 Blue
        diskColor:         Color(red: 0.88, green: 0.65, blue: 0.32),         // #E0A652
        buffersColor:      Color(red: 0.88, green: 0.65, blue: 0.32),         // #E0A652
        cachedColor:       Color(red: 0.49, green: 0.65, blue: 0.95),         // #7AA2F7 Blue
        buttonPrimary:     Color(red: 0.49, green: 0.65, blue: 0.95),         // #7AA2F7 Blue
        buttonPrimaryHover:Color(red: 0.55, green: 0.73, blue: 0.98),         // #8CB9FA
        buttonSecondary:   Color(red: 0.22, green: 0.24, blue: 0.36),         // #3B3D5C
        buttonSecondaryHover: Color(red: 0.30, green: 0.32, blue: 0.45),      // #4D5173
        buttonDanger:      Color(red: 0.96, green: 0.44, blue: 0.52),         // #F7708A
        buttonDangerHover: Color(red: 0.90, green: 0.32, blue: 0.42),         // #E6526B
        buttonDangerBg:    Color(red: 0.96, green: 0.44, blue: 0.52).opacity(0.12),
        infoColor:         Color(red: 0.49, green: 0.65, blue: 0.95)          // #7AA2F7 Blue
    )

    static func preset(named name: String) -> ThemeColors {
        allPresets.first { $0.id == name } ?? .materialDark
    }
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private(set) var colors: ThemeColors

    @ObservationIgnored
    private var _selectedThemeId: String {
        didSet { UserDefaults.standard.set(_selectedThemeId, forKey: "selectedTheme") }
    }

    var selectedThemeId: String {
        get { _selectedThemeId }
        set {
            _selectedThemeId = newValue
            colors = ThemeColors.preset(named: newValue)
        }
    }

    var availableThemes: [ThemeColors] { ThemeColors.allPresets }

    init() {
        let saved = UserDefaults.standard.string(forKey: "selectedTheme") ?? "materialDark"
        self._selectedThemeId = saved
        self.colors = ThemeColors.preset(named: saved)
    }

    // MARK: - Direct Color Access (convenience)

    var background: Color { colors.background }
    var surfacePrimary: Color { colors.surfacePrimary }
    var surfaceSecondary: Color { colors.surfaceSecondary }
    var border: Color { colors.border }
    var borderLight: Color { colors.borderLight }

    var textPrimary: Color { colors.textPrimary }
    var textSecondary: Color { colors.textSecondary }
    var textTertiary: Color { colors.textTertiary }
    var textMuted: Color { colors.textMuted }

    var statusOnline: Color { colors.statusOnline }
    var statusOffline: Color { colors.statusOffline }
    var statusWarning: Color { colors.statusWarning }

    var cpuColor: Color { colors.cpuColor }
    var memoryColor: Color { colors.memoryColor }
    var swapColor: Color { colors.swapColor }
    var networkRxColor: Color { colors.networkRxColor }
    var networkTxColor: Color { colors.networkTxColor }
    var diskColor: Color { colors.diskColor }
    var buffersColor: Color { colors.buffersColor }
    var cachedColor: Color { colors.cachedColor }

    var buttonPrimary: Color { colors.buttonPrimary }
    var buttonPrimaryHover: Color { colors.buttonPrimaryHover }
    var buttonSecondary: Color { colors.buttonSecondary }
    var buttonSecondaryHover: Color { colors.buttonSecondaryHover }
    var buttonDanger: Color { colors.buttonDanger }
    var buttonDangerHover: Color { colors.buttonDangerHover }
    var buttonDangerBg: Color { colors.buttonDangerBg }
    var infoColor: Color { colors.infoColor }

    // Legacy alias
    var accent: Color { buttonPrimary }

    // MARK: - Dynamic Colors

    func utilizationColor(_ value: Double) -> Color {
        if value >= 0.8 { return statusOffline }
        if value >= 0.5 { return statusWarning }
        return statusOnline
    }

    func activityUploadColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusOnline : textTertiary
    }

    func activityDownloadColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusOffline : textTertiary
    }

    func activityReadColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusOnline : textTertiary
    }

    func activityWriteColor(_ bytesPerSec: Double) -> Color {
        bytesPerSec > 0 ? statusWarning : textTertiary
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

    var uiScale: CGFloat {
        CGFloat(UserDefaults.standard.double(forKey: "uiScale").clamped(to: 0.8...1.5, default: 1.0))
    }

    func scaled(_ base: CGFloat) -> CGFloat {
        base * uiScale
    }
}

// MARK: - Double Clamping Helper

private extension Double {
    func clamped(to range: ClosedRange<Double>, default fallback: Double) -> Double {
        self == 0 ? fallback : min(max(self, range.lowerBound), range.upperBound)
    }
}
