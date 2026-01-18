import Foundation

// LLM model variants for transcription enrichment
public enum LLMModel: String, CaseIterable, Codable {
    case qwen05B = "mlx-community/Qwen2.5-0.5B-Instruct-4bit"
    case qwen15B = "mlx-community/Qwen2.5-1.5B-Instruct-4bit"
    case qwen3B = "mlx-community/Qwen2.5-3B-Instruct-4bit"

    public var displayName: String {
        switch self {
        case .qwen05B: "Qwen 2.5 (0.5B)"
        case .qwen15B: "Qwen 2.5 (1.5B)"
        case .qwen3B: "Qwen 2.5 (3B)"
        }
    }

    public var modelId: String {
        self.rawValue
    }

    public var estimatedSizeBytes: Int64 {
        switch self {
        case .qwen05B: 300_000_000 // ~300MB (4-bit quantized)
        case .qwen15B: 900_000_000 // ~900MB (4-bit quantized)
        case .qwen3B: 1_800_000_000 // ~1.8GB (4-bit quantized)
        }
    }

    public var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self.estimatedSizeBytes)
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

// Dynamic LLM model from HuggingFace
struct MLXModel: Identifiable, Codable, Hashable {
    let id: String // e.g., "mlx-community/Qwen2.5-0.5B-Instruct-4bit"

    var displayName: String {
        // Extract model name from HuggingFace path
        let components = id.split(separator: "/")
        guard components.count >= 2 else { return id }

        var name = String(components[1])
        // Clean up common patterns
        name = name.replacingOccurrences(of: "-Instruct", with: "")
        name = name.replacingOccurrences(of: "-4bit", with: " (4-bit)")
        name = name.replacingOccurrences(of: "-8bit", with: " (8-bit)")
        name = name.replacingOccurrences(of: "-", with: " ")

        return name
    }

    var isQuantized: Bool {
        id.contains("4bit") || id.contains("8bit") || id.contains("fp16")
    }

    var quantizationType: String? {
        if id.contains("4bit") { return "4-bit" }
        if id.contains("8bit") { return "8-bit" }
        if id.contains("fp16") { return "FP16" }
        return nil
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
