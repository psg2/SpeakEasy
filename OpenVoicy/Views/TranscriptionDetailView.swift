import AppKit
import SwiftUI

struct TranscriptionDetailView: View {
    let transcription: TranscriptionRecord
    @ObservedObject var appState: AppState

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
                }
            }

            Divider()

            ScrollView {
                Text(transcription.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                Button(action: copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                if let fileName = transcription.audioFileName,
                   AudioStorageManager.shared.audioFileExists(fileName: fileName)
                {
                    Button(action: { AudioStorageManager.shared.revealInFinder(fileName: fileName) }) {
                        Label("Reveal Audio", systemImage: "folder")
                    }

                    Button(action: {
                        Task {
                            await appState.retryTranscription(record: transcription)
                        }
                    }) {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                }

                Spacer()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcription.text, forType: .string)
    }
}
