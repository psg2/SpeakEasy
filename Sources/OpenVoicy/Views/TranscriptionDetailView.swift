import AppKit
import SwiftUI

// Uses extensions from Utils/TimeFormatters.swift and Utils/ViewExtensions.swift

struct TranscriptionDetailView: View {
    let transcription: TranscriptionRecord
    @ObservedObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.transcription.createdAt, style: .date)
                        .font(.headline)
                    Text(self.transcription.createdAt, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(self.transcription.wordCount) words")
                        .font(.subheadline)
                    if let duration = transcription.durationSeconds {
                        Text(self.formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let transcriptionTime = transcription.transcriptionTimeSeconds {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text(transcriptionTime.formatAsTranscriptionTime())
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            if self.transcription.provider != nil || self.transcription.modelName != nil {
                self.providerInfoView
            }

            Divider()

            if self.transcription.transcriptionStatus == .processing {
                self.processingView
            } else if self.transcription.text.isEmpty {
                self.emptyTextView
            } else {
                ScrollView {
                    Text(self.transcription.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider()

            HStack {
                Button(action: self.copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(self.transcription.text.isEmpty)
                .handCursorOnHover()

                if let fileName = transcription.audioFileName,
                   AudioStorageManager.shared.audioFileExists(fileName: fileName)
                {
                    Button(action: { AudioStorageManager.shared.revealInFinder(fileName: fileName) }) {
                        Label("Reveal Audio", systemImage: "folder")
                    }
                    .handCursorOnHover()

                    Button(action: {
                        Task {
                            await self.appState.retryTranscription(record: self.transcription)
                        }
                    }) {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .handCursorOnHover()
                }

                Spacer()

                Button(role: .destructive, action: self.deleteTranscription) {
                    Label("Delete", systemImage: "trash")
                }
                .handCursorOnHover()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var providerInfoView: some View {
        HStack(spacing: 12) {
            if let provider = transcription.provider {
                HStack(spacing: 4) {
                    Image(systemName: provider.icon)
                        .font(.caption)
                    Text(provider.displayName)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(6)
            }

            if let modelName = transcription.modelName {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.caption)
                    Text(modelName)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(6)
            }

            Spacer()
        }
        .foregroundColor(.secondary)
    }

    private var processingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text("Processing...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("This transcription may have failed. Try retrying or delete it.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyTextView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "text.quote")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No transcription text")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func deleteTranscription() {
        if let fileName = transcription.audioFileName {
            try? AudioStorageManager.shared.deleteAudio(fileName: fileName)
        }
        self.modelContext.delete(self.transcription)
        self.onDelete?()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.transcription.text, forType: .string)
    }
}
