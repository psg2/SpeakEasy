import AppKit
import SwiftData
import SwiftUI

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
}

public struct HistoryView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TranscriptionRecord.createdAt, order: .reverse)
    private var transcriptions: [TranscriptionRecord]

    @State private var selectedTranscription: TranscriptionRecord?
    @State private var searchText = ""

    private var groupedTranscriptions: [(String, [TranscriptionRecord])] {
        let filtered =
            self.searchText.isEmpty
                ? self.transcriptions
                : self.transcriptions.filter {
                    $0.text.range(of: self.searchText, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                }

        let grouped = Dictionary(grouping: filtered) { record in
            Calendar.current.startOfDay(for: record.createdAt)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (self.formatDateHeader($0.key), $0.value) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            self.headerView
            Divider()
            self.mainContent
        }
        .frame(minWidth: 700, minHeight: 500)
        .sheet(item: self.$selectedTranscription) { transcription in
            TranscriptionDetailView(
                transcription: transcription,
                appState: self.appState,
                onDelete: { self.selectedTranscription = nil })
                .frame(minWidth: 500, minHeight: 400)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                Text("OpenVoicy")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()

            if self.appState.state != .idle {
                self.recordingIndicator
            }

            Button(action: {
                NotificationCenter.default.post(name: .showSettings, object: nil)
            }) {
                Image(systemName: "gear")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
            .help("Settings (⌘,)")
        }
        .padding()
    }

    private var recordingIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(self.appState.state == .recording ? Color.red : Color.orange)
                .frame(width: 8, height: 8)

            Text(self.appState.state == .recording ? "Recording" : "Processing")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                self.statsAndSearchBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                if self.transcriptions.isEmpty {
                    self.emptyStateView
                        .frame(minHeight: 300)
                } else {
                    self.transcriptionTable
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var statsAndSearchBar: some View {
        VStack(spacing: 16) {
            if !self.transcriptions.isEmpty {
                self.statsBar
            }

            self.searchBar
        }
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            Spacer()

            self.statItem(
                icon: "doc.text.fill",
                value: "\(self.transcriptions.count)",
                label: "transcriptions",
                color: .blue)

            Spacer()

            Divider()
                .frame(height: 24)

            Spacer()

            self.statItem(icon: "textformat.size", value: "\(self.totalWordCount)", label: "words", color: .green)

            if let avgWPM = averageWordsPerMinute {
                Spacer()

                Divider()
                    .frame(height: 24)

                Spacer()

                self.statItem(icon: "speedometer", value: "\(avgWPM)", label: "WPM", color: .orange)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search transcriptions...", text: self.$searchText)
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.cyan, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))

            Text("Hold \(self.shortcutDisplayText) to dictate")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your transcriptions will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var shortcutDisplayText: String {
        KeyboardUtils.string(
            for: self.settings.shortcutKeyCode,
            modifiers: self.settings.shortcutModifierFlags)
    }

    // MARK: - Transcription Table

    private var transcriptionTable: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(self.groupedTranscriptions, id: \.0) { dateString, records in
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateString.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    VStack(spacing: 1) {
                        ForEach(records) { record in
                            TranscriptionTableRow(
                                transcription: record,
                                onCopy: { self.copyTranscription(record) },
                                onReveal: { self.revealAudio(record) },
                                onRetry: { Task { await self.appState.retryTranscription(record: record) } },
                                onDelete: { self.deleteTranscription(record) },
                                onSelect: { self.selectedTranscription = record })
                        }
                    }
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var averageWordsPerMinute: Int? {
        let recordsWithDuration = self.transcriptions.filter { ($0.durationSeconds ?? 0) > 0 }
        guard !recordsWithDuration.isEmpty else { return nil }

        let totalWords = recordsWithDuration.reduce(0) { $0 + $1.wordCount }
        let totalMinutes = recordsWithDuration.reduce(0.0) { $0 + ($1.durationSeconds ?? 0) } / 60.0

        guard totalMinutes > 0 else { return nil }
        return Int(Double(totalWords) / totalMinutes)
    }

    private var totalWordCount: Int {
        self.transcriptions.reduce(0) { $0 + $1.wordCount }
    }

    // MARK: - Helper Functions

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

    private func revealAudio(_ record: TranscriptionRecord) {
        if let fileName = record.audioFileName {
            AudioStorageManager.shared.revealInFinder(fileName: fileName)
        }
    }

    private func deleteTranscription(_ record: TranscriptionRecord) {
        if let fileName = record.audioFileName {
            try? AudioStorageManager.shared.deleteAudio(fileName: fileName)
        }
        self.modelContext.delete(record)
    }
}

// MARK: - Table Row

struct TranscriptionTableRow: View {
    let transcription: TranscriptionRecord
    let onCopy: () -> Void
    let onReveal: () -> Void
    let onRetry: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void

    @State private var isHovered = false

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            // Time column
            Text(self.timeFormatter.string(from: self.transcription.createdAt))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            // Text preview
            self.textPreview
                .frame(maxWidth: .infinity, alignment: .leading)

            // Metadata or action buttons
            if self.isHovered {
                self.actionButtons
            } else {
                self.metadataView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(self.isHovered ? Color.secondary.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                self.isHovered = hovering
            }
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .onTapGesture {
            self.onSelect()
        }
    }

    @ViewBuilder
    private var textPreview: some View {
        if self.transcription.transcriptionStatus == .processing {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Processing...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        } else if self.transcription.transcriptionStatus == .failed {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Transcription failed")
                    .font(.body)
                    .foregroundColor(.orange)
            }
        } else if self.transcription.text.isEmpty {
            Text("No transcription")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
        } else {
            Text(self.transcription.text)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var metadataView: some View {
        HStack(spacing: 12) {
            if let time = transcription.transcriptionTimeSeconds {
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text(time.formatAsTranscriptionTime())
                        .font(.caption)
                }
                .foregroundColor(.orange.opacity(0.8))
            }

            if let provider = transcription.provider {
                HStack(spacing: 3) {
                    Image(systemName: provider.icon)
                    Text(self.transcription.modelName ?? (provider == .openAI ? "API" : "Local"))
                }
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(4)
                .foregroundColor(.secondary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            Button(action: self.onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.body)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Copy")
            .handCursorOnHover()

            if self.transcription.audioFileName != nil {
                Button(action: self.onReveal) {
                    Image(systemName: "folder")
                        .font(.body)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                .handCursorOnHover()

                Button(action: self.onRetry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Retry transcription")
                .handCursorOnHover()
            }

            Button(action: self.onDelete) {
                Image(systemName: "trash")
                    .font(.body)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red.opacity(0.8))
            .help("Delete")
            .handCursorOnHover()
        }
        .foregroundColor(.secondary)
    }
}
