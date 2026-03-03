import SwiftUI
import SwiftData

@main
struct ServerPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var connectionManager = SSHConnectionManager()
    @State private var metricsEngine: MetricsEngine
    @State private var dockerService = DockerService()
    @State private var terminalManager = TerminalSessionManager()
    @State private var localization = LocalizationManager.shared
    @State private var themeManager = ThemeManager.shared

    init() {
        let cm = SSHConnectionManager()
        _connectionManager = State(initialValue: cm)
        _metricsEngine = State(initialValue: MetricsEngine(connectionManager: cm))
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environment(connectionManager)
                .environment(metricsEngine)
                .environment(dockerService)
                .environment(terminalManager)
                .environment(localization)
                .environment(themeManager)
                .modelContainer(DataController.shared.container)
                .preferredColorScheme(.dark)
                .frame(minWidth: 720, minHeight: 480)
        }
        .defaultSize(width: 1200, height: 800)

        Settings {
            SettingsView()
                .environment(localization)
                .environment(themeManager)
                .modelContainer(DataController.shared.container)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.appearance = NSAppearance(named: .darkAqua)

        DispatchQueue.main.async {
            self.ensureEditMenu()
        }
    }

    private func ensureEditMenu() {
        let loc = LocalizationManager.shared
        guard let mainMenu = NSApp.mainMenu else { return }

        let hasEditMenu = mainMenu.items.contains { $0.submenu?.title == "Edit" || $0.submenu?.title == "Bearbeiten" }
        if hasEditMenu { return }

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: loc["menu.edit"])
        editMenu.addItem(withTitle: loc["menu.undo"], action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: loc["menu.redo"], action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: loc["menu.cut"], action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: loc["menu.copy"], action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: loc["menu.paste"], action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: loc["menu.select_all"], action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu

        if mainMenu.items.count > 0 {
            mainMenu.insertItem(editMenuItem, at: 1)
        } else {
            mainMenu.addItem(editMenuItem)
        }
    }
}
