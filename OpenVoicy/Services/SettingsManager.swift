import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    @Published var apiKey: String {
        didSet {
            defaults.set(apiKey, forKey: "openai_api_key")
        }
    }

    @Published var shortcutKeyCode: Int {
        didSet {
            defaults.set(shortcutKeyCode, forKey: "global_shortcut_key_code")
        }
    }

    @Published var shortcutModifierFlags: Int {
        didSet {
            defaults.set(shortcutModifierFlags, forKey: "global_shortcut_modifier_flags")
        }
    }

    @Published var language: String? {
        didSet {
            defaults.set(language, forKey: "transcription_language")
        }
    }

    @Published var recordingMode: String {
        didSet {
            defaults.set(recordingMode, forKey: "recording_mode")
        }
    }

    init() {
        self.apiKey = defaults.string(forKey: "openai_api_key") ?? ""
        // Default to Option (2048/0x800) + Space (49/0x31)
        self.shortcutKeyCode = defaults.object(forKey: "global_shortcut_key_code") as? Int ?? 49
        self.shortcutModifierFlags = defaults.object(forKey: "global_shortcut_modifier_flags") as? Int ?? 2048

        self.language = defaults.string(forKey: "transcription_language")
        self.recordingMode = defaults.string(forKey: "recording_mode") ?? "pressToToggle"
    }

    var hasApiKey: Bool {
        return !apiKey.isEmpty
    }
}
