import Foundation

// Provider selection enum
enum TranscriptionProvider: String, CaseIterable, Codable {
    case openAI = "openai"
    case localWhisper = "local"

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI API"
        case .localWhisper: return "Local Whisper"
        }
    }

    var description: String {
        switch self {
        case .openAI: return "Cloud-based, requires API key"
        case .localWhisper: return "On-device, private, no internet required"
        }
    }

    var icon: String {
        switch self {
        case .openAI: return "cloud"
        case .localWhisper: return "desktopcomputer"
        }
    }
}

// Available Whisper models for local transcription
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
        case .largeTurbo: return "Large Turbo"
        }
    }

    var fileName: String {
        "ggml-\(rawValue).bin"
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }

    var sizeBytes: Int64 {
        switch self {
        case .tiny: return 77_700_000
        case .base: return 148_000_000
        case .small: return 488_000_000
        case .medium: return 1_530_000_000
        case .largeTurbo: return 1_620_000_000
        }
    }

    var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    var qualityDescription: String {
        switch self {
        case .tiny: return "Fastest, lower accuracy"
        case .base: return "Fast, good for clear audio"
        case .small: return "Balanced speed and accuracy"
        case .medium: return "High accuracy, slower"
        case .largeTurbo: return "Best accuracy, optimized speed"
        }
    }
}

// Model download status
enum ModelDownloadStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)
}
