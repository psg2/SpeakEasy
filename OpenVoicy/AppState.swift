import Foundation
import Combine
import SwiftUI
import AppKit

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

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
        setupShortcut()
    }

    private func setupBindings() {
        recorder.$audioLevel
            .receive(on: RunLoop.main)
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)
    }

    private func setupShortcut() {
        GlobalShortcutManager.shared.updateShortcut(from: settings.shortcut)

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
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .processing:
            break // Ignore
        }
    }

    func startRecording() {
        guard settings.hasApiKey else {
            errorMessage = "Please set your OpenAI API Key in settings."
            return
        }

        // Reset state
        errorMessage = nil
        lastTranscription = ""

        SoundManager.shared.playStartSound()
        state = .recording
        recorder.startRecording()

        // Register Escape to cancel
        GlobalShortcutManager.shared.registerEscapeShortcut()
    }

    func stopRecording() {
        GlobalShortcutManager.shared.unregisterEscapeShortcut()

        SoundManager.shared.playStopSound()
        state = .processing
        recorder.stopRecording()

        recorder.onRecordingFinished = { [weak self] url in
            guard let self = self, let url = url else {
                self?.state = .idle
                self?.errorMessage = "Recording failed."
                return
            }

            Task {
                await self.transcribe(url: url)
            }
        }
    }

    func cancelRecording() {
        GlobalShortcutManager.shared.unregisterEscapeShortcut()
        recorder.stopRecording()
        state = .idle
    }

    private func transcribe(url: URL) async {
        do {
            let text = try await transcriber.transcribe(audioFileURL: url, language: settings.language)
            self.lastTranscription = text

            // Output handling
            self.accessibility.copyToClipboard(text)

            // Ensure app is hidden so focus returns to previous app before typing
            NSApp.hide(nil)

            // Short delay to allow OS to switch focus
            try? await Task.sleep(nanoseconds: 100 * 1_000_000) // 100ms

            if self.accessibility.checkPermissions() {
                self.accessibility.typeText(text)
            } else {
                self.errorMessage = "Transcription copied to clipboard. Enable Accessibility to type directly."
            }

            self.state = .idle

            // Cleanup
            try? FileManager.default.removeItem(at: url)

        } catch {
            self.errorMessage = "Transcription failed: \(error.localizedDescription)"
            self.state = .idle
        }
    }
}
