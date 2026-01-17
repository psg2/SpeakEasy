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

    @Published var shortcut: String {
        didSet {
            defaults.set(shortcut, forKey: "global_shortcut")
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
        self.shortcut = defaults.string(forKey: "global_shortcut") ?? "Option+Space"
        self.language = defaults.string(forKey: "transcription_language")
        self.recordingMode = defaults.string(forKey: "recording_mode") ?? "pressToToggle"
    }

    var hasApiKey: Bool {
        return !apiKey.isEmpty
    }
}
