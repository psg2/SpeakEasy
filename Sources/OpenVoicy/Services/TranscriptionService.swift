import Foundation

enum TranscriptionError: LocalizedError {
    case invalidApiKey
    case fileTooLarge
    case fileTooShort
    case networkError(String)
    case apiError(String)
    case invalidResponse
    case encodingError
    case modelNotReady
    case localWhisperError(String)

    var errorDescription: String? {
        switch self {
        case .invalidApiKey:
            "Invalid or missing API key"
        case .fileTooLarge:
            "Audio file too large (max 25MB for OpenAI)"
        case .fileTooShort:
            "Audio recording too short"
        case let .networkError(msg):
            "Network error: \(msg)"
        case let .apiError(msg):
            "API error: \(msg)"
        case .invalidResponse:
            "Invalid response from server"
        case .encodingError:
            "Failed to encode audio"
        case .modelNotReady:
            "Whisper model not downloaded"
        case let .localWhisperError(msg):
            "Local Whisper error: \(msg)"
        }
    }

    init(from openAIError: OpenAIError) {
        switch openAIError {
        case .invalidApiKey:
            self = .invalidApiKey
        case .fileTooLarge:
            self = .fileTooLarge
        case .fileTooShort:
            self = .fileTooShort
        case let .networkError(msg):
            self = .networkError(msg)
        case let .apiError(msg):
            self = .apiError(msg)
        case .invalidResponse:
            self = .invalidResponse
        case .encodingError:
            self = .encodingError
        }
    }
}

class TranscriptionService {
    static let shared = TranscriptionService()

    private let settings = SettingsManager.shared
    private let openAIClient = OpenAIClient.shared

    func transcribe(audioFileURL: URL, language: String? = nil) async throws -> String {
        switch self.settings.transcriptionProvider {
        case .openAI:
            try await self.transcribeWithOpenAI(audioFileURL: audioFileURL, language: language)
        case .localWhisper:
            try await self.transcribeWithLocalWhisper(audioFileURL: audioFileURL, language: language)
        }
    }

    // MARK: - Local Whisper Transcription

    private func transcribeWithLocalWhisper(audioFileURL: URL, language: String?) async throws -> String {
        guard self.settings.isLocalWhisperReady else {
            throw TranscriptionError.modelNotReady
        }

        do {
            return try await LocalWhisperService.shared.transcribe(
                audioFileURL: audioFileURL,
                language: language)
        } catch let error as LocalWhisperError {
            throw TranscriptionError.localWhisperError(error.localizedDescription)
        } catch {
            throw TranscriptionError.localWhisperError(error.localizedDescription)
        }
    }

    // MARK: - OpenAI API Transcription

    private func transcribeWithOpenAI(audioFileURL: URL, language: String?) async throws -> String {
        guard let apiKey = self.settings.apiKey as String?, !apiKey.isEmpty else {
            throw TranscriptionError.invalidApiKey
        }

        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            throw TranscriptionError.encodingError
        }

        do {
            return try await self.openAIClient.transcribe(
                audioData: audioData,
                language: language,
                apiKey: apiKey)
        } catch let error as OpenAIError {
            throw TranscriptionError(from: error)
        }
    }
}
