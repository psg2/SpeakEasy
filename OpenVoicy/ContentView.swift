import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 20) {
            Text("OpenVoicy")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(statusText)
                .font(.headline)
                .foregroundColor(statusColor)

            if !appState.lastTranscription.isEmpty {
                VStack(alignment: .leading) {
                    Text("Last Transcription:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(appState.lastTranscription)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if let error = appState.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button(action: {
                    appState.toggleRecording()
                }, label: {
                    HStack {
                        Text(appState.state == .recording ? "Stop Recording" : "Start Recording")
                        Image(systemName: appState.state == .recording ? "stop.circle.fill" : "mic.circle.fill")
                    }
                })
                .keyboardShortcut(" ", modifiers: .option) // Local shortcut for testing

                Button(action: {
                    showSettings = true
                }, label: {
                    Image(systemName: "gear")
                })
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }

    var statusText: String {
        switch appState.state {
        case .idle: return "Ready"
        case .recording: return "Recording..."
        case .processing: return "Processing..."
        }
    }

    var statusColor: Color {
        switch appState.state {
        case .idle: return .primary
        case .recording: return .red
        case .processing: return .orange
        }
    }
}
