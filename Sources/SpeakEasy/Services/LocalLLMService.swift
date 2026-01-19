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

        // System prompt for transcription enrichment - very strict to avoid chatty responses
        let systemPrompt = """
        You are a text formatter. Fix punctuation and capitalization only. \
        Output ONLY the corrected text. No explanations. No translations. No commentary. \
        If the text is already correct, output it unchanged.
        """

        // Initialize LLM with ChatML template and limited token count
        llm = LLM(
            from: url,
            template: .chatML(systemPrompt),
            temp: 0.1, // Low temperature for more deterministic output
            maxTokenCount: 512 // Limit context to prevent runaway generation
        )

        currentModelPath = url.path

        let loadTime = CFAbsoluteTimeGetCurrent() - loadStart
        log.info("LLM model loaded in \(String(format: "%.2f", loadTime))s")
    }

    /// Enrich transcription with punctuation, capitalization, and error correction
    func enrichTranscription(_ text: String) async throws -> String {
        guard let llm else {
            throw LLMError.modelNotLoaded
        }

        log.info("[LLM] Input text: \"\(text)\"")
        let enrichStart = CFAbsoluteTimeGetCurrent()

        // Create prompt - direct instruction followed by the text
        let prompt = "Fix punctuation and capitalization:\n\n\(text)"
        log.info("[LLM] Full prompt: \"\(prompt)\"")

        // Get completion from LLM
        let result = await llm.getCompletion(from: prompt)
        log.info("[LLM] Raw LLM output: \"\(result)\"")

        let enrichTime = CFAbsoluteTimeGetCurrent() - enrichStart

        // Clean up result - remove any markdown, extra text, or repetition
        var enrichedText = result.trimmingCharacters(in: .whitespacesAndNewlines)
        log.info("[LLM] After trim: \"\(enrichedText)\"")

        // If result is empty, return original
        if enrichedText.isEmpty {
            log.warning("[LLM] Output is empty, using original text")
            return text
        }

        // If result is much longer than input, it's likely hallucinating - return original
        if enrichedText.count > text.count * 3 {
            log.warning("[LLM] Output too long (\(enrichedText.count) vs \(text.count)), using original")
            return text
        }

        // Detect repetition loops (same phrase repeated)
        if let repetition = detectRepetition(in: enrichedText) {
            log.warning("[LLM] Detected repetition loop: \"\(repetition)\", using original")
            return text
        }

        // Remove common LLM response patterns
        if enrichedText.lowercased().hasPrefix("here") ||
            enrichedText.lowercased().hasPrefix("the corrected") ||
            enrichedText.lowercased().hasPrefix("corrected:")
        {
            log.info("[LLM] Detected chatty prefix, extracting text after colon")
            // Try to extract just the actual text after common prefixes
            if let colonIndex = enrichedText.firstIndex(of: ":") {
                let afterColon = enrichedText[enrichedText.index(after: colonIndex)...]
                enrichedText = afterColon.trimmingCharacters(in: .whitespacesAndNewlines)
                log.info("[LLM] After prefix removal: \"\(enrichedText)\"")
            }
        }

        // Remove markdown bold markers
        if enrichedText.contains("**") {
            enrichedText = enrichedText.replacingOccurrences(of: "**", with: "")
            log.info("[LLM] Removed markdown: \"\(enrichedText)\"")
        }

        log.info("[LLM] Final output: \"\(enrichedText)\" (took \(String(format: "%.2f", enrichTime))s)")

        return enrichedText
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

    // MARK: - Private Helpers

    /// Detect if text contains repetitive phrases (sign of LLM loop)
    private func detectRepetition(in text: String) -> String? {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard words.count >= 6 else { return nil }

        // Check for repeated sequences of 2-5 words
        for windowSize in 2 ... 5 {
            var sequenceCounts: [String: Int] = [:]

            for i in 0 ..< (words.count - windowSize + 1) {
                let sequence = words[i ..< i + windowSize].joined(separator: " ")
                sequenceCounts[sequence, default: 0] += 1
            }

            // If any sequence appears more than 3 times, it's likely a loop
            for (sequence, count) in sequenceCounts where count > 3 {
                return sequence
            }
        }

        return nil
    }
}
