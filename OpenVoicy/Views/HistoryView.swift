import AppKit
import SwiftData
import SwiftUI

struct HistoryView: View {
    @ObservedObject var appState: AppState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TranscriptionRecord.createdAt, order: .reverse)
    private var transcriptions: [TranscriptionRecord]

    @State private var showSettings = false
    @State private var selectedTranscription: TranscriptionRecord?
    @State private var searchText = ""

    private var groupedTranscriptions: [(String, [TranscriptionRecord])] {
        let filtered =
            searchText.isEmpty
            ? transcriptions
            : transcriptions.filter { $0.text.localizedCaseInsensitiveContains(searchText) }

        let grouped = Dictionary(grouping: filtered) { record in
            Calendar.current.startOfDay(for: record.createdAt)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (formatDateHeader($0.key), $0.value) }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                headerView

                Divider()

                searchBar

                if transcriptions.isEmpty {
                    emptyStateView
                } else {
                    transcriptionList
                }

                statusBar
            }
        } detail: {
            if let selected = selectedTranscription {
                TranscriptionDetailView(transcription: selected, appState: appState)
            } else {
                Text("Select a transcription")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var headerView: some View {
        HStack {
            Text("OpenVoicy")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            if appState.state != .idle {
                recordingIndicator
            }

            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding()
    }

    private var recordingIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(appState.state == .recording ? Color.red : Color.orange)
                .frame(width: 8, height: 8)

            Text(appState.state == .recording ? "Recording" : "Processing")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search transcriptions...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "waveform.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Transcriptions Yet")
                .font(.title3)
                .fontWeight(.medium)

            Text("Press \(shortcutDisplayText) to start recording")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shortcutDisplayText: String {
        KeyboardUtils.string(
            for: SettingsManager.shared.shortcutKeyCode,
            modifiers: SettingsManager.shared.shortcutModifierFlags
        )
    }

    private var transcriptionList: some View {
        List(selection: $selectedTranscription) {
            ForEach(groupedTranscriptions, id: \.0) { dateString, records in
                Section(header: Text(dateString).font(.headline)) {
                    ForEach(records) { record in
                        TranscriptionRowView(transcription: record)
                            .tag(record)
                            .contextMenu {
                                contextMenuItems(for: record)
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func contextMenuItems(for record: TranscriptionRecord) -> some View {
        Button("Copy") {
            copyTranscription(record)
        }

        if let fileName = record.audioFileName,
           AudioStorageManager.shared.audioFileExists(fileName: fileName)
        {
            Button("Reveal Audio in Finder") {
                AudioStorageManager.shared.revealInFinder(fileName: fileName)
            }

            Button("Retry Transcription") {
                Task {
                    await appState.retryTranscription(record: record)
                }
            }
        }

        Divider()

        Button("Delete", role: .destructive) {
            deleteTranscription(record)
        }
    }

    private var statusBar: some View {
        HStack {
            Text("\(transcriptions.count) transcriptions")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func copyTranscription(_ record: TranscriptionRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.text, forType: .string)
    }

    private func deleteTranscription(_ record: TranscriptionRecord) {
        if let fileName = record.audioFileName {
            try? AudioStorageManager.shared.deleteAudio(fileName: fileName)
        }

        if selectedTranscription?.id == record.id {
            selectedTranscription = nil
        }

        modelContext.delete(record)
    }
}
