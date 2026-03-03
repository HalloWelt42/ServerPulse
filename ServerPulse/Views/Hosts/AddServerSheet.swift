import SwiftUI
import SwiftData

struct AddServerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc

    @State private var name = ""
    @State private var hostname = ""
    @State private var port = "22"
    @State private var username = "pi"
    @State private var authMethod: Server.AuthMethod = .password
    @State private var password = ""
    @State private var showPassword = false
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
                    .foregroundStyle(AppTheme.textSecondary)
                    .handCursorOnHover()

                Spacer()

                Text(loc["add_server.title"])
                    .font(.system(size: AppTheme.scaled(15), weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Button(loc["add_server.save"]) { saveServer() }
                    .keyboardShortcut(.return)
                    .foregroundStyle(isFormValid ? AppTheme.buttonPrimary : AppTheme.textMuted)
                    .fontWeight(.bold)
                    .disabled(!isFormValid)
                    .handCursorOnHover()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.surfacePrimary)

            Divider().overlay(AppTheme.border)

            // Form rows
            ScrollView {
                VStack(spacing: 0) {
                    // Connection section
                    sectionHeader(loc["add_server.section.connection"])

                    formRow(label: loc["add_server.name"]) {
                        TextField(loc["add_server.placeholder.name"], text: $name)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.textPrimary)
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
                                .foregroundStyle(AppTheme.textPrimary)
                                .onChange(of: hostname) { _, val in
                                    hostname = val.filter { !$0.isWhitespace }
                                    if hostname.count > 253 { hostname = String(hostname.prefix(253)) }
                                }

                            Text(":")
                                .foregroundStyle(AppTheme.textMuted)

                            TextField("22", text: $port)
                                .textFieldStyle(.plain)
                                .frame(width: 44)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(portNumber >= 1 && portNumber <= 65535 || port.isEmpty ? AppTheme.textPrimary : AppTheme.statusOffline)
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
                            .foregroundStyle(AppTheme.textPrimary)
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

                    if authMethod == .password || authMethod == .keyAndPassword {
                        formDivider()

                        formRow(label: authMethod == .password ? loc["add_server.password"] : loc["add_server.passphrase"]) {
                            HStack(spacing: 8) {
                                if showPassword {
                                    TextField(loc["add_server.placeholder.password"], text: $password)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(AppTheme.textPrimary)
                                } else {
                                    SecureField(loc["add_server.placeholder.password"], text: $password)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(AppTheme.textPrimary)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(AppTheme.textMuted)
                                        .font(.system(size: AppTheme.scaled(13)))
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
                            .tint(AppTheme.buttonPrimary)
                    }

                    // Test connection section
                    if let testResult {
                        sectionHeader(loc["add_server.section.status"])

                        HStack {
                            Image(systemName: testResult.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(testResult.contains("Success") ? AppTheme.statusOnline : AppTheme.statusOffline)
                            Text(testResult)
                                .font(.system(size: AppTheme.scaled(13)))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppTheme.surfacePrimary)
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
        .background(AppTheme.background)
    }

    // MARK: - Form Components

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: AppTheme.scaled(11), weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: AppTheme.scaled(14), weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surfacePrimary)
    }

    @ViewBuilder
    private func formDivider() -> some View {
        Divider()
            .overlay(AppTheme.border)
            .padding(.leading, 16)
    }

    // MARK: - Actions

    private func saveServer() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let server = Server(
            name: trimmedName.isEmpty ? hostname : trimmedName,
            hostname: hostname.trimmingCharacters(in: .whitespaces),
            port: portNumber > 0 ? portNumber : 22,
            username: username.trimmingCharacters(in: .whitespaces),
            authMethod: authMethod,
            dockerEnabled: dockerEnabled
        )
        server.pollingInterval = Double(pollingInterval) ?? 5

        if !password.isEmpty {
            let credId = KeychainService.newCredentialID()
            try? KeychainService.shared.storePassword(password, for: credId)
            server.credentialKeychainID = credId
        }

        modelContext.insert(server)
        dismiss()
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

            if !password.isEmpty {
                let tempId = "test-\(UUID().uuidString)"
                try? KeychainService.shared.storePassword(password, for: tempId)
                testServer.credentialKeychainID = tempId
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
        }
    }
}
