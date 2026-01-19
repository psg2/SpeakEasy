import Foundation
import LLM

private let log = FileLogger.shared

enum LLMError: LocalizedError {
    case modelNotLoaded
    case modelNotFound(String)
    case modelLoadFailed(String)
    case inferenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            "LLM model not loaded"
        case let .modelNotFound(path):
            "Model file not found: \(path)"
        case let .modelLoadFailed(modelId):
            "Failed to load model: \(modelId)"
        case let .inferenceFailed(message):
            "Inference failed: \(message)"
        }
    }
}

class LocalLLMService {
    static let shared = LocalLLMService()

    private var llm: LLM?
    private var currentModelPath: String?

    private init() {}

    /// Load LLM model from local GGUF file
    func loadModel(from url: URL) async throws {
        // Return early if model is already loaded
        if currentModelPath == url.path, llm != nil {
            log.info("LLM model already loaded: \(url.lastPathComponent)")
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw LLMError.modelNotFound(url.path)
        }

        log.info("Loading LLM model: \(url.lastPathComponent)")
        let loadStart = CFAbsoluteTimeGetCurrent()

        // Unload existing model first
        unloadModel()

        // System prompt for transcription enrichment
        let systemPrompt = """
        You are a transcription editor. Your task is to fix spelling errors, add proper \
        punctuation and capitalization to transcriptions. Preserve the original words and \
        meaning. Only correct obvious errors. Do not add or remove content. Output only \
        the corrected text without explanations.
        """

        // Initialize LLM with ChatML template
        llm = LLM(from: url, template: .chatML(systemPrompt))

        currentModelPath = url.path

        let loadTime = CFAbsoluteTimeGetCurrent() - loadStart
        log.info("LLM model loaded in \(String(format: "%.2f", loadTime))s")
    }

    /// Enrich transcription with punctuation, capitalization, and error correction
    func enrichTranscription(_ text: String) async throws -> String {
        guard let llm else {
            throw LLMError.modelNotLoaded
        }

        log.info("Starting LLM enrichment...")
        let enrichStart = CFAbsoluteTimeGetCurrent()

        // Create prompt for transcription enrichment
        let prompt = "Correct this transcription: \(text)"

        do {
            // Get completion from LLM
            let result = await llm.getCompletion(from: prompt)

            let enrichTime = CFAbsoluteTimeGetCurrent() - enrichStart
            let enrichedText = result.trimmingCharacters(in: .whitespacesAndNewlines)

            log.info("LLM enrichment completed in \(String(format: "%.2f", enrichTime))s")
            log.info("Generated \(enrichedText.count) characters")

            return enrichedText
        }
    }

    /// Unload the current model to free memory
    func unloadModel() {
        llm = nil
        currentModelPath = nil
        log.info("LLM model unloaded")
    }

    /// Check if a model is currently loaded
    var isModelLoaded: Bool {
        llm != nil
    }

    /// Get the currently loaded model path
    var loadedModelPath: String? {
        currentModelPath
    }
}
