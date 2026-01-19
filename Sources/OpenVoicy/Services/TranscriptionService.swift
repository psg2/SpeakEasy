import Foundation

private let log = FileLogger.shared

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
        let result = try await self.transcribeWithSnippets(audioFileURL: audioFileURL, language: language)
        return result.processedText
    }

    func transcribeWithSnippets(
        audioFileURL: URL,
        language: String? = nil) async throws -> (rawText: String, processedText: String)
    {
        let rawText: String = switch self.settings.transcriptionProvider {
        case .openAI:
            try await self.transcribeWithOpenAI(audioFileURL: audioFileURL, language: language)
        case .localWhisper:
            try await self.transcribeWithLocalWhisper(audioFileURL: audioFileURL, language: language)
        }

        var processedText = self.applySnippetReplacements(rawText)

        // Apply LLM enrichment if enabled and model is ready
        if self.settings.llmEnrichmentEnabled, self.settings.isLLMReady {
            processedText = try await self.enrichWithLLM(processedText)
        }

        return (rawText, processedText)
    }

    func applySnippetReplacements(_ text: String) -> String {
        guard !self.settings.snippets.isEmpty else {
            return text
        }

        var processedText = text

        for (snippetKey, snippetValue) in self.settings.snippets {
            let pattern = NSRegularExpression.escapedPattern(for: snippetKey)
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(processedText.startIndex..., in: processedText)
                processedText = regex.stringByReplacingMatches(
                    in: processedText,
                    range: range,
                    withTemplate: snippetValue)
            }
        }

        return processedText
    }

    // MARK: - LLM Enrichment

    private func enrichWithLLM(_ text: String) async throws -> String {
        log.info("Starting LLM enrichment...")

        do {
            // Get model file path
            let modelURL = await LLMModelManager.shared.modelPath(for: self.settings.selectedLLMModel)

            // Load the model if needed
            try await LocalLLMService.shared.loadModel(from: modelURL)

            // Enrich the transcription
            let enrichedText = try await LocalLLMService.shared.enrichTranscription(text)

            log.info("LLM enrichment completed successfully")
            return enrichedText
        } catch {
            log.warning("LLM enrichment failed, using original text: \(error.localizedDescription)")
            // Fallback to original text if enrichment fails
            return text
        }
    }

    // MARK: - Local Whisper Transcription

    private func transcribeWithLocalWhisper(audioFileURL: URL, language: String?) async throws -> String {
        guard self.settings.isLocalWhisperReady else {
            throw TranscriptionError.modelNotReady
        }

        let prompt = self.settings.whisperPrompt.isEmpty ? nil : self.settings.whisperPrompt

        do {
            return try await LocalWhisperService.shared.transcribe(
                audioFileURL: audioFileURL,
                language: language,
                prompt: prompt)
        } catch {
            throw TranscriptionError.localWhisperError(error.localizedDescription)
        }
    }

    // MARK: - OpenAI API Transcription

    private func transcribeWithOpenAI(audioFileURL: URL, language: String?) async throws -> String {
        guard !self.settings.apiKey.isEmpty else {
            throw TranscriptionError.invalidApiKey
        }

        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            throw TranscriptionError.encodingError
        }

        let prompt = self.settings.whisperPrompt.isEmpty ? nil : self.settings.whisperPrompt

        do {
            return try await self.openAIClient.transcribe(
                audioData: audioData,
                language: language,
                prompt: prompt,
                apiKey: self.settings.apiKey)
        } catch let error as OpenAIError {
            throw TranscriptionError(from: error)
        }
    }
}
