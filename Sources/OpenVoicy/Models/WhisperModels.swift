import Foundation

// Provider selection enum
public enum TranscriptionProvider: String, CaseIterable, Codable {
    case openAI = "openai"
    case localWhisper = "local"

    public var displayName: String {
        switch self {
        case .openAI: return "OpenAI API"
        case .localWhisper: return "Local Whisper"
        }
    }

    public var description: String {
        switch self {
        case .openAI: return "Cloud-based, requires API key"
        case .localWhisper: return "On-device with CoreML (Apple Silicon optimized)"
        }
    }

    public var icon: String {
        switch self {
        case .openAI: return "cloud"
        case .localWhisper: return "desktopcomputer"
        }
    }
}

// Dynamic Whisper model from HuggingFace
struct WhisperKitModel: Identifiable, Codable, Hashable {
    let id: String  // e.g., "openai_whisper-base"

    var displayName: String {
        // Convert "openai_whisper-base" to "Base"
        // Convert "openai_whisper-large-v3_turbo" to "Large V3 Turbo"
        var name = id
            .replacingOccurrences(of: "openai_whisper-", with: "")
            .replacingOccurrences(of: "distil-whisper_distil-", with: "Distil ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        // Capitalize words
        name = name.split(separator: " ").map { word in
            let w = String(word)
            if w.lowercased() == "v2" || w.lowercased() == "v3" {
                return w.uppercased()
            }
            return w.capitalized
        }.joined(separator: " ")

        // Remove size suffixes like "947MB"
        if let range = name.range(of: #"\d+MB$"#, options: .regularExpression) {
            name = String(name[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }

        return name
    }

    var isEnglishOnly: Bool {
        id.hasSuffix(".en")
    }

    var isDistil: Bool {
        id.hasPrefix("distil-whisper")
    }

    var isTurbo: Bool {
        id.contains("turbo")
    }

    /// Estimated size based on model variant
    var estimatedSizeBytes: Int64 {
        // Extract size from name if present (e.g., "947MB")
        if let match = id.range(of: #"(\d+)MB"#, options: .regularExpression) {
            let sizeStr = id[match].replacingOccurrences(of: "MB", with: "")
            if let size = Int64(sizeStr) {
                return size * 1_000_000
            }
        }

        // Otherwise estimate based on model name
        if id.contains("tiny") { return 66_000_000 }
        if id.contains("base") { return 148_000_000 }
        if id.contains("small") { return 244_000_000 }
        if id.contains("medium") { return 1_530_000_000 }
        if id.contains("large") { return 3_000_000_000 }
        return 500_000_000  // Default estimate
    }

    var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: estimatedSizeBytes)
    }

    var qualityDescription: String {
        if id.contains("tiny") { return "Fastest, best for simple dictation" }
        if id.contains("base") { return "Fast, good for clear audio" }
        if id.contains("small") { return "Balanced speed and accuracy" }
        if id.contains("medium") { return "High accuracy, moderate speed" }
        if id.contains("large") && isTurbo { return "Best accuracy with optimized speed" }
        if id.contains("large") { return "Best accuracy, slower" }
        if isDistil { return "Distilled model - faster inference" }
        return "Whisper model"
    }
}

// Model download status
enum ModelDownloadStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)
}

// Legacy enum for settings compatibility
// This maps to the new dynamic model system
enum WhisperModel: String, CaseIterable, Codable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    case medium = "medium"
    case largeTurbo = "large-v3-turbo"

    var displayName: String {
        switch self {
        case .tiny: return "Tiny"
        case .base: return "Base"
        case .small: return "Small"
        case .medium: return "Medium"
        case .largeTurbo: return "Large V3 Turbo"
        }
    }

    var whisperKitName: String {
        switch self {
        case .tiny: return "openai_whisper-tiny"
        case .base: return "openai_whisper-base"
        case .small: return "openai_whisper-small"
        case .medium: return "openai_whisper-medium"
        case .largeTurbo: return "openai_whisper-large-v3_turbo"
        }
    }

    var sizeBytes: Int64 {
        switch self {
        case .tiny: return 66_000_000
        case .base: return 148_000_000
        case .small: return 244_000_000
        case .medium: return 1_530_000_000
        case .largeTurbo: return 954_000_000
        }
    }

    var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    var qualityDescription: String {
        switch self {
        case .tiny: return "Fastest, best for simple dictation"
        case .base: return "Fast, good for clear audio"
        case .small: return "Balanced speed and accuracy"
        case .medium: return "High accuracy, moderate speed"
        case .largeTurbo: return "Best accuracy with optimized speed"
        }
    }
}
