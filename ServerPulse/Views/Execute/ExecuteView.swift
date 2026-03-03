import SwiftUI
import SwiftData

struct ExecuteView: View {
    @Environment(SSHConnectionManager.self) private var connectionManager
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Server.sortOrder) private var servers: [Server]
    @Query(sort: \Snippet.name) private var snippets: [Snippet]

    @State private var command = ""
    @State private var selectedServerIds: Set<UUID> = []
    @State private var executions: [CommandExecution] = []
    @State private var isRunning = false

    private var connectedServers: [Server] {
        servers.filter { connectionManager.isConnected(serverId: $0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(loc["execute.title"])
                    .font(.system(size: AppTheme.scaled(24), weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer()
            }
            .padding(.horizontal, AppTheme.paddingLarge)
            .padding(.vertical, AppTheme.paddingMedium)

            HSplitView {
                // Left: Command + Server selection
                VStack(alignment: .leading, spacing: 16) {
                    // Command input
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(loc["execute.command"])
                                .font(.system(size: AppTheme.scaled(12), weight: .semibold))
                                .foregroundStyle(AppTheme.textTertiary)
                                .textCase(.uppercase)
                            Spacer()
                            snippetPicker
                        }

                        TextEditor(text: $command)
                            .font(.system(size: AppTheme.scaled(13), design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(AppTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            .frame(minHeight: 80, maxHeight: 120)
                    }

                    // Server selection
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(loc["execute.servers"])
                                .font(.system(size: AppTheme.scaled(12), weight: .semibold))
                                .foregroundStyle(AppTheme.textTertiary)
                                .textCase(.uppercase)

                            Spacer()

                            Button(loc["execute.select_all"]) {
                                selectedServerIds = Set(connectedServers.map(\.id))
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundStyle(AppTheme.buttonPrimary)
                            .handCursorOnHover()
                        }

                        if connectedServers.isEmpty {
                            Text(loc["execute.no_servers"])
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                                .padding()
                        } else {
                            ScrollView {
                                VStack(spacing: 4) {
                                    ForEach(connectedServers) { server in
                                        ServerCheckRow(
                                            server: server,
                                            isSelected: selectedServerIds.contains(server.id),
                                            onToggle: {
                                                if selectedServerIds.contains(server.id) {
                                                    selectedServerIds.remove(server.id)
                                                } else {
                                                    selectedServerIds.insert(server.id)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }

                    Button {
                        Task { await executeCommand() }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(loc.string("execute.run", selectedServerIds.count))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.buttonPrimary)
                    .disabled(command.isEmpty || selectedServerIds.isEmpty || isRunning)
                    .handCursorOnHover()

                    Spacer()
                }
                .padding(AppTheme.paddingLarge)
                .frame(minWidth: 300, maxWidth: 400)

                // Right: Results
                VStack(alignment: .leading, spacing: 8) {
                    if executions.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: AppTheme.scaled(48)))
                                .foregroundStyle(AppTheme.textTertiary)
                            Text(loc["execute.results"])
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(executions) { exec in
                                    ExecutionResultCard(execution: exec)
                                }
                            }
                            .padding(AppTheme.paddingMedium)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.background)
    }

    private var snippetPicker: some View {
        Menu(loc["execute.insert_snippet"]) {
            ForEach(snippets) { snippet in
                Button(snippet.name) {
                    command = snippet.command
                }
            }
        }
        .font(.caption)
        .disabled(snippets.isEmpty)
        .handCursorOnHover()
    }

    private func executeCommand() async {
        isRunning = true
        executions.removeAll()

        let cmd = command // Capture for Sendable closure

        await withTaskGroup(of: CommandExecution.self) { group in
            for serverId in selectedServerIds {
                guard let server = servers.first(where: { $0.id == serverId }),
                      let session = connectionManager.getMetricsSession(for: serverId) else { continue }

                let sid = server.id
                let sname = server.name

                group.addTask {
                    var exec = CommandExecution(
                        serverId: sid,
                        serverName: sname,
                        command: cmd
                    )
                    do {
                        let output = try await session.execute(cmd)
                        exec.output = output
                        exec.exitCode = 0
                    } catch {
                        exec.error = error.localizedDescription
                        exec.exitCode = 1
                    }
                    exec.completedAt = Date()
                    return exec
                }
            }

            for await result in group {
                executions.append(result)
            }
        }

        isRunning = false
    }
}

// MARK: - Server Check Row

private struct ServerCheckRow: View {
    let server: Server
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? AppTheme.buttonPrimary : AppTheme.textTertiary)

            VStack(alignment: .leading, spacing: 1) {
                Text(server.name)
                    .font(.system(size: AppTheme.scaled(13), weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(server.hostname)
                    .font(.system(size: AppTheme.scaled(11)))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(isSelected ? AppTheme.buttonPrimary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .handCursorOnHover()
    }
}

// MARK: - Execution Result Card

struct ExecutionResultCard: View {
    let execution: CommandExecution
    @Environment(LocalizationManager.self) private var loc

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(execution.succeeded ? AppTheme.statusOnline : AppTheme.statusOffline)
                        .frame(width: 8, height: 8)
                    Text(execution.serverName)
                        .font(.system(size: AppTheme.scaled(13), weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                if let exitCode = execution.exitCode {
                    Text(loc.string("execute.exit_code", exitCode))
                        .font(.system(size: AppTheme.scaled(11), design: .monospaced))
                        .foregroundStyle(execution.succeeded ? AppTheme.textMuted : AppTheme.statusOffline)
                }

                if execution.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if !execution.output.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(execution.output)
                        .font(.system(size: AppTheme.scaled(11), design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
                .padding(8)
                .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let error = execution.error {
                Text(error)
                    .font(.system(size: AppTheme.scaled(11)))
                    .foregroundStyle(AppTheme.statusOffline)
            }
        }
        .padding(12)
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
