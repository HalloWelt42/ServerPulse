import SwiftUI

struct DonationView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(LocalizationManager.self) private var loc
    @State private var selectedCrypto: CryptoOption? = nil
    @State private var copiedAddress: String? = nil
    @State private var heartBeat = false

    private let donationRed = Color(red: 0.9, green: 0.15, blue: 0.2)
    private let donationRedLight = Color(red: 1.0, green: 0.3, blue: 0.35)

    enum CryptoOption: String, CaseIterable, Identifiable {
        case bitcoin = "btc"
        case dogecoin = "doge"
        case ethereum = "eth"

        var id: String { rawValue }

        var address: String {
            switch self {
            case .bitcoin: return "bc1qnd599khdkv3v3npmj9ufxzf6h4fzanny2acwqr"
            case .dogecoin: return "DL7tuiYCqm3xQjMDXChdxeQxqUGMACn1ZV"
            case .ethereum: return "0x8A28fc47bFFFA03C8f685fa0836E2dBe1CA14F27"
            }
        }

        var displayName: String {
            switch self {
            case .bitcoin: return "Bitcoin"
            case .dogecoin: return "Dogecoin"
            case .ethereum: return "Ethereum"
            }
        }

        var icon: String {
            switch self {
            case .bitcoin: return "bitcoinsign.circle.fill"
            case .dogecoin: return "d.circle.fill"
            case .ethereum: return "e.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .bitcoin: return Color(red: 0.96, green: 0.65, blue: 0.14)    // #F5A623 Bitcoin orange
            case .dogecoin: return Color(red: 0.78, green: 0.60, blue: 0.24)   // #C69A3C Doge gold
            case .ethereum: return Color(red: 0.39, green: 0.46, blue: 0.81)   // #6476CF Ethereum blue
            }
        }

        var qrFileName: String {
            "\(rawValue)-qr"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Heart-decorated support banner
                supportBanner
                    .padding(.horizontal, 48)
                    .padding(.top, 36)

                VStack(spacing: 32) {
                    // Open Source badge
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: theme.scaled(12)))
                            .foregroundStyle(theme.statusOnline)
                        Text(loc["donate.open_source_badge"])
                            .font(.system(size: theme.scaled(12), weight: .medium))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.statusOnline.opacity(0.08))
                    .clipShape(Capsule())

                    // Ko-fi Button
                    Button {
                        if let url = URL(string: "https://ko-fi.com/HalloWelt42") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: theme.scaled(18)))
                            Text(loc["donate.kofi_button"])
                                .font(.system(size: theme.scaled(16), weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [theme.buttonPrimary, theme.buttonPrimaryHover],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: theme.buttonPrimary.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .handCursorOnHover()

                    // GitHub Open Source link
                    Button {
                        if let url = URL(string: "https://github.com/HalloWelt42/ServerPulse") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: theme.scaled(14)))
                            Text(loc["donate.github_button"])
                                .font(.system(size: theme.scaled(13), weight: .semibold))
                        }
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(theme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .handCursorOnHover()

                    Divider()
                        .overlay(theme.border)
                        .padding(.horizontal, 60)

                    // Crypto Section
                    VStack(spacing: 20) {
                        Text(loc["donate.crypto_title"])
                            .font(.system(size: theme.scaled(18), weight: .semibold))
                            .foregroundStyle(theme.textPrimary)

                        // Crypto buttons
                        HStack(spacing: 14) {
                            ForEach(CryptoOption.allCases) { crypto in
                                cryptoButton(crypto)
                            }
                        }

                        // QR Code & Address display
                        if let selected = selectedCrypto {
                            VStack(spacing: 16) {
                                // QR Code from SVG
                                qrCodeView(for: selected)

                                // Address
                                VStack(spacing: 10) {
                                    Text(selected.address)
                                        .font(.system(size: theme.scaled(12), design: .monospaced))
                                        .foregroundStyle(theme.textSecondary)
                                        .textSelection(.enabled)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(maxWidth: 360)

                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(selected.address, forType: .string)
                                        copiedAddress = selected.rawValue
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            if copiedAddress == selected.rawValue {
                                                copiedAddress = nil
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: copiedAddress == selected.rawValue ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: theme.scaled(12)))
                                            Text(copiedAddress == selected.rawValue ? loc["donate.copied"] : loc["donate.copy_address"])
                                                .font(.system(size: theme.scaled(12), weight: .semibold))
                                        }
                                        .foregroundStyle(copiedAddress == selected.rawValue ? theme.statusOnline : theme.buttonPrimary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 9)
                                        .background(
                                            copiedAddress == selected.rawValue
                                                ? theme.statusOnline.opacity(0.1)
                                                : theme.buttonPrimary.opacity(0.1)
                                        )
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .handCursorOnHover()
                                }
                            }
                            .padding(24)
                            .background(theme.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .animation(.easeInOut(duration: 0.2), value: selectedCrypto)
                        }
                    }
                    .frame(maxWidth: 500)

                    Spacer().frame(height: 32)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
                .padding(.horizontal, 48)
            }
        }
        .background(theme.background)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                heartBeat = true
            }
        }
    }

    // MARK: - Support Banner (Red, Hearts, Framed)

    private var supportBanner: some View {
        VStack(spacing: 18) {
            // Floating hearts row
            HStack(spacing: 0) {
                floatingHeart(size: 12, offset: -4)
                Spacer()
                floatingHeart(size: 16, offset: 2)
                Spacer()
                floatingHeart(size: 10, offset: -6)
                Spacer()
                floatingHeart(size: 14, offset: 4)
                Spacer()
                floatingHeart(size: 12, offset: -2)
            }
            .padding(.horizontal, 20)

            // Main header with hearts
            HStack(spacing: 14) {
                Image(systemName: "heart.fill")
                    .font(.system(size: theme.scaled(24)))
                    .foregroundStyle(.white.opacity(0.9))
                    .scaleEffect(heartBeat ? 1.15 : 0.95)

                VStack(spacing: 6) {
                    Text(loc["donate.title"])
                        .font(.system(size: theme.scaled(26), weight: .bold))
                        .foregroundStyle(.white)

                    Text(loc["donate.subtitle"])
                        .font(.system(size: theme.scaled(13)))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                }

                Image(systemName: "heart.fill")
                    .font(.system(size: theme.scaled(24)))
                    .foregroundStyle(.white.opacity(0.9))
                    .scaleEffect(heartBeat ? 0.95 : 1.15)
            }

            // "Made with love" badge
            HStack(spacing: 6) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: theme.scaled(14)))
                    .foregroundStyle(.white)
                Text(loc["donate.made_with_love"])
                    .font(.system(size: theme.scaled(13), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(.white.opacity(0.15))
            .clipShape(Capsule())

            // Floating hearts row (bottom)
            HStack(spacing: 0) {
                floatingHeart(size: 10, offset: 3)
                Spacer()
                floatingHeart(size: 14, offset: -5)
                Spacer()
                floatingHeart(size: 12, offset: 2)
                Spacer()
                floatingHeart(size: 10, offset: -3)
                Spacer()
                floatingHeart(size: 16, offset: 5)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        donationRed.opacity(0.85),
                        Color(red: 0.7, green: 0.1, blue: 0.15).opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle pattern overlay
                Color.white.opacity(0.03)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [donationRedLight.opacity(0.8), donationRed.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: donationRed.opacity(0.3), radius: 12, y: 6)
    }

    private func floatingHeart(size: CGFloat, offset: CGFloat) -> some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(.white.opacity(heartBeat ? 0.5 : 0.2))
            .offset(y: heartBeat ? offset : -offset)
    }

    // MARK: - Crypto Button

    private func cryptoButton(_ crypto: CryptoOption) -> some View {
        let isSelected = selectedCrypto == crypto

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCrypto = selectedCrypto == crypto ? nil : crypto
            }
            copiedAddress = nil
        } label: {
            HStack(spacing: 8) {
                Image(systemName: crypto.icon)
                    .font(.system(size: theme.scaled(16)))
                    .foregroundStyle(crypto.color)
                Text(crypto.displayName)
                    .font(.system(size: theme.scaled(13), weight: .semibold))
                    .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isSelected ? crypto.color.opacity(0.15) : theme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? crypto.color.opacity(0.5) : theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .handCursorOnHover()
    }

    // MARK: - QR Code View

    @ViewBuilder
    private func qrCodeView(for crypto: CryptoOption) -> some View {
        if let svgURL = Bundle.module.url(forResource: crypto.qrFileName, withExtension: "svg", subdirectory: "QRCodes"),
           let image = NSImage(contentsOf: svgURL) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // Fallback if SVG can't be loaded
            VStack(spacing: 8) {
                Image(systemName: "qrcode")
                    .font(.system(size: 80))
                    .foregroundStyle(theme.textTertiary)
                Text(loc["donate.qr_unavailable"])
                    .font(.system(size: theme.scaled(11)))
                    .foregroundStyle(theme.textTertiary)
            }
            .frame(width: 200, height: 200)
            .background(theme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
