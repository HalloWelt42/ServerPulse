import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(ThemeManager.self) private var theme
    @AppStorage("defaultPollingInterval") private var defaultPollingInterval: Double = 5
    @AppStorage("defaultConnectionTimeout") private var defaultConnectionTimeout: Double = 10
    @AppStorage("defaultKeepAliveInterval") private var defaultKeepAliveInterval: Double = 30
    @AppStorage("showTemperatureInCard") private var showTemperatureInCard = true
    @AppStorage("autoConnectOnLaunch") private var autoConnectOnLaunch = true

    // UI Scale
    @AppStorage("uiScale") private var uiScale: Double = 1.0

    // Terminal Font
    @AppStorage("terminalFontName") private var terminalFontName: String = "SF Mono"
    @AppStorage("terminalFontSize") private var terminalFontSize: Double = 13
    @AppStorage("terminalFontBold") private var terminalFontBold: Bool = false

    private let terminalFonts = [
        "SF Mono", "Menlo", "Monaco", "Courier New",
        "Andale Mono", "Consolas", "JetBrains Mono",
        "Fira Code", "Source Code Pro", "IBM Plex Mono"
    ]

    var body: some View {
        Form {
            Section(loc["settings.section.language"]) {
                Picker(loc["settings.language"], selection: Binding(
                    get: { loc.currentLanguage },
                    set: { loc.setLanguage($0) }
                )) {
                    ForEach(loc.availableLanguages) { lang in
                        Text("\(lang.nativeName) (\(lang.displayName))").tag(lang.id)
                    }
                }
            }

            Section(loc["settings.section.general"]) {
                Toggle(loc["settings.auto_connect"], isOn: $autoConnectOnLaunch)
                Toggle(loc["settings.show_temp"], isOn: $showTemperatureInCard)
            }

            // MARK: - Appearance
            Section(loc["settings.section.appearance"]) {
                HStack {
                    Text(loc["settings.theme"])
                    Spacer()
                    Picker("", selection: Binding(
                        get: { theme.selectedThemeId },
                        set: { theme.selectedThemeId = $0 }
                    )) {
                        ForEach(theme.availableThemes) { preset in
                            Text(preset.displayName).tag(preset.id)
                        }
                    }
                    .frame(width: 180)
                }

                HStack {
                    Text(loc["settings.ui_scale"])
                    Spacer()
                    Picker("", selection: $uiScale) {
                        Text(loc["settings.scale.small"]).tag(0.85)
                        Text(loc["settings.scale.normal"]).tag(1.0)
                        Text(loc["settings.scale.large"]).tag(1.15)
                        Text(loc["settings.scale.xlarge"]).tag(1.3)
                    }
                    .frame(width: 150)
                }
            }

            // MARK: - Terminal
            Section(loc["settings.section.terminal"]) {
                HStack {
                    Text(loc["settings.terminal.font"])
                    Spacer()
                    Picker("", selection: $terminalFontName) {
                        ForEach(availableFonts, id: \.self) { name in
                            Text(name)
                                .font(.custom(name, size: 13))
                                .tag(name)
                        }
                    }
                    .frame(width: 180)
                }

                HStack {
                    Text(loc["settings.terminal.size"])
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            if terminalFontSize > 8 { terminalFontSize -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.bordered)
                        .handCursorOnHover()

                        Text("\(Int(terminalFontSize)) pt")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(theme.textPrimary)
                            .frame(width: 50)

                        Button {
                            if terminalFontSize < 28 { terminalFontSize += 1 }
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.bordered)
                        .handCursorOnHover()
                    }
                }

                Toggle(loc["settings.terminal.bold"], isOn: $terminalFontBold)

                // Preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc["settings.terminal.preview"])
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textTertiary)
                    Text("user@server:~ $ ls -la /var/log")
                        .font(.custom(resolvedFontName, size: terminalFontSize))
                        .fontWeight(terminalFontBold ? .bold : .regular)
                        .foregroundStyle(Color(red: 0.88, green: 0.88, blue: 0.88))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Section(loc["settings.section.connection"]) {
                HStack {
                    Text(loc["settings.polling"])
                    Spacer()
                    Picker("", selection: $defaultPollingInterval) {
                        Text(loc["settings.time.1s"]).tag(1.0)
                        Text(loc["settings.time.3s"]).tag(3.0)
                        Text(loc["settings.time.5s"]).tag(5.0)
                        Text(loc["settings.time.10s"]).tag(10.0)
                        Text(loc["settings.time.30s"]).tag(30.0)
                    }
                    .frame(width: 150)
                }

                HStack {
                    Text(loc["settings.timeout"])
                    Spacer()
                    Picker("", selection: $defaultConnectionTimeout) {
                        Text(loc["settings.time.5s"]).tag(5.0)
                        Text(loc["settings.time.10s"]).tag(10.0)
                        Text(loc["settings.time.15s"]).tag(15.0)
                        Text(loc["settings.time.30s"]).tag(30.0)
                    }
                    .frame(width: 150)
                }

                HStack {
                    Text(loc["settings.keepalive"])
                    Spacer()
                    Picker("", selection: $defaultKeepAliveInterval) {
                        Text(loc["settings.time.15s"]).tag(15.0)
                        Text(loc["settings.time.30s"]).tag(30.0)
                        Text(loc["settings.time.60s"]).tag(60.0)
                    }
                    .frame(width: 150)
                }
            }

            Section(loc["settings.section.about"]) {
                HStack {
                    Text("ServerPulse")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("v\(AppVersion.current)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(AppVersion.copyright)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.textTertiary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 450, maxWidth: 600)
        .navigationTitle(loc["settings.title"])
    }

    /// Filter to fonts that are actually installed on the system
    private var availableFonts: [String] {
        terminalFonts.filter { name in
            NSFont(name: name, size: 13) != nil ||
            NSFont(name: name.replacingOccurrences(of: " ", with: "-"), size: 13) != nil
        }
    }

    /// Resolve font name to one NSFont can find
    private var resolvedFontName: String {
        let name = terminalFontName
        if NSFont(name: name, size: 13) != nil { return name }
        let dashed = name.replacingOccurrences(of: " ", with: "-")
        if NSFont(name: dashed, size: 13) != nil { return dashed }
        return "Menlo" // fallback
    }
}
