import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Hub

enum LLMError: LocalizedError {
    case modelNotLoaded
    case modelLoadFailed(String)
    case inferenceFailed(String)
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            "LLM model not loaded"
        case let .modelLoadFailed(modelId):
            "Failed to load model: \(modelId)"
        case let .inferenceFailed(message):
            "Inference failed: \(message)"
        case .invalidConfiguration:
            "Invalid model configuration"
        }
    }
}

class LocalLLMService {
    static let shared = LocalLLMService()

    private var modelContainer: ModelContainer?
    private var currentModelId: String?
    private let queue = DispatchQueue(label: "com.openvoicy.llm", qos: .userInitiated)

    private init() {}

    /// Load LLM model from HuggingFace
    func loadModel(_ modelId: String) async throws {
        // Return early if model is already loaded
        if currentModelId == modelId, modelContainer != nil {
            log.info("LLM model already loaded: \(modelId)")
            return
        }

        log.info("Loading LLM model: \(modelId)")
        let loadStart = CFAbsoluteTimeGetCurrent()

        do {
            // Create hub API client
            let hub = HubApi()

            // Get model configuration
            let modelConfiguration = ModelConfiguration.defaultModel(id: modelId)

            // Load model container (downloads if needed)
            modelContainer = try await ModelContainer.from(
                configuration: modelConfiguration,
                hub: hub
            )

            currentModelId = modelId

            let loadTime = CFAbsoluteTimeGetCurrent() - loadStart
            log.info("LLM model loaded successfully in \(String(format: "%.2f", loadTime))s: \(modelId)")
        } catch {
            log.error("Failed to load LLM model \(modelId): \(error.localizedDescription)")
            throw LLMError.modelLoadFailed(modelId)
        }
    }

    /// Enrich transcription with punctuation, capitalization, and error correction
    func enrichTranscription(_ text: String, temperature: Float = 0.3) async throws -> String {
        guard let modelContainer else {
            throw LLMError.modelNotLoaded
        }

        log.info("Starting LLM enrichment...")
        let enrichStart = CFAbsoluteTimeGetCurrent()

        // Create prompt for transcription enrichment
        let prompt = """
        Fix spelling errors, add proper punctuation and capitalization to the following transcription. \
        Preserve the original words and meaning. Only correct obvious errors. \
        Do not add or remove content.

        Transcription: \(text)

        Corrected:
        """

        do {
            // Configure generation parameters
            let parameters = GenerateParameters(
                temperature: temperature,
                topP: 0.9,
                maxTokens: 500
            )

            // Generate enriched text
            let result = try await modelContainer.perform { model, tokenizer in
                LLMEvaluator.generate(
                    prompt: .init(prompt),
                    model: model,
                    tokenizer: tokenizer,
                    parameters: parameters
                )
            }

            let enrichTime = CFAbsoluteTimeGetCurrent() - enrichStart
            let enrichedText = result.output.trimmingCharacters(in: .whitespacesAndNewlines)

            log.info("LLM enrichment completed in \(String(format: "%.2f", enrichTime))s")
            log.info("Generated \(result.output.count) characters")

            return enrichedText
        } catch {
            log.error("LLM inference failed: \(error.localizedDescription)")
            throw LLMError.inferenceFailed(error.localizedDescription)
        }
    }

    /// Unload the current model to free memory
    func unloadModel() {
        modelContainer = nil
        currentModelId = nil
        log.info("LLM model unloaded")
    }

    /// Check if a model is currently loaded
    var isModelLoaded: Bool {
        modelContainer != nil
    }

    /// Get the currently loaded model ID
    var loadedModelId: String? {
        currentModelId
    }
}
