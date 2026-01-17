import AppKit
import SwiftUI

struct TranscriptionDetailView: View {
    let transcription: TranscriptionRecord
    @ObservedObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transcription.createdAt, style: .date)
                        .font(.headline)
                    Text(transcription.createdAt, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(transcription.wordCount) words")
                        .font(.subheadline)
                    if let duration = transcription.durationSeconds {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let transcriptionTime = transcription.transcriptionTimeSeconds {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text(formatTranscriptionTime(transcriptionTime))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            if transcription.provider != nil || transcription.modelName != nil {
                providerInfoView
            }

            Divider()

            if transcription.transcriptionStatus == .processing {
                processingView
            } else if transcription.text.isEmpty {
                emptyTextView
            } else {
                ScrollView {
                    Text(transcription.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider()

            HStack {
                Button(action: copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(transcription.text.isEmpty)
                .onHover { inside in
                    if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                if let fileName = transcription.audioFileName,
                   AudioStorageManager.shared.audioFileExists(fileName: fileName)
                {
                    Button(action: { AudioStorageManager.shared.revealInFinder(fileName: fileName) }) {
                        Label("Reveal Audio", systemImage: "folder")
                    }
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }

                    Button(action: {
                        Task {
                            await appState.retryTranscription(record: transcription)
                        }
                    }) {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }

                Spacer()

                Button(role: .destructive, action: deleteTranscription) {
                    Label("Delete", systemImage: "trash")
                }
                .onHover { inside in
                    if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
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
        modelContext.delete(transcription)
        onDelete?()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatTranscriptionTime(_ seconds: Double) -> String {
        if seconds < 1 {
            return String(format: "%.0fms", seconds * 1000)
        } else if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let secs = seconds.truncatingRemainder(dividingBy: 60)
            return String(format: "%dm %.1fs", minutes, secs)
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcription.text, forType: .string)
    }
}
