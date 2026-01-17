import AVFoundation
import Foundation
import SwiftWhisper

class LocalWhisperService {
    static let shared = LocalWhisperService()

    private var whisper: Whisper?
    private var loadedModel: WhisperModel?

    private init() {}

    func ensureModelLoaded(_ model: WhisperModel) throws {
        if loadedModel == model && whisper != nil {
            return
        }

        let modelPath = WhisperModelManager.shared.modelPath(for: model)

        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw LocalWhisperError.modelNotDownloaded
        }

        whisper = Whisper(fromFileURL: modelPath)
        loadedModel = model
    }

    func transcribe(audioFileURL: URL, language: String? = nil) async throws -> String {
        let model = SettingsManager.shared.selectedWhisperModel
        try ensureModelLoaded(model)

        guard let whisper = whisper else {
            throw LocalWhisperError.modelNotLoaded
        }

        let audioFrames = try await loadAudioFrames(from: audioFileURL)
        let segments = try await whisper.transcribe(audioFrames: audioFrames)

        let transcription = segments.map(\.text).joined(separator: " ")
        return transcription.trimmingCharacters(in: .whitespacesAndNewlines)
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
    case audioConversionFailed
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotDownloaded:
            return "Whisper model not downloaded. Please download it in Settings."
        case .modelNotLoaded:
            return "Failed to load Whisper model"
        case .audioConversionFailed:
            return "Failed to convert audio for transcription"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        }
    }
}
