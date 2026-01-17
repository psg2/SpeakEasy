import SwiftUI

struct TranscriptionRowView: View {
    let transcription: TranscriptionRecord

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(timeFormatter.string(from: transcription.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    if let time = transcription.transcriptionTimeSeconds {
                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.caption2)
                            Text(formatTranscriptionTime(time))
                                .font(.caption)
                        }
                        .foregroundColor(.orange.opacity(0.8))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "textformat.size")
                            .font(.caption2)
                        Text("\(transcription.wordCount) words")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Text(transcription.text)
                .font(.body)
                .lineLimit(2)
                .truncationMode(.tail)

            if transcription.transcriptionStatus == .failed {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Transcription failed")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else if transcription.transcriptionStatus == .processing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            providerModelChips
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var providerModelChips: some View {
        if transcription.provider != nil || transcription.modelName != nil {
            HStack(spacing: 6) {
                if let provider = transcription.provider {
                    HStack(spacing: 3) {
                        Image(systemName: provider.icon)
                        Text(provider == .openAI ? "API" : "Local")
                    }
                    .font(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
                }

                if let modelName = transcription.modelName {
                    HStack(spacing: 3) {
                        Image(systemName: "cpu")
                        Text(modelName)
                    }
                    .font(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
                }
            }
            .foregroundColor(.secondary)
        } else if let fileName = transcription.audioFileName,
                  AudioStorageManager.shared.audioFileExists(fileName: fileName)
        {
            HStack(spacing: 4) {
                Image(systemName: "waveform")
                    .font(.caption2)
                Text("Audio saved")
                    .font(.caption2)
            }
            .foregroundColor(.secondary.opacity(0.7))
        }
    }

    private func formatTranscriptionTime(_ seconds: Double) -> String {
        if seconds < 1 {
            return String(format: "%.0fms", seconds * 1000)
        } else if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let secs = seconds.truncatingRemainder(dividingBy: 60)
            return String(format: "%dm %.0fs", minutes, secs)
        }
    }
}
