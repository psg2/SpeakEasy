import AppKit
import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            SettingsCard("About SpeakEasy") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.linearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SpeakEasy")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Text(
                        "A simple, open-source voice transcription app for macOS using OpenAI's Whisper API or local Whisper models.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            SettingsCard("Diagnostics") {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsRow(
                        title: "View Logs",
                        description: "Open log file with detailed timing info")
                    {
                        HStack(spacing: 8) {
                            Button(action: { FileLogger.shared.openLogFile() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                    Text("Open Log")
                                }
                            }
                            .buttonStyle(.bordered)

                            Button(action: { FileLogger.shared.revealLogsInFinder() }) {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.bordered)
                            .help("Reveal in Finder")
                        }
                    }

                    Divider()

                    SettingsRow(
                        title: "Audio Files",
                        description: "Open the folder containing recorded audio files")
                    {
                        Button(action: self.openAudioFolder) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                Text("Open Folder")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func openAudioFolder() {
        let url = AudioStorageManager.shared.recordingsDirectory
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
}
