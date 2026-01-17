import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 20) {
            Text("OpenVoicy")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(self.statusText)
                .font(.headline)
                .foregroundColor(self.statusColor)

            if !self.appState.lastTranscription.isEmpty {
                VStack(alignment: .leading) {
                    Text("Last Transcription:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(self.appState.lastTranscription)
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
                    self.appState.toggleRecording()
                }, label: {
                    HStack {
                        Text(self.appState.state == .recording ? "Stop Recording" : "Start Recording")
                        Image(systemName: self.appState.state == .recording ? "stop.circle.fill" : "mic.circle.fill")
                    }
                })
                .keyboardShortcut(" ", modifiers: .option) // Local shortcut for testing

                Button(action: {
                    self.showSettings = true
                }, label: {
                    Image(systemName: "gear")
                })
                .sheet(isPresented: self.$showSettings) {
                    SettingsView()
                }
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }

    var statusText: String {
        switch self.appState.state {
        case .idle: "Ready"
        case .recording: "Recording..."
        case .processing: "Processing..."
        }
    }

    var statusColor: Color {
        switch self.appState.state {
        case .idle: .primary
        case .recording: .red
        case .processing: .orange
        }
    }
}
