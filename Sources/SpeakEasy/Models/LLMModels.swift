import Foundation

// LLM model variants for transcription enrichment (GGUF format for llama.cpp)
public enum LLMModel: String, CaseIterable, Codable, Sendable, Hashable {
    case qwen05B = "Qwen2.5-0.5B-Instruct-Q4_K_M"
    case qwen15B = "Qwen2.5-1.5B-Instruct-Q4_K_M"
    case qwen3B = "Qwen2.5-3B-Instruct-Q4_K_M"

    public var displayName: String {
        switch self {
        case .qwen05B: "Qwen 2.5 (0.5B)"
        case .qwen15B: "Qwen 2.5 (1.5B)"
        case .qwen3B: "Qwen 2.5 (3B)"
        }
    }

    public var fileName: String {
        "\(rawValue).gguf"
    }

    /// Direct download URL from HuggingFace
    public var downloadURL: URL {
        switch self {
        case .qwen05B:
            URL(
                string:
                    "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"
            )!
        case .qwen15B:
            URL(
                string:
                    "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
            )!
        case .qwen3B:
            URL(
                string:
                    "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"
            )!
        }
    }

    public var estimatedSizeBytes: Int64 {
        switch self {
        case .qwen05B: 400_000_000 // ~400MB (Q4_K_M)
        case .qwen15B: 1_100_000_000 // ~1.1GB (Q4_K_M)
        case .qwen3B: 2_000_000_000 // ~2GB (Q4_K_M)
        }
    }

    public var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: estimatedSizeBytes)
    }

    public var ramUsage: String {
        switch self {
        case .qwen05B: "~1GB RAM"
        case .qwen15B: "~2GB RAM"
        case .qwen3B: "~3GB RAM"
        }
    }

    public var qualityDescription: String {
        switch self {
        case .qwen05B: "Fast inference, good for basic corrections"
        case .qwen15B: "Balanced quality and speed (recommended)"
        case .qwen3B: "Best quality, higher resource usage"
        }
    }

    public var speedDescription: String {
        switch self {
        case .qwen05B: "Fastest"
        case .qwen15B: "Fast"
        case .qwen3B: "Moderate"
        }
    }
}

// LLM download and loading status
enum LLMStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case loading
    case loaded
    case error(String)
}
