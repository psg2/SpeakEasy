import Foundation

// Provider selection enum
public enum TranscriptionProvider: String, CaseIterable, Codable {
    case openAI = "openai"
    case localWhisper = "local"

    public var displayName: String {
        switch self {
        case .openAI: "OpenAI API"
        case .localWhisper: "Local Whisper"
        }
    }

    public var description: String {
        switch self {
        case .openAI: "Cloud-based, requires API key"
        case .localWhisper: "On-device with CoreML (Apple Silicon optimized)"
        }
    }

    public var icon: String {
        switch self {
        case .openAI: "cloud"
        case .localWhisper: "desktopcomputer"
        }
    }
}

// Dynamic Whisper model from HuggingFace
struct WhisperKitModel: Identifiable, Codable, Hashable {
    let id: String // e.g., "openai_whisper-base"

    var displayName: String {
        // Convert "openai_whisper-base" to "Base"
        // Convert "openai_whisper-large-v3_turbo" to "Large V3 Turbo"
        var name = self.id
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
        self.id.hasSuffix(".en")
    }

    var isDistil: Bool {
        self.id.hasPrefix("distil-whisper")
    }

    var isTurbo: Bool {
        self.id.contains("turbo")
    }

    /// Estimated size based on model variant
    var estimatedSizeBytes: Int64 {
        // Extract size from name if present (e.g., "947MB")
        if let match = id.range(of: #"(\d+)MB"#, options: .regularExpression) {
            let sizeStr = self.id[match].replacingOccurrences(of: "MB", with: "")
            if let size = Int64(sizeStr) {
                return size * 1_000_000
            }
        }

        // Otherwise estimate based on model name
        if self.id.contains("tiny") { return 66_000_000 }
        if self.id.contains("base") { return 148_000_000 }
        if self.id.contains("small") { return 244_000_000 }
        if self.id.contains("medium") { return 1_530_000_000 }
        if self.id.contains("large") { return 3_000_000_000 }
        return 500_000_000 // Default estimate
    }

    var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self.estimatedSizeBytes)
    }

    var qualityDescription: String {
        if self.id.contains("tiny") { return "Fastest, best for simple dictation" }
        if self.id.contains("base") { return "Fast, good for clear audio" }
        if self.id.contains("small") { return "Balanced speed and accuracy" }
        if self.id.contains("medium") { return "High accuracy, moderate speed" }
        if self.id.contains("large"), self.isTurbo { return "Best accuracy with optimized speed" }
        if self.id.contains("large") { return "Best accuracy, slower" }
        if self.isDistil { return "Distilled model - faster inference" }
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
    case tiny
    case base
    case small
    case medium
    case largeTurbo = "large-v3-turbo"

    var displayName: String {
        switch self {
        case .tiny: "Tiny"
        case .base: "Base"
        case .small: "Small"
        case .medium: "Medium"
        case .largeTurbo: "Large V3 Turbo"
        }
    }

    var whisperKitName: String {
        switch self {
        case .tiny: "openai_whisper-tiny"
        case .base: "openai_whisper-base"
        case .small: "openai_whisper-small"
        case .medium: "openai_whisper-medium"
        case .largeTurbo: "openai_whisper-large-v3_turbo"
        }
    }

    var sizeBytes: Int64 {
        switch self {
        case .tiny: 66_000_000
        case .base: 148_000_000
        case .small: 244_000_000
        case .medium: 1_530_000_000
        case .largeTurbo: 954_000_000
        }
    }

    var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self.sizeBytes)
    }

    var qualityDescription: String {
        switch self {
        case .tiny: "Fastest, best for simple dictation"
        case .base: "Fast, good for clear audio"
        case .small: "Balanced speed and accuracy"
        case .medium: "High accuracy, moderate speed"
        case .largeTurbo: "Best accuracy with optimized speed"
        }
    }
}
