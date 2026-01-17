import Combine
import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    @Published var apiKey: String {
        didSet {
            self.defaults.set(self.apiKey, forKey: "openai_api_key")
        }
    }

    @Published var shortcutKeyCode: Int {
        didSet {
            self.defaults.set(self.shortcutKeyCode, forKey: "global_shortcut_key_code")
        }
    }

    @Published var shortcutModifierFlags: Int {
        didSet {
            self.defaults.set(self.shortcutModifierFlags, forKey: "global_shortcut_modifier_flags")
        }
    }

    @Published var language: String? {
        didSet {
            self.defaults.set(self.language, forKey: "transcription_language")
        }
    }

    @Published var recordingMode: String {
        didSet {
            self.defaults.set(self.recordingMode, forKey: "recording_mode")
        }
    }

    init() {
        self.apiKey = self.defaults.string(forKey: "openai_api_key") ?? ""
        // Default to Option (2048/0x800) + Space (49/0x31)
        self.shortcutKeyCode = self.defaults.object(forKey: "global_shortcut_key_code") as? Int ?? 49
        self.shortcutModifierFlags = self.defaults.object(forKey: "global_shortcut_modifier_flags") as? Int ?? 2048

        self.language = self.defaults.string(forKey: "transcription_language")
        self.recordingMode = self.defaults.string(forKey: "recording_mode") ?? "pressToToggle"
    }

    var hasApiKey: Bool {
        !self.apiKey.isEmpty
    }
}
