import SwiftUI
import SwiftData

struct ServerDetailView: View {
    let server: Server
    @Environment(SSHConnectionManager.self) private var connectionManager
    @Environment(MetricsEngine.self) private var metricsEngine
    @Environment(TerminalSessionManager.self) private var terminalManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.dismiss) private var dismiss

    private var metrics: ServerMetrics? {
        metricsEngine.serverMetrics[server.id]
    }

    private var state: Server.ConnectionState {
        connectionManager.serverStates[server.id] ?? .disconnected
    }

    var body: some View {
        VStack(spacing: 0) {
            detailHeader

            // Two-column layout: panels left, processes right
            HStack(alignment: .top, spacing: 0) {
                // Left: metric panels
                ScrollView {
                    VStack(spacing: 12) {
                        cpuPanel
                        memoryPanel
                        networkPanel
                        diskPanel
                    }
                    .padding(16)
                }
                .frame(minWidth: 380, maxWidth: 500)

                Divider().overlay(AppTheme.border)

                // Right: process list
                ProcessTableView(server: server)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.background)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var detailHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: AppTheme.scaled(18), weight: .semibold))
                    .foregroundStyle(AppTheme.buttonPrimary)
            }
            .buttonStyle(.plain)
            .handCursorOnHover()

            Text(server.name)
                .font(.system(size: AppTheme.scaled(22), weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // Quick stats in header
            if let m = metrics {
                HStack(spacing: 20) {
                    HeaderStat(
                        label: loc["detail.header.cpu"],
                        value: "\(Int(m.cpu.totalUsage * 100))%",
                        color: AppTheme.utilizationColor(m.cpu.totalUsage)
                    )
                    HeaderStat(
                        label: loc["detail.header.cores"],
                        value: "\(m.cpu.perCore.count)",
                        color: AppTheme.textPrimary
                    )
                    HeaderStat(
                        label: loc["detail.header.idle"],
                        value: "\(Int(m.cpu.idle * 100))%",
                        color: AppTheme.textPrimary
                    )
                    HeaderStat(
                        label: loc["detail.header.uptime"],
                        value: TimeFormatter.formatUptime(m.uptime),
                        color: AppTheme.textPrimary
                    )
                    if let temp = m.temperature?.maxTemperature {
                        HeaderStat(
                            label: loc["detail.header.temp"],
                            value: "\(Int(temp))°C",
                            color: temp >= 70 ? AppTheme.statusOffline : AppTheme.statusWarning
                        )
                    }
                }
            }

            HStack(spacing: 8) {
                Button {
                    Task {
                        try? await terminalManager.openSession(for: server, connectionManager: connectionManager)
                    }
                } label: {
                    Image(systemName: "terminal")
                }
                .buttonStyle(.bordered)
                .handCursorOnHover()

                Button {
                    metricsEngine.stopPolling(serverId: server.id)
                    metricsEngine.startPolling(server: server)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .handCursorOnHover()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surfaceSecondary)
        .overlay(alignment: .bottom) {
            Divider().overlay(AppTheme.border)
        }
    }

    // MARK: - CPU Panel

    private var cpuPanel: some View {
        PanelContainer(title: loc["detail.panel.cpu"]) {
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    Text("\(Int((metrics?.cpu.totalUsage ?? 0) * 100))")
                        .font(.system(size: AppTheme.scaled(36), weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("%")
                        .font(.system(size: AppTheme.scaled(16), weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                        .offset(y: 6)

                    Spacer()

                    if let cpu = metrics?.cpu {
                        HStack(spacing: 16) {
                            cpuStatLabel(loc["detail.cpu.system"], value: "\(Int(cpu.systemUsage * 100))%", color: AppTheme.statusOffline)
                            cpuStatLabel(loc["detail.cpu.user"], value: "\(Int(cpu.userUsage * 100))%", color: AppTheme.statusOnline)
                            cpuStatLabel(loc["detail.cpu.iowait"], value: "\(Int(cpu.ioWait * 100))%", color: AppTheme.statusWarning)
                            cpuStatLabel(loc["detail.cpu.steal"], value: "\(Int(cpu.steal * 100))%", color: AppTheme.textMuted)
                        }
                    }
                }

                if let cores = metrics?.cpu.perCore, !cores.isEmpty {
                    PerCoreGridView(cores: cores)
                }

                HStack {
                    if let cpu = metrics?.cpu {
                        bottomStat(loc["detail.cpu.cores"], value: "\(cpu.perCore.count)")
                        Spacer()
                        bottomStat(loc["detail.cpu.idle"], value: "\(Int(cpu.idle * 100))%")
                        Spacer()
                        bottomStat(loc["detail.cpu.uptime"], value: TimeFormatter.formatUptime(metrics?.uptime ?? 0))
                        Spacer()
                    }

                    GaugeRing(
                        value: metrics?.cpu.totalUsage ?? 0,
                        label: "",
                        color: AppTheme.utilizationColor(metrics?.cpu.totalUsage ?? 0),
                        lineWidth: 5,
                        size: 48,
                        showLabel: false,
                        animateOnTap: true
                    )
                }
            }
        }
    }

    private func cpuStatLabel(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: AppTheme.scaled(9), weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: AppTheme.scaled(13), weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func bottomStat(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: AppTheme.scaled(9), weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: AppTheme.scaled(14), weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Memory Panel

    private var memoryPanel: some View {
        PanelContainer(title: loc["detail.panel.memory"]) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        memStatBlock(loc["detail.memory.free"], value: ByteFormatter.format(metrics?.memory.freeBytes ?? 0), color: AppTheme.statusOnline)
                        memStatBlock(loc["detail.memory.used"], value: ByteFormatter.format(metrics?.memory.usedBytes ?? 0), color: AppTheme.utilizationColor(metrics?.memory.usagePercent ?? 0))
                        memStatBlock(loc["detail.memory.page_cache"], value: ByteFormatter.format(metrics?.memory.cachedBytes ?? 0), color: AppTheme.cachedColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    GaugeRing(
                        value: metrics?.memory.usagePercent ?? 0,
                        label: "\(Int((metrics?.memory.usagePercent ?? 0) * 100))%",
                        color: AppTheme.utilizationColor(metrics?.memory.usagePercent ?? 0),
                        lineWidth: 6,
                        size: 72,
                        fontSize: 18,
                        animateOnTap: true
                    )
                }

                if let mem = metrics?.memory, mem.totalBytes > 0 {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            let total = Double(mem.totalBytes)
                            let w = geo.size.width
                            let usedW = Double(mem.usedBytes) / total * w
                            let bufW = Double(mem.buffersBytes) / total * w
                            let cachedW = Double(mem.cachedBytes) / total * w
                            let freeW = Double(mem.freeBytes) / total * w

                            Rectangle().fill(AppTheme.utilizationColor(mem.usagePercent)).frame(width: max(usedW, 0))
                            Rectangle().fill(AppTheme.buffersColor).frame(width: max(bufW, 0))
                            Rectangle().fill(AppTheme.cachedColor).frame(width: max(cachedW, 0))
                            Rectangle().fill(AppTheme.statusOnline).frame(width: max(freeW, 0))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private func memStatBlock(_ label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: AppTheme.scaled(9), weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: AppTheme.scaled(14), weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
        }
    }

    // MARK: - Network Panel

    private var networkPanel: some View {
        PanelContainer(title: loc["detail.panel.network"]) {
            VStack(spacing: 8) {
                let interfaces = metrics?.networks ?? []
                ForEach(interfaces) { iface in
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: iface.id.contains("wlan") || iface.id.contains("wl") ? "wifi" : "cable.connector")
                                .font(.system(size: AppTheme.scaled(11)))
                                .foregroundStyle(AppTheme.statusOnline)
                            Text(iface.id)
                                .font(.system(size: AppTheme.scaled(13), weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: AppTheme.scaled(8), weight: .bold))
                                    .foregroundStyle(AppTheme.activityUploadColor(iface.txBytesPerSec))
                                Text(loc["detail.network.upload_rate"])
                                    .foregroundStyle(AppTheme.textTertiary)
                                Text(ByteFormatter.formatRate(iface.txBytesPerSec))
                                    .foregroundStyle(iface.txBytesPerSec > 0 ? AppTheme.statusOnline : AppTheme.textSecondary)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: AppTheme.scaled(8), weight: .bold))
                                    .foregroundStyle(AppTheme.activityDownloadColor(iface.rxBytesPerSec))
                                Text(loc["detail.network.download_rate"])
                                    .foregroundStyle(AppTheme.textTertiary)
                                Text(ByteFormatter.formatRate(iface.rxBytesPerSec))
                                    .foregroundStyle(iface.rxBytesPerSec > 0 ? AppTheme.statusOffline : AppTheme.textSecondary)
                            }
                        }
                        .font(.system(size: AppTheme.scaled(11), design: .monospaced))

                        VStack(alignment: .trailing, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(loc["detail.network.upload_total"])
                                    .foregroundStyle(AppTheme.textTertiary)
                                Text(ByteFormatter.format(iface.totalTxBytes))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            HStack(spacing: 4) {
                                Text(loc["detail.network.download_total"])
                                    .foregroundStyle(AppTheme.textTertiary)
                                Text(ByteFormatter.format(iface.totalRxBytes))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .font(.system(size: AppTheme.scaled(11), design: .monospaced))

                        let maxRate = max(iface.txBytesPerSec, iface.rxBytesPerSec)
                        let ringVal = min(maxRate / 1_000_000, 1.0)
                        GaugeRing(
                            value: ringVal,
                            label: "",
                            color: AppTheme.utilizationColor(ringVal),
                            lineWidth: 3,
                            size: 32,
                            showLabel: false,
                            animateOnTap: true
                        )
                    }
                    .padding(8)
                    .background(AppTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Disk Panel

    private var diskPanel: some View {
        PanelContainer(title: loc["detail.panel.disks"]) {
            VStack(spacing: 8) {
                let disks = metrics?.disks ?? []
                ForEach(disks) { disk in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(disk.mountPoint)
                                .font(.system(size: AppTheme.scaled(13), weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Text(disk.filesystem.uppercased())
                                .font(.system(size: AppTheme.scaled(10), weight: .medium))
                                .foregroundStyle(AppTheme.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.border)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text("\(ByteFormatter.format(disk.usedBytes))/\(ByteFormatter.format(disk.totalBytes))")
                                .font(.system(size: AppTheme.scaled(12), design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppTheme.border)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppTheme.utilizationColor(disk.usagePercent))
                                    .frame(width: geo.size.width * CGFloat(disk.usagePercent))
                                    .animation(.easeInOut(duration: 0.5), value: disk.usagePercent)
                            }
                        }
                        .frame(height: 6)

                        HStack(spacing: 0) {
                            diskIOStat(loc["detail.disk.speed"], readVal: ByteFormatter.formatRate(disk.readBytesPerSec), writeVal: ByteFormatter.formatRate(disk.writeBytesPerSec), readRate: disk.readBytesPerSec, writeRate: disk.writeBytesPerSec)
                            Spacer()
                            diskIOStat(loc["detail.disk.iops"], readVal: String(format: "%.0f", disk.iopsRead), writeVal: String(format: "%.0f", disk.iopsWrite), readRate: disk.iopsRead, writeRate: disk.iopsWrite)
                        }
                    }
                    .padding(10)
                    .background(AppTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func diskIOStat(_ title: String, readVal: String, writeVal: String, readRate: Double, writeRate: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: AppTheme.scaled(9), weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("R")
                        .foregroundStyle(AppTheme.activityReadColor(readRate))
                    Text(readVal)
                        .foregroundStyle(readRate > 0 ? AppTheme.textPrimary : AppTheme.textSecondary)
                }
                HStack(spacing: 4) {
                    Text("W")
                        .foregroundStyle(AppTheme.activityWriteColor(writeRate))
                    Text(writeVal)
                        .foregroundStyle(writeRate > 0 ? AppTheme.textPrimary : AppTheme.textSecondary)
                }
            }
            .font(.system(size: AppTheme.scaled(11), design: .monospaced))
        }
    }
}

// MARK: - Per-Core Grid

struct PerCoreGridView: View {
    let cores: [CPUMetrics.CoreMetrics]

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: min(cores.count, 8))
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(cores) { core in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.utilizationColor(core.usage))
                    .frame(height: AppTheme.scaled(10))
                    .animation(.easeInOut(duration: 0.3), value: core.usage)
            }
        }
    }
}

// MARK: - Supporting Views

private struct HeaderStat: View {
    let label: String
    let value: String
    var color: Color = AppTheme.textPrimary

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: AppTheme.scaled(9), weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: AppTheme.scaled(13), weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PanelContainer<Content: View>: View {
    let title: String
    var badge: String = ""
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: AppTheme.scaled(13), weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer()
                if !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: AppTheme.scaled(11), weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }

            content()
        }
        .padding(14)
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Process Table

struct ProcessTableView: View {
    let server: Server
    @Environment(MetricsEngine.self) private var metricsEngine
    @Environment(LocalizationManager.self) private var loc
    @State private var processes: [RemoteProcess] = []
    @State private var sortBy: SortKey = .cpu

    enum SortKey {
        case cpu, mem
    }

    private var sortedProcesses: [RemoteProcess] {
        switch sortBy {
        case .cpu: return processes.sorted { $0.cpuPercent > $1.cpuPercent }
        case .mem: return processes.sorted { $0.memPercent > $1.memPercent }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(loc["detail.process.title"])
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { sortBy = .cpu } label: {
                    HStack(spacing: 2) {
                        Text(loc["detail.process.cpu"])
                        if sortBy == .cpu {
                            Image(systemName: "chevron.down")
                                .font(.system(size: AppTheme.scaled(8)))
                        }
                    }
                }
                .buttonStyle(.plain)
                .handCursorOnHover()
                .frame(width: 60, alignment: .trailing)

                Button { sortBy = .mem } label: {
                    HStack(spacing: 2) {
                        Text(loc["detail.process.memory"])
                        if sortBy == .mem {
                            Image(systemName: "chevron.down")
                                .font(.system(size: AppTheme.scaled(8)))
                        }
                    }
                }
                .buttonStyle(.plain)
                .handCursorOnHover()
                .frame(width: 60, alignment: .trailing)
            }
            .font(.system(size: AppTheme.scaled(11), weight: .semibold))
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            Divider().overlay(AppTheme.border)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sortedProcesses) { proc in
                        HStack(spacing: 0) {
                            Text(proc.command)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(AppTheme.textSecondary)

                            Text(String(format: "%.0f%%", proc.cpuPercent))
                                .frame(width: 60, alignment: .trailing)
                                .foregroundStyle(proc.cpuPercent > 50 ? AppTheme.statusOffline : AppTheme.textMuted)

                            Text(ByteFormatter.format(proc.rss * 1024))
                                .frame(width: 60, alignment: .trailing)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .font(.system(size: AppTheme.scaled(12), design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)

                        Divider().overlay(AppTheme.border.opacity(0.3))
                    }
                }
            }
        }
        .task {
            processes = await metricsEngine.fetchProcesses(for: server)
        }
    }
}
