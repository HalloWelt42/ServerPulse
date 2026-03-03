import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable {
    case servers = "servers"
    case containers = "containers"
    case terminal = "terminal"
    case snippets = "snippets"
    case execute = "execute"
    case keychain = "keychain"
    case settings = "settings"
    case donate = "donate"
    case guide = "guide"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .servers: return "server.rack"
        case .containers: return "shippingbox.fill"
        case .terminal: return "terminal.fill"
        case .snippets: return "chevron.left.forwardslash.chevron.right"
        case .execute: return "play.circle.fill"
        case .keychain: return "key.fill"
        case .settings: return "gearshape.fill"
        case .donate: return "heart.fill"
        case .guide: return "book.fill"
        }
    }

    @MainActor func displayName(_ loc: LocalizationManager) -> String {
        loc["sidebar.\(rawValue)"]
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @Environment(TerminalSessionManager.self) private var terminalManager
    @Environment(LocalizationManager.self) private var loc

    var body: some View {
        List(selection: $selection) {
            Section(loc["sidebar.section.monitor"]) {
                ForEach([SidebarSection.servers, .containers]) { section in
                    Label(section.displayName(loc), systemImage: section.icon)
                        .tag(section)
                }
            }

            Section(loc["sidebar.section.tools"]) {
                ForEach([SidebarSection.terminal, .snippets, .execute]) { section in
                    Label(section.displayName(loc), systemImage: section.icon)
                        .tag(section)
                }
            }

            if !terminalManager.activeSessions.isEmpty {
                Section(loc.string("sidebar.section.sessions", terminalManager.activeSessions.count)) {
                    ForEach(terminalManager.activeSessions) { session in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(session.isConnected ? AppTheme.statusOnline : AppTheme.statusOffline)
                                .frame(width: 6, height: 6)
                            Text(session.title)
                                .font(.system(size: AppTheme.scaled(12)))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }

            Section {
                ForEach([SidebarSection.keychain, .settings]) { section in
                    Label(section.displayName(loc), systemImage: section.icon)
                        .tag(section)
                }
            }

            Section(loc["sidebar.section.more"]) {
                Label(SidebarSection.guide.displayName(loc), systemImage: SidebarSection.guide.icon)
                    .tag(SidebarSection.guide)

                // Donate entry: highlighted with red heart
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color(red: 0.9, green: 0.15, blue: 0.2))
                        .font(.system(size: 12))
                    Text(SidebarSection.donate.displayName(loc))
                        .foregroundStyle(Color(red: 0.9, green: 0.15, blue: 0.2))
                        .fontWeight(.semibold)
                }
                .tag(SidebarSection.donate)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
    }
}
