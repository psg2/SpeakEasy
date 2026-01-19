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

    @Published var transcriptionProvider: TranscriptionProvider {
        didSet {
            self.defaults.set(self.transcriptionProvider.rawValue, forKey: "transcription_provider")
        }
    }

    @Published var selectedWhisperModel: WhisperModel {
        didSet {
            self.defaults.set(self.selectedWhisperModel.rawValue, forKey: "selected_whisper_model")
            // Also update the model ID for consistency
            self.selectedModelId = self.selectedWhisperModel.whisperKitName
        }
    }

    /// The selected model ID (supports dynamic models from HuggingFace)
    @Published var selectedModelId: String {
        didSet {
            self.defaults.set(self.selectedModelId, forKey: "selected_model_id")
        }
    }

    /// Text snippets for replacement (key: snippet name, value: replacement text)
    @Published var snippets: [String: String] {
        didSet {
            self.defaults.set(try? JSONEncoder().encode(self.snippets), forKey: "text_snippets")
        }
    }

    /// Whisper prompt for context and custom words (improves transcription accuracy)
    @Published var whisperPrompt: String {
        didSet {
            self.defaults.set(self.whisperPrompt, forKey: "whisper_prompt")
        }
    }

    init() {
        self.apiKey = self.defaults.string(forKey: "openai_api_key") ?? ""
        // Default to Option (2048/0x800) + Space (49/0x31)
        self.shortcutKeyCode = self.defaults.object(forKey: "global_shortcut_key_code") as? Int ?? 49
        self.shortcutModifierFlags = self.defaults.object(forKey: "global_shortcut_modifier_flags") as? Int ?? 2048

        self.language = self.defaults.string(forKey: "transcription_language")
        self.recordingMode = self.defaults.string(forKey: "recording_mode") ?? "pressToToggle"

        if let providerRaw = self.defaults.string(forKey: "transcription_provider"),
           let provider = TranscriptionProvider(rawValue: providerRaw)
        {
            self.transcriptionProvider = provider
        } else {
            self.transcriptionProvider = .openAI
        }

        let whisperModel: WhisperModel = if let modelRaw = self.defaults.string(forKey: "selected_whisper_model"),
                                            let model = WhisperModel(rawValue: modelRaw)
        {
            model
        } else {
            .base
        }
        self.selectedWhisperModel = whisperModel

        // Load selected model ID (for dynamic models)
        if let modelId = self.defaults.string(forKey: "selected_model_id") {
            self.selectedModelId = modelId
        } else {
            self.selectedModelId = whisperModel.whisperKitName
        }

        // Load text snippets
        if let snippetsData = self.defaults.data(forKey: "text_snippets"),
           let snippets = try? JSONDecoder().decode([String: String].self, from: snippetsData)
        {
            self.snippets = snippets
        } else {
            self.snippets = [:]
        }

        // Load Whisper prompt
        self.whisperPrompt = self.defaults.string(forKey: "whisper_prompt") ?? ""
    }

    var hasApiKey: Bool {
        !self.apiKey.isEmpty
    }

    var isLocalWhisperReady: Bool {
        WhisperModelManager.isModelDownloadedSync(self.selectedModelId)
    }

    var canTranscribe: Bool {
        switch self.transcriptionProvider {
        case .openAI:
            self.hasApiKey
        case .localWhisper:
            self.isLocalWhisperReady
        }
    }

    /// Returns the current model name based on provider selection
    var currentModelName: String {
        switch self.transcriptionProvider {
        case .openAI:
            "whisper-1"
        case .localWhisper:
            self.selectedWhisperModel.displayName
        }
    }
}
