import SwiftUI

struct MainContentView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedSection: SidebarSection? = .servers
    @Environment(TerminalSessionManager.self) private var terminalManager
    @AppStorage("appLaunchCount") private var appLaunchCount: Int = 0

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(.dark)
        .onChange(of: terminalManager.shouldNavigateToTerminal) { _, shouldNav in
            if shouldNav {
                selectedSection = .terminal
                terminalManager.shouldNavigateToTerminal = false
            }
        }
        .onAppear {
            checkRandomDonationNavigation()
        }
    }

    /// Randomly navigate to the donation page approximately every 100 starts
    private func checkRandomDonationNavigation() {
        appLaunchCount += 1
        let randomChance = Int.random(in: 1...100)
        if randomChance == 1 {
            // ~1% chance each launch → on average every 100 starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                selectedSection = .donate
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .servers:
            ServersDashboardView()
        case .containers:
            ContainersDashboardView()
        case .terminal:
            TerminalView()
        case .snippets:
            SnippetsView()
        case .execute:
            ExecuteView()
        case .keychain:
            KeychainView()
        case .settings:
            SettingsView()
        case .donate:
            DonationView()
        case .guide:
            GuideView()
        case .none:
            ServersDashboardView()
        }
    }
}
