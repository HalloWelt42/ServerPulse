import SwiftUI
import SwiftData

struct ContainersDashboardView: View {
    @Environment(SSHConnectionManager.self) private var connectionManager
    @Environment(DockerService.self) private var dockerService
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @State private var searchText = ""
    @State private var statusFilter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable {
        case all, running, stopped
        @MainActor func displayName(_ loc: LocalizationManager) -> String {
            loc["containers.filter.\(rawValue)"]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(loc["containers.title"])
                    .font(.system(size: AppTheme.scaled(24), weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer()

                HStack(spacing: 12) {
                    TextField(loc["containers.search"], text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)

                    ForEach(StatusFilter.allCases, id: \.self) { filter in
                        Button(filter.displayName(loc)) {
                            statusFilter = filter
                        }
                        .buttonStyle(.bordered)
                        .tint(statusFilter == filter ? AppTheme.buttonPrimary : .gray)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .handCursorOnHover()
                    }
                }
            }
            .padding(.horizontal, AppTheme.paddingLarge)
            .padding(.vertical, AppTheme.paddingMedium)

            // Container list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(connectedServers) { server in
                        let containers = filteredContainers(for: server.id)
                        if !containers.isEmpty {
                            serverSection(server: server, containers: containers)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingLarge)
                .padding(.bottom, AppTheme.paddingLarge)
            }

            if connectedServers.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: AppTheme.scaled(48)))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text(loc["containers.empty.title"])
                        .font(.system(size: AppTheme.scaled(18), weight: .semibold))
                        .foregroundStyle(AppTheme.textMuted)
                    Text(loc["containers.empty.subtitle"])
                        .font(.system(size: AppTheme.scaled(13)))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
            }
        }
        .background(AppTheme.background)
        .task {
            await refreshContainers()
        }
    }

    private var connectedServers: [Server] {
        servers.filter { server in
            server.dockerEnabled && connectionManager.isConnected(serverId: server.id)
        }
    }

    private func filteredContainers(for serverId: UUID) -> [DockerContainer] {
        let all = dockerService.containers[serverId] ?? []
        var filtered = all

        switch statusFilter {
        case .all: break
        case .running:
            filtered = filtered.filter { $0.status == .running }
        case .stopped:
            filtered = filtered.filter { $0.status == .exited || $0.status == .dead }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.image.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    @ViewBuilder
    private func serverSection(server: Server, containers: [DockerContainer]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.string("containers.server_info", server.name, server.hostname, containers.count))
                .font(.system(size: AppTheme.scaled(14), weight: .semibold))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.bottom, 4)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300, maximum: 450), spacing: 12)
            ], spacing: 12) {
                ForEach(containers) { container in
                    ContainerCardView(container: container, server: server)
                }
            }
        }
    }

    private func refreshContainers() async {
        for server in connectedServers {
            guard let session = connectionManager.getMetricsSession(for: server.id) else { continue }
            await dockerService.fetchContainers(for: server, session: session)
        }
    }
}

// MARK: - Container Card

struct ContainerCardView: View {
    let container: DockerContainer
    let server: Server
    @Environment(DockerService.self) private var dockerService
    @Environment(SSHConnectionManager.self) private var connectionManager
    @Environment(LocalizationManager.self) private var loc
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(container.status.isRunning ? 0.6 : 0), radius: 3)

                Text(container.name)
                    .font(.system(size: AppTheme.scaled(13), weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                containerActions
            }

            // Image name
            Text(container.image)
                .font(.system(size: AppTheme.scaled(10), design: .monospaced))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)

            // Metrics
            HStack(spacing: 12) {
                // CPU gauge
                GaugeRingSmall(
                    value: (container.metrics?.cpuPercent ?? 0) / 100.0,
                    color: AppTheme.cpuColor
                )

                // Memory
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc["containers.memory"])
                        .font(.system(size: AppTheme.scaled(11), weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                    Text(ByteFormatter.format(container.metrics?.memoryUsageBytes ?? 0))
                        .font(.system(size: AppTheme.scaled(12), weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                // Net I/O
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc["containers.net_io"])
                        .font(.system(size: AppTheme.scaled(11), weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                    Text(ByteFormatter.format(container.metrics?.networkRxBytes ?? 0))
                        .font(.system(size: AppTheme.scaled(12), weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                // Block I/O
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc["containers.block_io"])
                        .font(.system(size: AppTheme.scaled(11), weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                    Text(ByteFormatter.format(container.metrics?.blockReadBytes ?? 0))
                        .font(.system(size: AppTheme.scaled(12), weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(isHovering ? AppTheme.surfacePrimary.opacity(0.85) : AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovering ? AppTheme.buttonPrimary.opacity(0.4) : AppTheme.border, lineWidth: 1)
        )
        .shadow(color: isHovering ? Color.black.opacity(0.12) : Color.clear, radius: 5, y: 2)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var containerActions: some View {
        HStack(spacing: 4) {
            if container.status.isRunning {
                ContainerActionButton(
                    icon: "stop.fill",
                    label: loc["containers.action.stop"],
                    color: AppTheme.buttonSecondary,
                    hoverColor: AppTheme.buttonSecondaryHover
                ) {
                    Task { await performAction { try await dockerService.stopContainer(container.id, on: $0) } }
                }
                ContainerActionButton(
                    icon: "arrow.clockwise",
                    label: loc["containers.action.restart"],
                    color: AppTheme.buttonSecondary,
                    hoverColor: AppTheme.buttonSecondaryHover
                ) {
                    Task { await performAction { try await dockerService.restartContainer(container.id, on: $0) } }
                }
            } else {
                ContainerActionButton(
                    icon: "play.fill",
                    label: loc["containers.action.start"],
                    color: AppTheme.buttonPrimary,
                    hoverColor: AppTheme.buttonPrimaryHover
                ) {
                    Task { await performAction { try await dockerService.startContainer(container.id, on: $0) } }
                }
            }
        }
    }

    private func performAction(_ action: @escaping (SSHSession) async throws -> Void) async {
        guard let session = connectionManager.getMetricsSession(for: server.id) else { return }
        try? await action(session)
        await dockerService.fetchContainers(for: server, session: session)
    }

    private var statusColor: Color {
        switch container.status {
        case .running: return AppTheme.statusOnline
        case .paused: return AppTheme.statusWarning
        default: return AppTheme.statusOffline
        }
    }
}

// MARK: - Container Action Button

struct ContainerActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var hoverColor: Color? = nil
    let action: () -> Void

    @State private var isHovering = false

    private var resolvedHover: Color { hoverColor ?? color }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: AppTheme.scaled(10), weight: .bold))
                Text(label)
                    .font(.system(size: AppTheme.scaled(10), weight: .bold))
                    .lineLimit(1)
            }
            .fixedSize()
            .foregroundStyle(isHovering ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isHovering ? resolvedHover : color.opacity(0.2))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .handCursorOnHover()
        .animation(.easeInOut(duration: 0.12), value: isHovering)
    }
}
