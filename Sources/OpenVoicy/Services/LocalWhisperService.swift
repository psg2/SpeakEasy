import AVFoundation
import Foundation
import SwiftWhisper

private let log = FileLogger.shared

class LocalWhisperService {
    static let shared = LocalWhisperService()

    private var whisper: Whisper?
    private var loadedModel: WhisperModel?

    private init() {
        log.whisper("LocalWhisperService initialized")
    }

    func ensureModelLoaded(_ model: WhisperModel) throws {
        if loadedModel == model && whisper != nil {
            log.whisper("✓ Model \(model.displayName) already loaded (skipping load)")
            return
        }

        log.whisper("══════════════════════════════════════════")
        log.whisper("MODEL LOADING: \(model.displayName)")
        log.whisper("══════════════════════════════════════════")

        let totalLoadStart = CFAbsoluteTimeGetCurrent()

        // Unload previous model first to free memory
        if whisper != nil {
            let unloadStart = CFAbsoluteTimeGetCurrent()
            log.whisper("Unloading previous model to free memory...")
            whisper = nil
            loadedModel = nil
            let unloadTime = CFAbsoluteTimeGetCurrent() - unloadStart
            log.whisper("  → Unload time: \(String(format: "%.2f", unloadTime * 1000))ms")
        }

        let modelPath = WhisperModelManager.shared.modelPath(for: model)
        log.whisper("Model path: \(modelPath.path)")

        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            log.error("Model file not found at path: \(modelPath.path)")
            throw LocalWhisperError.modelNotDownloaded
        }

        // Check file size to verify model integrity
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: modelPath.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let expectedSize = model.sizeBytes

            let fileSizeMB = Double(fileSize) / 1_000_000
            log.whisper("Model file size: \(String(format: "%.1f", fileSizeMB)) MB")

            // Allow 10% variance in file size
            if fileSize < Int64(Double(expectedSize) * 0.9) {
                log.error("Model file appears corrupted. Size \(fileSize) is less than 90% of expected \(expectedSize)")
                throw LocalWhisperError.modelCorrupted
            }
        } catch let error as LocalWhisperError {
            throw error
        } catch {
            log.warning("Could not check file attributes: \(error.localizedDescription)")
        }

        log.whisper("Initializing Whisper from file...")
        let initStart = CFAbsoluteTimeGetCurrent()
        let loadedWhisper = Whisper(fromFileURL: modelPath)
        let initTime = CFAbsoluteTimeGetCurrent() - initStart

        let totalLoadTime = CFAbsoluteTimeGetCurrent() - totalLoadStart
        log.whisper("  → Whisper init time: \(String(format: "%.2f", initTime))s")
        log.whisper("  → Total load time: \(String(format: "%.2f", totalLoadTime))s")
        log.whisper("══════════════════════════════════════════")

        whisper = loadedWhisper
        loadedModel = model
    }

    func transcribe(audioFileURL: URL, language: String? = nil) async throws -> String {
        let totalStart = CFAbsoluteTimeGetCurrent()

        log.whisper("══════════════════════════════════════════")
        log.whisper("TRANSCRIPTION START")
        log.whisper("══════════════════════════════════════════")
        log.whisper("Audio file: \(audioFileURL.lastPathComponent)")

        let model = SettingsManager.shared.selectedWhisperModel
        log.whisper("Model: \(model.displayName)")

        // Step 1: Load model (if needed)
        let modelLoadStart = CFAbsoluteTimeGetCurrent()
        try ensureModelLoaded(model)
        let modelLoadTime = CFAbsoluteTimeGetCurrent() - modelLoadStart

        guard let whisper = whisper else {
            log.error("Whisper instance is nil after loading")
            throw LocalWhisperError.modelNotLoaded
        }

        // Step 2: Load and convert audio
        let audioLoadStart = CFAbsoluteTimeGetCurrent()
        log.whisper("Loading audio frames...")
        let audioFrames = try await loadAudioFrames(from: audioFileURL)
        let audioLoadTime = CFAbsoluteTimeGetCurrent() - audioLoadStart
        let audioDurationSec = Double(audioFrames.count) / 16000.0
        log.whisper("  → Audio frames: \(audioFrames.count) (~\(String(format: "%.1f", audioDurationSec))s of audio)")
        log.whisper("  → Audio load time: \(String(format: "%.2f", audioLoadTime * 1000))ms")

        // Step 3: Run transcription
        let transcribeStart = CFAbsoluteTimeGetCurrent()
        log.whisper("Running Whisper inference...")
        let segments = try await whisper.transcribe(audioFrames: audioFrames)
        let transcribeTime = CFAbsoluteTimeGetCurrent() - transcribeStart

        let transcription = segments.map(\.text).joined(separator: " ")
        let result = transcription.trimmingCharacters(in: .whitespacesAndNewlines)

        let totalTime = CFAbsoluteTimeGetCurrent() - totalStart
        let realtimeFactor = transcribeTime / audioDurationSec

        log.whisper("══════════════════════════════════════════")
        log.whisper("TRANSCRIPTION COMPLETE")
        log.whisper("══════════════════════════════════════════")
        log.whisper("  → Model load:    \(String(format: "%6.2f", modelLoadTime))s")
        log.whisper("  → Audio load:    \(String(format: "%6.2f", audioLoadTime))s")
        log.whisper("  → Inference:     \(String(format: "%6.2f", transcribeTime))s")
        log.whisper("  → TOTAL:         \(String(format: "%6.2f", totalTime))s")
        log.whisper("──────────────────────────────────────────")
        log.whisper("  → Audio duration: \(String(format: "%.1f", audioDurationSec))s")
        log.whisper("  → Realtime factor: \(String(format: "%.1f", realtimeFactor))x (lower is better)")
        log.whisper("  → Segments: \(segments.count)")
        log.whisper("  → Result: \(result.count) chars, \(result.split(separator: " ").count) words")
        log.whisper("══════════════════════════════════════════")

        return result
    }

    private func loadAudioFrames(from url: URL) async throws -> [Float] {
        let audioFile = try AVAudioFile(forReading: url)
        let sourceFormat = audioFile.processingFormat

        if sourceFormat.sampleRate == 16000 && sourceFormat.channelCount == 1 {
            return try readAudioFrames(from: audioFile)
        } else {
            return try convertAndReadAudioFrames(from: audioFile)
        }
    }

    private func readAudioFrames(from audioFile: AVAudioFile) throws -> [Float] {
        let frameCount = UInt32(audioFile.length)

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: frameCount
        ) else {
            throw LocalWhisperError.audioConversionFailed
        }

        try audioFile.read(into: buffer)

        guard let floatData = buffer.floatChannelData else {
            throw LocalWhisperError.audioConversionFailed
        }

        return Array(UnsafeBufferPointer(
            start: floatData[0],
            count: Int(buffer.frameLength)
        ))
    }

    private func convertAndReadAudioFrames(from audioFile: AVAudioFile) throws -> [Float] {
        let sourceFormat = audioFile.processingFormat

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw LocalWhisperError.audioConversionFailed
        }

        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw LocalWhisperError.audioConversionFailed
        }

        let ratio = targetFormat.sampleRate / sourceFormat.sampleRate
        let outputFrameCount = UInt32(Double(audioFile.length) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCount
        ) else {
            throw LocalWhisperError.audioConversionFailed
        }

        let inputFrameCount = UInt32(audioFile.length)
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: inputFrameCount
        ) else {
            throw LocalWhisperError.audioConversionFailed
        }

        try audioFile.read(into: inputBuffer)

        var error: NSError?
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if let error {
            throw LocalWhisperError.audioConversionFailed
        }

        guard let floatData = outputBuffer.floatChannelData else {
            throw LocalWhisperError.audioConversionFailed
        }

        return Array(UnsafeBufferPointer(
            start: floatData[0],
            count: Int(outputBuffer.frameLength)
        ))
    }

    func unloadModel() {
        whisper = nil
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
