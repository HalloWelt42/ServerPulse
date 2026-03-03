import Foundation
import Observation

@MainActor
@Observable
final class LocalizationManager {

    static let shared = LocalizationManager()

    // MARK: - Public State

    private(set) var currentLanguage: String = "en"
    private(set) var availableLanguages: [LanguageInfo] = []

    struct LanguageInfo: Identifiable, Hashable {
        let id: String
        let displayName: String
        let nativeName: String
        let isBuiltIn: Bool
    }

    // MARK: - Private

    private var translations: [String: String] = [:]
    private var fallbackTranslations: [String: String] = [:]

    // MARK: - Init

    private init() {
        scanLanguages()
        fallbackTranslations = loadJSON(for: "en")

        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        if availableLanguages.contains(where: { $0.id == saved }) {
            currentLanguage = saved
        }
        translations = loadJSON(for: currentLanguage)
    }

    // MARK: - Language Switching

    func setLanguage(_ code: String) {
        guard availableLanguages.contains(where: { $0.id == code }) else { return }
        currentLanguage = code
        translations = loadJSON(for: code)
        UserDefaults.standard.set(code, forKey: "appLanguage")
    }

    // MARK: - String Lookup

    subscript(_ key: String) -> String {
        translations[key] ?? fallbackTranslations[key] ?? key
    }

    func string(_ key: String, _ args: any CVarArg...) -> String {
        let template = self[key]
        return String(format: template, arguments: args)
    }

    // MARK: - Scan

    func scanLanguages() {
        var found: [LanguageInfo] = []

        // Bundle resources
        if let bundleURLs = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Localization") {
            for url in bundleURLs {
                let code = url.deletingPathExtension().lastPathComponent
                if code.hasPrefix("_") { continue }
                if let info = parseLanguageInfo(from: url, code: code, isBuiltIn: true) {
                    found.append(info)
                }
            }
        }

        // External user-added languages
        let extDir = Self.externalLocalizationDirectory
        if FileManager.default.fileExists(atPath: extDir.path) {
            let extFiles = (try? FileManager.default.contentsOfDirectory(
                at: extDir, includingPropertiesForKeys: nil
            )) ?? []
            for url in extFiles where url.pathExtension == "json" {
                let code = url.deletingPathExtension().lastPathComponent
                if found.contains(where: { $0.id == code }) { continue }
                if let info = parseLanguageInfo(from: url, code: code, isBuiltIn: false) {
                    found.append(info)
                }
            }
        }

        availableLanguages = found.sorted { $0.nativeName < $1.nativeName }
    }

    // MARK: - Paths

    static var externalLocalizationDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ServerPulse/Localization", isDirectory: true)
    }

    // MARK: - Helpers

    private func loadJSON(for code: String) -> [String: String] {
        // Bundle first
        if let url = Bundle.module.url(forResource: code, withExtension: "json", subdirectory: "Localization") {
            return parseTranslations(from: url)
        }
        // External
        let extURL = Self.externalLocalizationDirectory.appendingPathComponent("\(code).json")
        if FileManager.default.fileExists(atPath: extURL.path) {
            return parseTranslations(from: extURL)
        }
        return [:]
    }

    private func parseTranslations(from url: URL) -> [String: String] {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        var result: [String: String] = [:]
        for (key, value) in json where !key.hasPrefix("_") {
            if let str = value as? String { result[key] = str }
        }
        return result
    }

    private func parseLanguageInfo(from url: URL, code: String, isBuiltIn: Bool) -> LanguageInfo? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let meta = json["_meta"] as? [String: Any] else {
            return nil
        }
        return LanguageInfo(
            id: code,
            displayName: meta["displayName"] as? String ?? code,
            nativeName: meta["nativeDisplayName"] as? String ?? code,
            isBuiltIn: isBuiltIn
        )
    }
}
