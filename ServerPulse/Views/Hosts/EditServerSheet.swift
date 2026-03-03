import SwiftUI
import SwiftData
import AppKit

struct EditServerSheet: View {
    let server: Server
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Environment(ThemeManager.self) private var theme

    @State private var name = ""
    @State private var hostname = ""
    @State private var port = "22"
    @State private var username = "pi"
    @State private var authMethod: Server.AuthMethod = .password
    @State private var password = ""
    @State private var showPassword = false
    @State private var sshKeyData: Data?
    @State private var sshKeyFileName: String?
    @State private var hasExistingKey = false
    @State private var hasExistingPassword = false
    @State private var pollingInterval = "5"
    @State private var dockerEnabled = true
    @State private var isTesting = false
    @State private var testResult: String?

    private var portNumber: Int { Int(port) ?? 0 }

    private var isFormValid: Bool {
        let trimmedHost = hostname.trimmingCharacters(in: .whitespaces)
        let trimmedUser = username.trimmingCharacters(in: .whitespaces)
        return !trimmedHost.isEmpty
            && !trimmedUser.isEmpty
            && trimmedUser.count <= 32
            && portNumber >= 1 && portNumber <= 65535
            && name.count <= 48
            && !trimmedHost.contains(" ")
            && !trimmedUser.contains(" ")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Button(loc["add_server.cancel"]) { dismiss() }
                    .keyboardShortcut(.escape)
                    .foregroundStyle(theme.textSecondary)
                    .handCursorOnHover()

                Spacer()

                Text(loc["edit_server.title"])
                    .font(.system(size: theme.scaled(15), weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                Spacer()

                Button(loc["add_server.save"]) { saveChanges() }
                    .keyboardShortcut(.return)
                    .foregroundStyle(isFormValid ? theme.buttonPrimary : theme.textMuted)
                    .fontWeight(.bold)
                    .disabled(!isFormValid)
                    .handCursorOnHover()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.surfacePrimary)

            Divider().overlay(theme.border)

            // Form rows
            ScrollView {
                VStack(spacing: 0) {
                    // Connection section
                    sectionHeader(loc["add_server.section.connection"])

                    formRow(label: loc["add_server.name"]) {
                        TextField(loc["add_server.placeholder.name"], text: $name)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(theme.textPrimary)
                            .onChange(of: name) { _, val in
                                if val.count > 48 { name = String(val.prefix(48)) }
                            }
                    }

                    formDivider()

                    formRow(label: loc["add_server.host"]) {
                        HStack(spacing: 8) {
                            TextField(loc["add_server.placeholder.host"], text: $hostname)
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(theme.textPrimary)
                                .onChange(of: hostname) { _, val in
                                    hostname = val.filter { !$0.isWhitespace }
                                    if hostname.count > 253 { hostname = String(hostname.prefix(253)) }
                                }

                            Text(":")
                                .foregroundStyle(theme.textMuted)

                            TextField("22", text: $port)
                                .textFieldStyle(.plain)
                                .frame(width: 44)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(portNumber >= 1 && portNumber <= 65535 || port.isEmpty ? theme.textPrimary : theme.statusOffline)
                                .onChange(of: port) { _, val in
                                    port = val.filter(\.isNumber)
                                    if port.count > 5 { port = String(port.prefix(5)) }
                                }
                        }
                    }

                    formDivider()

                    formRow(label: loc["add_server.user"]) {
                        TextField("pi", text: $username)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(theme.textPrimary)
                            .onChange(of: username) { _, val in
                                username = val.filter { !$0.isWhitespace }
                                if username.count > 32 { username = String(username.prefix(32)) }
                            }
                    }

                    // Authentication section
                    sectionHeader(loc["add_server.section.auth"])

                    formRow(label: loc["add_server.method"]) {
                        Picker("", selection: $authMethod) {
                            Text(loc["add_server.auth.password"]).tag(Server.AuthMethod.password)
                            Text(loc["add_server.auth.key"]).tag(Server.AuthMethod.key)
                            Text(loc["add_server.auth.key_pass"]).tag(Server.AuthMethod.keyAndPassword)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    if authMethod == .key || authMethod == .keyAndPassword {
                        formDivider()

                        formRow(label: loc["add_server.ssh_key"]) {
                            HStack(spacing: 8) {
                                if let fileName = sshKeyFileName {
                                    Image(systemName: "key.fill")
                                        .foregroundStyle(theme.statusOnline)
                                        .font(.system(size: theme.scaled(11)))
                                    Text(fileName)
                                        .font(.system(size: theme.scaled(12), design: .monospaced))
                                        .foregroundStyle(theme.textSecondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } else if hasExistingKey {
                                    Image(systemName: "key.fill")
                                        .foregroundStyle(theme.statusOnline)
                                        .font(.system(size: theme.scaled(11)))
                                    Text(loc["edit_server.key_stored"])
                                        .font(.system(size: theme.scaled(12)))
                                        .foregroundStyle(theme.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button(sshKeyData == nil && !hasExistingKey ? loc["add_server.key.select"] : loc["add_server.key.change"]) {
                                    selectKeyFile()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .handCursorOnHover()
                            }
                        }
                    }

                    if authMethod == .password || authMethod == .keyAndPassword {
                        formDivider()

                        formRow(label: authMethod == .password ? loc["add_server.password"] : loc["add_server.passphrase"]) {
                            HStack(spacing: 8) {
                                if showPassword {
                                    TextField(hasExistingPassword ? loc["edit_server.password_hint"] : loc["add_server.placeholder.password"], text: $password)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(theme.textPrimary)
                                } else {
                                    SecureField(hasExistingPassword ? loc["edit_server.password_hint"] : loc["add_server.placeholder.password"], text: $password)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(theme.textPrimary)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(theme.textMuted)
                                        .font(.system(size: theme.scaled(13)))
                                }
                                .buttonStyle(.plain)
                                .handCursorOnHover()
                            }
                        }
                    }

                    // Options section
                    sectionHeader(loc["add_server.section.options"])

                    formRow(label: loc["add_server.polling"]) {
                        Picker("", selection: $pollingInterval) {
                            Text(loc["add_server.polling.1s"]).tag("1")
                            Text(loc["add_server.polling.5s"]).tag("5")
                            Text(loc["add_server.polling.10s"]).tag("10")
                            Text(loc["add_server.polling.30s"]).tag("30")
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }

                    formDivider()

                    formRow(label: loc["add_server.docker"]) {
                        Toggle("", isOn: $dockerEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(theme.buttonPrimary)
                    }

                    // Test connection section
                    if let testResult {
                        sectionHeader(loc["add_server.section.status"])

                        HStack {
                            Image(systemName: testResult.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(testResult.contains("Success") ? theme.statusOnline : theme.statusOffline)
                            Text(testResult)
                                .font(.system(size: theme.scaled(13)))
                                .foregroundStyle(theme.textSecondary)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(theme.surfacePrimary)
                    }

                    Spacer().frame(height: 20)

                    // Test button
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text(isTesting ? loc["add_server.test.testing"] : loc["add_server.test.button"])
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isFormValid || isTesting)
                    .handCursorOnHover()
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 16)
                }
            }
        }
        .frame(width: 560, height: 600)
        .background(theme.background)
        .onAppear { loadServerData() }
    }

    // MARK: - Form Components

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: theme.scaled(11), weight: .medium))
                .foregroundStyle(theme.textMuted)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: theme.scaled(14), weight: .medium))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.surfacePrimary)
    }

    @ViewBuilder
    private func formDivider() -> some View {
        Divider()
            .overlay(theme.border)
            .padding(.leading, 16)
    }

    // MARK: - Load Existing Data

    private func loadServerData() {
        name = server.name
        hostname = server.hostname
        port = String(server.port)
        username = server.username
        authMethod = server.authMethod
        pollingInterval = String(Int(server.pollingInterval))
        dockerEnabled = server.dockerEnabled

        // Check if credentials exist in Keychain
        if let credId = server.credentialKeychainID,
           KeychainService.shared.getPassword(id: credId) != nil {
            hasExistingPassword = true
        }

        if let keyId = server.sshKeyKeychainID,
           KeychainService.shared.getSSHKey(id: keyId) != nil {
            hasExistingKey = true
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        server.name = trimmedName.isEmpty ? hostname : trimmedName
        server.hostname = hostname.trimmingCharacters(in: .whitespaces)
        server.port = portNumber > 0 ? portNumber : 22
        server.username = username.trimmingCharacters(in: .whitespaces)
        server.authMethod = authMethod
        server.pollingInterval = Double(pollingInterval) ?? 5
        server.dockerEnabled = dockerEnabled
        server.updatedAt = Date()

        // Update password or passphrase if changed
        if !password.isEmpty {
            // Remove old credential if exists
            if let oldId = server.credentialKeychainID {
                try? KeychainService.shared.deletePassword(id: oldId)
            }
            let credId = KeychainService.newCredentialID()
            try? KeychainService.shared.storePassword(password, for: credId)
            server.credentialKeychainID = credId
        }

        // If auth method no longer needs password, clean up
        if authMethod == .key {
            if let oldId = server.credentialKeychainID {
                try? KeychainService.shared.deletePassword(id: oldId)
                server.credentialKeychainID = nil
            }
        }

        // Update SSH key if new one was selected
        if let keyData = sshKeyData {
            // Remove old key if exists
            if let oldKeyId = server.sshKeyKeychainID {
                try? KeychainService.shared.deleteSSHKey(id: oldKeyId)
            }
            let keyId = KeychainService.newCredentialID()
            try? KeychainService.shared.storeSSHKey(keyData, for: keyId)
            server.sshKeyKeychainID = keyId
        }

        // If auth method no longer needs key, clean up
        if authMethod == .password {
            if let oldKeyId = server.sshKeyKeychainID {
                try? KeychainService.shared.deleteSSHKey(id: oldKeyId)
                server.sshKeyKeychainID = nil
            }
        }

        dismiss()
    }

    private func selectKeyFile() {
        let panel = NSOpenPanel()
        panel.title = "Select SSH Private Key"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.showsHiddenFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                sshKeyData = data
                sshKeyFileName = url.lastPathComponent
            } catch {
                testResult = "Failed to read key: \(error.localizedDescription)"
            }
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            let testServer = Server(
                name: "test",
                hostname: hostname,
                port: Int(port) ?? 22,
                username: username,
                authMethod: authMethod
            )

            let tempId = "test-\(UUID().uuidString)"

            // Use new password if entered, otherwise use existing
            if !password.isEmpty {
                try? KeychainService.shared.storePassword(password, for: tempId)
                testServer.credentialKeychainID = tempId
            } else if let existingCredId = server.credentialKeychainID {
                testServer.credentialKeychainID = existingCredId
            }

            // Use new key if selected, otherwise use existing
            var keyTempId: String?
            if let keyData = sshKeyData {
                let id = "test-key-\(UUID().uuidString)"
                keyTempId = id
                try? KeychainService.shared.storeSSHKey(keyData, for: id)
                testServer.sshKeyKeychainID = id
            } else if let existingKeyId = server.sshKeyKeychainID {
                testServer.sshKeyKeychainID = existingKeyId
            }

            let testSession = SSHSession(server: testServer)

            do {
                try await testSession.connect()
                let output = try await testSession.execute("uname -a")
                await testSession.disconnect()
                await MainActor.run {
                    testResult = "Success: \(output.prefix(80))"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "Failed: \(error.localizedDescription)"
                    isTesting = false
                }
            }

            // Cleanup temp keychain items only
            if !password.isEmpty {
                try? KeychainService.shared.deletePassword(id: tempId)
            }
            if let keyTempId {
                try? KeychainService.shared.deleteSSHKey(id: keyTempId)
            }
        }
    }
}
