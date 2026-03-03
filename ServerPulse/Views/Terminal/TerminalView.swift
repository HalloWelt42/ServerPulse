import SwiftUI
import SwiftData
import SwiftTerm

struct TerminalView: View {
    @Environment(SSHConnectionManager.self) private var connectionManager
    @Environment(TerminalSessionManager.self) private var terminalManager
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var showServerPicker = false

    var body: some View {
        VStack(spacing: 0) {
            if terminalManager.activeSessions.isEmpty {
                emptyState
            } else {
                tabBar
                terminalToolbar
                terminalContent
            }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showServerPicker) {
            serverPickerSheet
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "terminal.fill")
                .font(.system(size: AppTheme.scaled(48)))
                .foregroundStyle(AppTheme.textTertiary)
            Text(loc["terminal.empty.title"])
                .font(.system(size: AppTheme.scaled(18), weight: .semibold))
                .foregroundStyle(AppTheme.textMuted)
            Text(loc["terminal.empty.subtitle"])
                .font(.system(size: AppTheme.scaled(13)))
                .foregroundStyle(AppTheme.textTertiary)
            Button(loc["terminal.empty.new"]) {
                showServerPicker = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.buttonPrimary)
            .handCursorOnHover()
            Spacer()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(terminalManager.activeSessions) { session in
                TerminalTab(
                    title: session.serverName,
                    isActive: session.id == terminalManager.selectedSessionId,
                    isConnected: session.isConnected,
                    onSelect: { terminalManager.selectedSessionId = session.id },
                    onClose: { Task { await terminalManager.closeSession(id: session.id) } }
                )
            }

            Button {
                showServerPicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: AppTheme.scaled(14)))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .handCursorOnHover()

            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(AppTheme.surfaceSecondary)
        .overlay(alignment: .bottom) {
            Divider().background(AppTheme.border)
        }
    }

    // MARK: - Terminal Toolbar

    @ViewBuilder
    private var terminalToolbar: some View {
        if let session = terminalManager.selectedSession {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(session.isConnected ? AppTheme.statusOnline : AppTheme.statusOffline)
                        .frame(width: 6, height: 6)
                    Text(loc["terminal.connected_to"] + " ")
                        .foregroundStyle(AppTheme.textMuted) +
                    Text(session.serverName)
                        .foregroundStyle(AppTheme.textPrimary)
                        .bold()
                }
                .font(.system(size: AppTheme.scaled(12)))
                .lineLimit(1)

                Spacer()

                Button(loc["terminal.disconnect"]) {
                    Task { await terminalManager.closeSession(id: session.id) }
                }
                .foregroundStyle(AppTheme.textSecondary)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .handCursorOnHover()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.13, green: 0.13, blue: 0.13))
            .overlay(alignment: .bottom) {
                Divider().background(AppTheme.border)
            }
        }
    }

    // MARK: - Terminal Content

    @ViewBuilder
    private var terminalContent: some View {
        if let session = terminalManager.selectedSession {
            SSHTerminalView(session: session.session, server: servers.first { $0.id == session.serverId })
                .id(session.id)
        } else {
            Color(red: 0.05, green: 0.05, blue: 0.05)
        }
    }

    // MARK: - Server Picker

    private var serverPickerSheet: some View {
        VStack(spacing: 16) {
            Text(loc["terminal.picker.title"])
                .font(.headline)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.top)

            let connectedServers = servers.filter { connectionManager.isConnected(serverId: $0.id) }

            if connectedServers.isEmpty {
                Text(loc["terminal.picker.empty"])
                    .foregroundStyle(AppTheme.textMuted)
                    .padding()
            } else {
                List(connectedServers) { server in
                    Button {
                        showServerPicker = false
                        Task {
                            try? await terminalManager.openSession(
                                for: server,
                                connectionManager: connectionManager
                            )
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(server.name)
                                    .fontWeight(.medium)
                                Text("\(server.username)@\(server.hostname)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "terminal")
                                .foregroundStyle(AppTheme.buttonPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                    .handCursorOnHover()
                }
            }

            Button(loc["terminal.picker.cancel"]) { showServerPicker = false }
                .buttonStyle(.bordered)
                .handCursorOnHover()
                .padding(.bottom)
        }
        .frame(width: 350, height: 300)
    }
}

// MARK: - Tab

private struct TerminalTab: View {
    let title: String
    let isActive: Bool
    let isConnected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? AppTheme.statusOnline : AppTheme.statusOffline)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: AppTheme.scaled(12), weight: .medium))
                .foregroundStyle(isActive ? AppTheme.textPrimary : AppTheme.textMuted)
                .lineLimit(1)
                .truncationMode(.tail)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: AppTheme.scaled(8), weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .handCursorOnHover()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(isActive ? AppTheme.surfacePrimary : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture(perform: onSelect)
        .handCursorOnHover()
    }
}

// MARK: - SwiftTerm NSView Wrapper

struct SSHTerminalView: NSViewRepresentable {
    let session: SSHSession
    let server: Server?

    @AppStorage("terminalFontName") private var fontName: String = "SF Mono"
    @AppStorage("terminalFontSize") private var fontSize: Double = 13
    @AppStorage("terminalFontBold") private var fontBold: Bool = false

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let termView = LocalProcessTerminalView(frame: .zero)
        termView.configureNativeColors()

        let weight: NSFont.Weight = fontBold ? .bold : .regular
        let resolvedFont = resolveFont(name: fontName, size: CGFloat(fontSize), weight: weight)
        termView.font = resolvedFont
        termView.nativeForegroundColor = .init(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        termView.nativeBackgroundColor = .init(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)

        // Start local shell for now - SSH channel integration would require
        // SwiftTerm's SshTerminalView with Citadel channel bridging
        termView.startProcess()

        // Send SSH command to connect to the server
        if let server = server {
            let sshCommand = "ssh \(server.username)@\(server.hostname) -p \(server.port)\n"
            termView.send(txt: sshCommand)
        }

        return termView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Update font when settings change
        let weight: NSFont.Weight = fontBold ? .bold : .regular
        let resolvedFont = resolveFont(name: fontName, size: CGFloat(fontSize), weight: weight)
        nsView.font = resolvedFont
    }

    private func resolveFont(name: String, size: CGFloat, weight: NSFont.Weight) -> NSFont {
        // Try exact name
        if let f = NSFont(name: name, size: size) {
            return weight == .bold ? NSFontManager.shared.convert(f, toHaveTrait: .boldFontMask) : f
        }
        // Try dashed name
        let dashed = name.replacingOccurrences(of: " ", with: "-")
        if let f = NSFont(name: dashed, size: size) {
            return weight == .bold ? NSFontManager.shared.convert(f, toHaveTrait: .boldFontMask) : f
        }
        // Fallback to system monospaced
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
}
