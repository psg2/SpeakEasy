import AppKit
import Combine
import Foundation
import SwiftData
import SwiftUI

enum RecordingState {
    case idle
    case recording
    case processing
}

@MainActor
class AppState: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var audioLevel: Float = 0.0
    @Published var lastTranscription: String = ""
    @Published var errorMessage: String?

    private let recorder = AudioRecorder()
    private let transcriber = TranscriptionService.shared
    private let accessibility = AccessibilityService.shared
    private let settings = SettingsManager.shared
    private let audioStorage = AudioStorageManager.shared

    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private var recordingStartTime: Date?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.setupBindings()
        self.setupShortcut()
    }

    private func setupBindings() {
        self.recorder.$audioLevel
            .receive(on: RunLoop.main)
            .assign(to: \.audioLevel, on: self)
            .store(in: &self.cancellables)
    }

    private func setupShortcut() {
        GlobalShortcutManager.shared.registerShortcut(
            key: self.settings.shortcutKeyCode,
            modifiers: self.settings.shortcutModifierFlags)

        GlobalShortcutManager.shared.onShortcutTriggered = { [weak self] in
            Task { @MainActor in
                self?.toggleRecording()
            }
        }

        GlobalShortcutManager.shared.onEscapeTriggered = { [weak self] in
            Task { @MainActor in
                self?.cancelRecording()
            }
        }
    }

    func toggleRecording() {
        switch self.state {
        case .idle:
            self.startRecording()
        case .recording:
            self.stopRecording()
        case .processing:
            break // Ignore
        }
    }

    func startRecording() {
        switch settings.transcriptionProvider {
        case .openAI:
            guard settings.hasApiKey else {
                self.errorMessage = "Please set your OpenAI API Key in Settings > Providers."
                return
            }
        case .localWhisper:
            guard settings.isLocalWhisperReady else {
                self.errorMessage = "Please download a Whisper model in Settings > Providers."
                return
            }
        }

        self.errorMessage = nil
        self.lastTranscription = ""
        self.recordingStartTime = Date()

        SoundManager.shared.playStartSound()
        self.state = .recording
        self.recorder.startRecording()

        GlobalShortcutManager.shared.registerEscapeShortcut()
    }

    func stopRecording() {
        GlobalShortcutManager.shared.unregisterEscapeShortcut()

        SoundManager.shared.playStopSound()
        self.state = .processing
        self.recorder.stopRecording()

        self.recorder.onRecordingFinished = { [weak self] url in
            guard let self, let url else {
                self?.state = .idle
                self?.errorMessage = "Recording failed."
                return
            }

            Task {
                await self.transcribeAndSave(temporaryURL: url)
            }
        }
    }

    func cancelRecording() {
        GlobalShortcutManager.shared.unregisterEscapeShortcut()
        self.recorder.stopRecording()
        self.state = .idle
        self.recordingStartTime = nil
    }

    private func transcribeAndSave(temporaryURL: URL) async {
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) }

        do {
            let audioFileName = try audioStorage.saveAudio(from: temporaryURL)

            let record = TranscriptionRecord(
                text: "",
                audioFileName: audioFileName,
                durationSeconds: duration,
                language: settings.language,
                transcriptionStatus: .processing
            )
            modelContext.insert(record)
            try modelContext.save()

            let text = try await transcriber.transcribe(
                audioFileURL: audioStorage.audioURL(for: audioFileName),
                language: settings.language
            )

            record.updateText(text)
            record.transcriptionStatus = .completed
            try modelContext.save()

            self.lastTranscription = text

            self.accessibility.copyToClipboard(text)

            NSApp.hide(nil)

            try? await Task.sleep(nanoseconds: 100 * 1_000_000)

            if self.accessibility.checkPermissions() {
                self.accessibility.typeText(text)
            } else {
                self.errorMessage = "Transcription copied to clipboard. Enable Accessibility to type directly."
            }

            self.state = .idle

            try? FileManager.default.removeItem(at: temporaryURL)

        } catch {
            self.errorMessage = "Transcription failed: \(error.localizedDescription)"
            self.state = .idle
            try? FileManager.default.removeItem(at: temporaryURL)
        }
    }

    func retryTranscription(record: TranscriptionRecord) async {
        guard let audioFileName = record.audioFileName,
              audioStorage.audioFileExists(fileName: audioFileName)
        else {
            self.errorMessage = "Audio file not found for retry."
            return
        }

        record.transcriptionStatus = .processing
        try? modelContext.save()

        do {
            let text = try await transcriber.transcribe(
                audioFileURL: audioStorage.audioURL(for: audioFileName),
                language: settings.language
            )

            record.updateText(text)
            record.transcriptionStatus = .completed
            try? modelContext.save()

        } catch {
            record.transcriptionStatus = .failed
            try? modelContext.save()
            self.errorMessage = "Retry failed: \(error.localizedDescription)"
        }
    }
}
