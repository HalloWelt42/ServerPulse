import SwiftUI
import SwiftData

struct ServersDashboardView: View {
    @Environment(SSHConnectionManager.self) private var connectionManager
    @Environment(MetricsEngine.self) private var metricsEngine
    @Environment(LocalizationManager.self) private var loc
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @AppStorage("autoConnectOnLaunch") private var autoConnectOnLaunch = true
    @State private var searchText = ""
    @State private var showAddServer = false
    @State private var navigationPath = NavigationPath()

    private var filteredServers: [Server] {
        if searchText.isEmpty { return servers }
        return servers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.hostname.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var connectedCount: Int {
        servers.filter { connectionManager.serverStates[$0.id] == .connected }.count
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc["dashboard.title"])
                            .font(.system(size: theme.scaled(22), weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)
                        if !servers.isEmpty {
                            Text(loc.string("dashboard.connected_count", connectedCount, servers.count))
                                .font(.system(size: theme.scaled(12), weight: .medium))
                                .foregroundStyle(theme.textMuted)
                                .lineLimit(1)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    Spacer()

                    HStack(spacing: 10) {
                        if !servers.isEmpty {
                            TextField(loc["dashboard.search"], text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 100, maxWidth: 180)
                        }

                        Button {
                            showAddServer = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.buttonPrimary)
                        .handCursorOnHover()
                    }
                }
                .padding(.horizontal, ThemeManager.paddingLarge)
                .padding(.vertical, 14)

                // Content
                if servers.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    GeometryReader { geo in
                        let columnCount = max(1, Int(geo.size.width / 400))
                        let rows = filteredServers.chunked(into: columnCount)
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                    HStack(spacing: 14) {
                                        ForEach(row) { server in
                                            UnifiedServerCard(
                                                server: server,
                                                connectionState: connectionManager.serverStates[server.id] ?? .disconnected,
                                                metrics: metricsEngine.serverMetrics[server.id],
                                                onToggleConnection: { toggleConnection(server) },
                                                onTap: { openDetail(server) },
                                                onDelete: { deleteServer(server) }
                                            )
                                            .frame(maxWidth: .infinity)
                                        }
                                        // Fill empty slots so last row stays aligned
                                        if row.count < columnCount {
                                            ForEach(0..<(columnCount - row.count), id: \.self) { _ in
                                                Color.clear.frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, ThemeManager.paddingLarge)
                            .padding(.bottom, ThemeManager.paddingLarge)
                        }
                    }
                }
            }
            .background(theme.background)
            .sheet(isPresented: $showAddServer) {
                AddServerSheet()
            }
            .navigationDestination(for: UUID.self) { serverId in
                if let server = servers.first(where: { $0.id == serverId }) {
                    ServerDetailView(server: server)
                }
            }
            .task {
                // Only auto-connect on fresh app start (no server states set yet)
                guard autoConnectOnLaunch else { return }
                let neverTouched = servers.allSatisfy { connectionManager.serverStates[$0.id] == nil }
                guard neverTouched else { return }
                await autoConnectAll()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "server.rack")
                .font(.system(size: theme.scaled(44)))
                .foregroundStyle(theme.textTertiary)
            Text(loc["dashboard.empty.title"])
                .font(.system(size: theme.scaled(16), weight: .semibold))
                .foregroundStyle(theme.textMuted)
            Button(loc["dashboard.empty.add"]) {
                showAddServer = true
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.buttonPrimary)
            .handCursorOnHover()
        }
    }

    private func openDetail(_ server: Server) {
        navigationPath.append(server.id)
    }

    private func toggleConnection(_ server: Server) {
        let state = connectionManager.serverStates[server.id] ?? .disconnected
        if state == .connected {
            metricsEngine.stopPolling(serverId: server.id)
            Task { await connectionManager.disconnect(from: server.id) }
        } else {
            Task { await connectServer(server) }
        }
    }

    private func connectServer(_ server: Server) async {
        do {
            try await connectionManager.connect(to: server)
            metricsEngine.startPolling(server: server)
        } catch {
            // State set to .error by connection manager
        }
    }

    private func deleteServer(_ server: Server) {
        metricsEngine.stopPolling(serverId: server.id)
        Task { await connectionManager.disconnect(from: server.id) }
        KeychainService.shared.deleteAll(for: server.id.uuidString)
        modelContext.delete(server)
    }

    private func autoConnectAll() async {
        for server in servers where server.isEnabled {
            let state = connectionManager.serverStates[server.id] ?? .disconnected
            if state == .disconnected {
                await connectServer(server)
            }
        }
    }
}

// MARK: - Unified Server Card

struct UnifiedServerCard: View {
    let server: Server
    let connectionState: Server.ConnectionState
    let metrics: ServerMetrics?
    let onToggleConnection: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    @Environment(LocalizationManager.self) private var loc
    @Environment(ThemeManager.self) private var theme
    @AppStorage("showTemperatureInCard") private var showTemperatureInCard = true
    @State private var isHovering = false
    @State private var isHoveringDetails = false
    @State private var isHoveringConnect = false
    @State private var isHoveringDelete = false
    @State private var showDeleteConfirm = false

    private var isConnected: Bool { connectionState == .connected }

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Name + Temp + Actions
            HStack(spacing: 8) {
                Text(server.name)
                    .font(.system(size: theme.scaled(15), weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(server.username)@\(server.hostname)")
                    .font(.system(size: theme.scaled(11)))
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if showTemperatureInCard, let temp = metrics?.temperature?.maxTemperature {
                    HStack(spacing: 3) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: theme.scaled(10)))
                            .foregroundStyle(tempColor(temp))
                        Text("\(Int(temp))°C")
                            .font(.system(size: theme.scaled(12), weight: .semibold, design: .monospaced))
                            .foregroundStyle(tempColor(temp))
                    }
                }

                // Connect toggle
                connectToggle

                // Details button
                if isConnected {
                    Button { onTap() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: theme.scaled(9)))
                            Text(loc["dashboard.card.details"])
                                .font(.system(size: theme.scaled(10), weight: .bold))
                                .lineLimit(1)
                        }
                        .fixedSize()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isHoveringDetails ? theme.buttonPrimaryHover : theme.buttonPrimary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringDetails = $0 }
                    .handCursorOnHover()
                }

                // Delete button — neutral, danger on hover
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: theme.scaled(11)))
                        .foregroundStyle(isHoveringDelete ? theme.buttonDanger : theme.textTertiary)
                        .padding(4)
                        .background(isHoveringDelete ? theme.buttonDangerBg : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
                .onHover { isHoveringDelete = $0 }
                .handCursorOnHover()
                .alert(loc["dashboard.card.delete_title"], isPresented: $showDeleteConfirm) {
                    Button(loc["common.cancel"], role: .cancel) { }
                    Button(loc["dashboard.card.delete_confirm"], role: .destructive) { onDelete() }
                } message: {
                    Text(loc.string("dashboard.card.delete_message", server.name))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Row 2: Metrics or status text
            if isConnected, let m = metrics {
                metricsRow(m)

                // Row 3: Disk usage bars
                if !m.disks.isEmpty {
                    diskUsageRow(m.disks)
                }
            } else if connectionState == .connecting {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(loc["dashboard.card.connecting"])
                        .font(.system(size: theme.scaled(12)))
                        .foregroundStyle(theme.textMuted)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            } else if connectionState == .error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: theme.scaled(11)))
                        .foregroundStyle(theme.statusWarning)
                    Text(loc["dashboard.card.failed"])
                        .font(.system(size: theme.scaled(12)))
                        .foregroundStyle(theme.textMuted)
                    Spacer()
                    Button { onTap() } label: {
                        Text(loc["dashboard.card.retry"])
                            .font(.system(size: theme.scaled(11), weight: .semibold))
                            .foregroundStyle(theme.buttonPrimary)
                    }
                    .buttonStyle(.plain)
                    .handCursorOnHover()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            } else {
                HStack {
                    Text(loc["dashboard.card.offline"])
                        .font(.system(size: theme.scaled(12)))
                        .foregroundStyle(theme.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(isHovering ? theme.surfacePrimary.opacity(0.85) : theme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovering ? theme.buttonPrimary.opacity(0.4) : (isConnected ? theme.border : theme.border.opacity(0.5)), lineWidth: 1)
        )
        .shadow(color: isHovering ? Color.black.opacity(0.15) : Color.clear, radius: 6, y: 2)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .handCursorOnHover()
    }

    // MARK: - Connect Toggle

    private var connectToggle: some View {
        Button {
            onToggleConnection()
        } label: {
            HStack(spacing: 5) {
                // Status dot — indicator keeps status colors
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(0.6), radius: isConnected ? 4 : 0)

                if connectionState == .connecting {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Text(isConnected ? loc["dashboard.card.on"] : loc["dashboard.card.off"])
                        .font(.system(size: theme.scaled(10), weight: .bold))
                        .foregroundStyle(isConnected ? theme.textPrimary : theme.textTertiary)
                        .lineLimit(1)
                }
            }
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                isHoveringConnect
                    ? (isConnected ? theme.buttonPrimary.opacity(0.3) : theme.buttonSecondary.opacity(0.5))
                    : (isConnected ? theme.buttonPrimary.opacity(0.15) : theme.border.opacity(0.5))
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHoveringConnect = $0 }
        .handCursorOnHover()
    }

    private var statusColor: Color {
        switch connectionState {
        case .connected: return theme.statusOnline
        case .connecting: return theme.statusWarning
        case .error: return theme.statusOffline
        case .disconnected: return theme.textTertiary
        }
    }

    // MARK: - Metrics Row

    private func metricsRow(_ m: ServerMetrics) -> some View {
        HStack(spacing: 14) {
            // CPU gauge — dynamic color based on usage
            VStack(spacing: 2) {
                GaugeRing(
                    value: m.cpu.totalUsage,
                    label: "\(Int(m.cpu.totalUsage * 100))%",
                    color: theme.utilizationColor(m.cpu.totalUsage),
                    lineWidth: 4,
                    size: 42,
                    fontSize: 11,
                    animateOnTap: true
                )
                Text(loc["dashboard.card.cpu"])
                    .font(.system(size: theme.scaled(9), weight: .medium))
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
            }
            .fixedSize()

            // Memory gauge — dynamic color based on usage
            VStack(spacing: 2) {
                GaugeRing(
                    value: m.memory.usagePercent,
                    label: "\(Int(m.memory.usagePercent * 100))%",
                    color: theme.utilizationColor(m.memory.usagePercent),
                    lineWidth: 4,
                    size: 42,
                    fontSize: 11,
                    animateOnTap: true
                )
                Text(loc["dashboard.card.memory"])
                    .font(.system(size: theme.scaled(9), weight: .medium))
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
            }
            .fixedSize()

            Spacer()

            // Network — dynamic colors: green↑ red↓ when active, neutral when idle
            VStack(alignment: .trailing, spacing: 3) {
                let totalTx = m.networks.reduce(0.0) { $0 + $1.txBytesPerSec }
                let totalRx = m.networks.reduce(0.0) { $0 + $1.rxBytesPerSec }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: theme.scaled(8), weight: .bold))
                        .foregroundStyle(theme.activityUploadColor(totalTx))
                    Text(ByteFormatter.formatRate(totalTx))
                        .font(.system(size: theme.scaled(10), weight: .bold, design: .monospaced))
                        .foregroundStyle(totalTx > 0 ? theme.textPrimary : theme.textTertiary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: theme.scaled(8), weight: .bold))
                        .foregroundStyle(theme.activityDownloadColor(totalRx))
                    Text(ByteFormatter.formatRate(totalRx))
                        .font(.system(size: theme.scaled(10), weight: .bold, design: .monospaced))
                        .foregroundStyle(totalRx > 0 ? theme.textPrimary : theme.textTertiary)
                }
            }
            .fixedSize()

            // Disk I/O — dynamic colors: green R, orange W when active
            VStack(alignment: .trailing, spacing: 3) {
                let totalRead = m.disks.reduce(0.0) { $0 + $1.readBytesPerSec }
                let totalWrite = m.disks.reduce(0.0) { $0 + $1.writeBytesPerSec }
                HStack(spacing: 4) {
                    Text("R")
                        .font(.system(size: theme.scaled(9), weight: .bold))
                        .foregroundStyle(theme.activityReadColor(totalRead))
                    Text(ByteFormatter.formatRate(totalRead))
                        .font(.system(size: theme.scaled(10), weight: .bold, design: .monospaced))
                        .foregroundStyle(totalRead > 0 ? theme.textPrimary : theme.textTertiary)
                }
                HStack(spacing: 4) {
                    Text("W")
                        .font(.system(size: theme.scaled(9), weight: .bold))
                        .foregroundStyle(theme.activityWriteColor(totalWrite))
                    Text(ByteFormatter.formatRate(totalWrite))
                        .font(.system(size: theme.scaled(10), weight: .bold, design: .monospaced))
                        .foregroundStyle(totalWrite > 0 ? theme.textPrimary : theme.textTertiary)
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Helpers

    private func tempColor(_ temp: Double) -> Color {
        if temp >= 80 { return theme.statusOffline }
        if temp >= 60 { return theme.statusWarning }
        return theme.textMuted
    }

    // MARK: - Disk Usage Row

    private func diskUsageRow(_ disks: [DiskMetrics]) -> some View {
        let mainDisks = disks
            .filter { !$0.mountPoint.hasPrefix("/boot") && !$0.mountPoint.hasPrefix("/snap") && $0.totalBytes > 0 }
            .prefix(3)

        return VStack(spacing: 4) {
            ForEach(Array(mainDisks)) { disk in
                HStack(spacing: 6) {
                    Text(disk.mountPoint)
                        .font(.system(size: theme.scaled(9), design: .monospaced))
                        .foregroundStyle(theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 40, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.border.opacity(0.5))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.utilizationColor(disk.usagePercent))
                                .frame(width: max(geo.size.width * CGFloat(disk.usagePercent), 2))
                        }
                    }
                    .frame(height: 6)

                    Text("\(ByteFormatter.format(disk.usedBytes))/\(ByteFormatter.format(disk.totalBytes))")
                        .font(.system(size: theme.scaled(9), design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                        .fixedSize()

                    Text("\(Int(disk.usagePercent * 100))%")
                        .font(.system(size: theme.scaled(9), weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.utilizationColor(disk.usagePercent))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}

// MARK: - Array Chunking Helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
