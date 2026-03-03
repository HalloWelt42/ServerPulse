import SwiftUI

struct GuideView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(LocalizationManager.self) private var loc
    @State private var showLicense = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // App Header
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .font(.system(size: theme.scaled(48)))
                        .foregroundStyle(theme.buttonPrimary)

                    Text("ServerPulse")
                        .font(.system(size: theme.scaled(28), weight: .bold))
                        .foregroundStyle(theme.textPrimary)

                    Text("v\(AppVersion.current)")
                        .font(.system(size: theme.scaled(13), weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.textMuted)

                    Text(loc["guide.tagline"])
                        .font(.system(size: theme.scaled(15)))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 500)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

                Divider().overlay(theme.border).padding(.horizontal, 24)

                // Features Section
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(loc["guide.features_title"], icon: "sparkles")

                    featureRow(icon: "server.rack", color: theme.buttonPrimary, title: loc["guide.feature.monitoring"], desc: loc["guide.feature.monitoring_desc"])
                    featureRow(icon: "terminal.fill", color: theme.statusOnline, title: loc["guide.feature.terminal"], desc: loc["guide.feature.terminal_desc"])
                    featureRow(icon: "shippingbox.fill", color: theme.statusWarning, title: loc["guide.feature.docker"], desc: loc["guide.feature.docker_desc"])
                    featureRow(icon: "play.circle.fill", color: theme.cachedColor, title: loc["guide.feature.execute"], desc: loc["guide.feature.execute_desc"])
                    featureRow(icon: "key.fill", color: theme.textMuted, title: loc["guide.feature.keychain"], desc: loc["guide.feature.keychain_desc"])
                    featureRow(icon: "globe", color: theme.buttonPrimary, title: loc["guide.feature.languages"], desc: loc["guide.feature.languages_desc"])
                }
                .padding(.horizontal, 32)

                Divider().overlay(theme.border).padding(.horizontal, 24)

                // Privacy & Security
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(loc["guide.privacy_title"], icon: "lock.shield.fill")

                    privacyRow(icon: "eye.slash.fill", text: loc["guide.privacy.no_tracking"])
                    privacyRow(icon: "megaphone.fill", text: loc["guide.privacy.no_ads"])
                    privacyRow(icon: "arrow.up.right.square", text: loc["guide.privacy.no_telemetry"])
                    privacyRow(icon: "lock.open.fill", text: loc["guide.privacy.open_source"])
                    privacyRow(icon: "externaldrive.fill", text: loc["guide.privacy.local_data"])
                }
                .padding(.horizontal, 32)

                Divider().overlay(theme.border).padding(.horizontal, 24)

                // License Section
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLicense.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: theme.scaled(14)))
                                .foregroundStyle(theme.buttonPrimary)
                            Text(loc["guide.license_title"])
                                .font(.system(size: theme.scaled(16), weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            Image(systemName: showLicense ? "chevron.up" : "chevron.down")
                                .font(.system(size: theme.scaled(12), weight: .semibold))
                                .foregroundStyle(theme.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                    .handCursorOnHover()

                    if showLicense {
                        licenseText
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 32)
            }
        }
        .background(theme.background)
    }

    // MARK: - Components

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: theme.scaled(16)))
                .foregroundStyle(theme.buttonPrimary)
            Text(title)
                .font(.system(size: theme.scaled(18), weight: .bold))
                .foregroundStyle(theme.textPrimary)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: theme.scaled(18)))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: theme.scaled(14), weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text(desc)
                    .font(.system(size: theme.scaled(12)))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func privacyRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: theme.scaled(13)))
                .foregroundStyle(theme.statusOnline)
                .frame(width: 20)
            Text(text)
                .font(.system(size: theme.scaled(13)))
                .foregroundStyle(theme.textSecondary)
        }
    }

    // MARK: - License Text

    private var licenseText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ServerPulse Non-Commercial License v1.0")
                .font(.system(size: theme.scaled(14), weight: .bold))
                .foregroundStyle(theme.textPrimary)

            Text("""
Based on Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)

Copyright (c) 2025 HalloWelt42

1. GRANT OF LICENSE
This software is provided free of charge for personal, educational, and non-commercial use. You may install and use this software on any number of devices you personally own.

2. RESTRICTIONS
You may NOT:
- Use this software for any commercial purpose
- Sell, sublicense, or redistribute this software
- Modify, adapt, or create derivative works
- Reverse engineer, decompile, or disassemble this software
- Remove or alter any copyright notices or branding

3. DISCLAIMER OF WARRANTY
THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

4. LIMITATION OF LIABILITY
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

5. DATA & PRIVACY
This software does not collect, transmit, or store any user data externally. All data remains on your local device. No analytics, tracking, or telemetry of any kind is included.

6. THIRD-PARTY COMPONENTS
This software uses open-source libraries under their respective licenses (MIT, Apache 2.0). These components are subject to their own license terms.

7. TERMINATION
This license is effective until terminated. It will terminate automatically if you fail to comply with any term. Upon termination, you must destroy all copies of the software.

For the full CC BY-NC-ND 4.0 license text, visit:
https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode
""")
                .font(.system(size: theme.scaled(11)))
                .foregroundStyle(theme.textSecondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(theme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}
