import AVFoundation
import Foundation
import WhisperKit

private let log = FileLogger.shared

class LocalWhisperService {
    static let shared = LocalWhisperService()

    private var whisperKit: WhisperKit?
    private var loadedModel: WhisperModel?

    private init() {
        log.whisper("LocalWhisperService initialized (WhisperKit)")
    }

    func ensureModelLoaded(_ model: WhisperModel) async throws {
        if loadedModel == model && whisperKit != nil {
            log.whisper("✓ Model \(model.displayName) already loaded (skipping load)")
            return
        }

        log.whisper("══════════════════════════════════════════")
        log.whisper("MODEL LOADING: \(model.displayName)")
        log.whisper("══════════════════════════════════════════")

        let totalLoadStart = CFAbsoluteTimeGetCurrent()

        // Unload previous model first to free memory
        if whisperKit != nil {
            let unloadStart = CFAbsoluteTimeGetCurrent()
            log.whisper("Unloading previous model to free memory...")
            whisperKit = nil
            loadedModel = nil
            let unloadTime = CFAbsoluteTimeGetCurrent() - unloadStart
            log.whisper("  → Unload time: \(String(format: "%.2f", unloadTime * 1000))ms")
        }

        log.whisper("Initializing WhisperKit with model: \(model.whisperKitName)")
        let initStart = CFAbsoluteTimeGetCurrent()

        do {
            // WhisperKit will download the model if not present
            whisperKit = try await WhisperKit(
                model: model.whisperKitName,
                verbose: false,
                logLevel: .none
            )
            let initTime = CFAbsoluteTimeGetCurrent() - initStart

            let totalLoadTime = CFAbsoluteTimeGetCurrent() - totalLoadStart
            log.whisper("  → WhisperKit init time: \(String(format: "%.2f", initTime))s")
            log.whisper("  → Total load time: \(String(format: "%.2f", totalLoadTime))s")
            log.whisper("══════════════════════════════════════════")

            loadedModel = model
        } catch {
            log.error("Failed to initialize WhisperKit: \(error.localizedDescription)")
            throw LocalWhisperError.modelLoadFailed(model.displayName)
        }
    }

    func transcribe(audioFileURL: URL, language: String? = nil) async throws -> String {
        let totalStart = CFAbsoluteTimeGetCurrent()

        log.whisper("══════════════════════════════════════════")
        log.whisper("TRANSCRIPTION START (WhisperKit)")
        log.whisper("══════════════════════════════════════════")
        log.whisper("Audio file: \(audioFileURL.lastPathComponent)")

        let model = SettingsManager.shared.selectedWhisperModel
        log.whisper("Model: \(model.displayName)")

        // Step 1: Load model (if needed)
        let modelLoadStart = CFAbsoluteTimeGetCurrent()
        try await ensureModelLoaded(model)
        let modelLoadTime = CFAbsoluteTimeGetCurrent() - modelLoadStart

        guard let whisperKit = whisperKit else {
            log.error("WhisperKit instance is nil after loading")
            throw LocalWhisperError.modelNotLoaded
        }

        // Step 2: Get audio duration for stats
        let audioDurationSec = getAudioDuration(url: audioFileURL)
        log.whisper("Audio duration: \(String(format: "%.1f", audioDurationSec))s")

        // Step 3: Run transcription
        let transcribeStart = CFAbsoluteTimeGetCurrent()
        log.whisper("Running WhisperKit inference...")

        let results = try await whisperKit.transcribe(
            audioPath: audioFileURL.path,
            decodeOptions: DecodingOptions(
                language: language
            )
        )
        let transcribeTime = CFAbsoluteTimeGetCurrent() - transcribeStart

        let transcription = results.map { $0.text }.joined(separator: " ")
        let result = transcription.trimmingCharacters(in: .whitespacesAndNewlines)

        let totalTime = CFAbsoluteTimeGetCurrent() - totalStart
        let realtimeFactor = audioDurationSec > 0 ? transcribeTime / audioDurationSec : 0

        log.whisper("══════════════════════════════════════════")
        log.whisper("TRANSCRIPTION COMPLETE")
        log.whisper("══════════════════════════════════════════")
        log.whisper("  → Model load:    \(String(format: "%6.2f", modelLoadTime))s")
        log.whisper("  → Inference:     \(String(format: "%6.2f", transcribeTime))s")
        log.whisper("  → TOTAL:         \(String(format: "%6.2f", totalTime))s")
        log.whisper("──────────────────────────────────────────")
        log.whisper("  → Audio duration: \(String(format: "%.1f", audioDurationSec))s")
        log.whisper("  → Realtime factor: \(String(format: "%.2f", realtimeFactor))x (lower is better)")
        log.whisper("  → Segments: \(results.count)")
        log.whisper("  → Result: \(result.count) chars, \(result.split(separator: " ").count) words")
        log.whisper("══════════════════════════════════════════")

        return result
    }

    private func getAudioDuration(url: URL) -> Double {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
            return duration
        } catch {
            return 0
        }
    }

    func unloadModel() {
        whisperKit = nil
        loadedModel = nil
    }
}

enum LocalWhisperError: LocalizedError {
    case modelNotDownloaded
    case modelNotLoaded
    case modelCorrupted
    case modelLoadFailed(String)
    case audioConversionFailed
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotDownloaded:
            return "Whisper model not downloaded. Please download it in Settings."
        case .modelNotLoaded:
            return "Failed to load Whisper model"
        case .modelCorrupted:
            return "Model file appears corrupted. Please delete and re-download."
        case .modelLoadFailed(let modelName):
            return "Failed to load \(modelName) model. It may be incompatible or corrupted."
        case .audioConversionFailed:
            return "Failed to convert audio for transcription"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        }
    }
}
