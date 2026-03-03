import SwiftUI
import SwiftData

struct KeychainView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Server.name) private var servers: [Server]
    @State private var selectedServer: Server?
    @State private var showImportKey = false
    @State private var importKeyServerId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(loc["keychain.title"])
                    .font(.system(size: theme.scaled(24), weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer()
            }
            .padding(.horizontal, ThemeManager.paddingLarge)
            .padding(.vertical, ThemeManager.paddingMedium)

            if servers.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: theme.scaled(48)))
                        .foregroundStyle(theme.textTertiary)
                    Text(loc["keychain.empty.title"])
                        .font(.system(size: theme.scaled(18), weight: .semibold))
                        .foregroundStyle(theme.textMuted)
                    Text(loc["keychain.empty.subtitle"])
                        .font(.system(size: theme.scaled(12)))
                        .foregroundStyle(theme.textTertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(servers) { server in
                            KeychainEntryCard(server: server, onImportKey: {
                                importKeyServerId = server.id
                                showImportKey = true
                            })
                        }
                    }
                    .padding(ThemeManager.paddingLarge)
                }
            }
        }
        .background(theme.background)
        .fileImporter(
            isPresented: $showImportKey,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleKeyImport(result)
        }
    }

    private func handleKeyImport(_ result: Result<[URL], Error>) {
        guard let serverId = importKeyServerId,
              let server = servers.first(where: { $0.id == serverId }) else { return }

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            if let keyData = try? Data(contentsOf: url) {
                let keyId = server.sshKeyKeychainID ?? KeychainService.newCredentialID()
                try? KeychainService.shared.storeSSHKey(keyData, for: keyId)
                server.sshKeyKeychainID = keyId
                if server.authMethod == .password {
                    server.authMethod = .key
                }
            }
        case .failure:
            break
        }
    }
}

// MARK: - Keychain Entry Card

struct KeychainEntryCard: View {
    let server: Server
    let onImportKey: () -> Void
    @Environment(ThemeManager.self) private var theme
    @Environment(LocalizationManager.self) private var loc
    @State private var showPassword = false
    @State private var newPassword = ""
    @State private var isEditing = false

    private var hasPassword: Bool {
        guard let id = server.credentialKeychainID else { return false }
        return KeychainService.shared.getPassword(id: id) != nil
    }

    private var hasKey: Bool {
        guard let id = server.sshKeyKeychainID else { return false }
        return KeychainService.shared.getSSHKey(id: id) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Server Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(server.name)
                        .font(.system(size: theme.scaled(15), weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("\(server.username)@\(server.hostname):\(server.port)")
                        .font(.system(size: theme.scaled(12), design: .monospaced))
                        .foregroundStyle(theme.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                Text(server.authMethod.rawValue.capitalized)
                    .font(.system(size: theme.scaled(11), weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.border)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(theme.textSecondary)
            }

            Divider().background(theme.border)

            // Credentials
            HStack(spacing: 24) {
                // Password
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: theme.scaled(11)))
                            .foregroundStyle(theme.textTertiary)
                        Text(loc["keychain.password"])
                            .font(.system(size: theme.scaled(11), weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                            .textCase(.uppercase)
                    }

                    HStack(spacing: 8) {
                        if hasPassword {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.statusOnline)
                                .font(.system(size: theme.scaled(14)))
                            Text(loc["keychain.stored"])
                                .font(.system(size: theme.scaled(12)))
                                .foregroundStyle(theme.textSecondary)
                        } else {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(theme.textTertiary)
                                .font(.system(size: theme.scaled(14)))
                            Text(loc["keychain.not_set"])
                                .font(.system(size: theme.scaled(12)))
                                .foregroundStyle(theme.textMuted)
                        }

                        if isEditing {
                            SecureField(loc["keychain.password"], text: $newPassword)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            Button(loc["keychain.save"]) {
                                savePassword()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .handCursorOnHover()
                        }
                    }
                }

                Spacer()

                // SSH Key
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: theme.scaled(11)))
                            .foregroundStyle(theme.textTertiary)
                        Text(loc["keychain.ssh_key"])
                            .font(.system(size: theme.scaled(11), weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                            .textCase(.uppercase)
                    }

                    HStack(spacing: 8) {
                        if hasKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.statusOnline)
                                .font(.system(size: theme.scaled(14)))
                            Text(loc["keychain.imported"])
                                .font(.system(size: theme.scaled(12)))
                                .foregroundStyle(theme.textSecondary)
                        } else {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(theme.textTertiary)
                                .font(.system(size: theme.scaled(14)))
                            Text(loc["keychain.not_set"])
                                .font(.system(size: theme.scaled(12)))
                                .foregroundStyle(theme.textMuted)
                        }
                    }
                }
            }

            // Actions
            HStack(spacing: 8) {
                Button {
                    isEditing.toggle()
                    newPassword = ""
                } label: {
                    Label(isEditing ? loc["keychain.cancel"] : loc["keychain.edit_password"], systemImage: isEditing ? "xmark" : "pencil")
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .handCursorOnHover()

                Button {
                    onImportKey()
                } label: {
                    Label(loc["keychain.import_key"], systemImage: "square.and.arrow.down")
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .handCursorOnHover()

                Spacer()

                if hasPassword || hasKey {
                    Button(role: .destructive) {
                        removeCredentials()
                    } label: {
                        Label(loc["keychain.remove_all"], systemImage: "trash")
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .handCursorOnHover()
                }
            }
        }
        .padding(ThemeManager.paddingMedium)
        .background(theme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ThemeManager.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeManager.cornerRadius)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private func savePassword() {
        let id = server.credentialKeychainID ?? KeychainService.newCredentialID()
        try? KeychainService.shared.storePassword(newPassword, for: id)
        server.credentialKeychainID = id
        newPassword = ""
        isEditing = false
    }

    private func removeCredentials() {
        KeychainService.shared.deleteAll(for: server.credentialKeychainID ?? "")
        KeychainService.shared.deleteAll(for: server.sshKeyKeychainID ?? "")
        server.credentialKeychainID = nil
        server.sshKeyKeychainID = nil
    }
}
