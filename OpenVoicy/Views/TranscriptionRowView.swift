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

                HStack(spacing: 4) {
                    Image(systemName: "textformat.size")
                        .font(.caption2)
                    Text("\(transcription.wordCount) words")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
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

            if let fileName = transcription.audioFileName,
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
        .padding(.vertical, 4)
    }
}
