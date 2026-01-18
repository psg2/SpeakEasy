import AppKit
import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case providers = "Providers"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .providers: "server.rack"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var modelManager = WhisperModelManager.shared

    @State private var selectedTab: SettingsTab = .general
    @State private var apiKey: String = ""
    @State private var language: String = ""
    @State private var shortcutKeyCode: Int = 49
    @State private var shortcutModifierFlags: Int = 2048
    @State private var selectedProvider: TranscriptionProvider = .openAI
    @State private var selectedModel: WhisperModel = .base
    @State private var selectedModelId: String = "openai_whisper-base"
    @State private var showAllModels: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            self.sidebar
            Divider()
            self.contentArea
        }
        .frame(width: 800, height: 600)
        .onAppear {
            self.loadSettings()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SETTINGS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            ForEach(SettingsTab.allCases, id: \.self) { tab in
                self.sidebarItem(tab)
            }

            Spacer()

            Text("OpenVoicy v1.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(16)
        }
        .frame(width: 160)
        .background(Color.secondary.opacity(0.05))
    }

    private func sidebarItem(_ tab: SettingsTab) -> some View {
        Button(action: { self.selectedTab = tab }) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.body)
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.body)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(self.selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        VStack(spacing: 0) {
            HStack {
                Text(self.selectedTab.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    switch self.selectedTab {
                    case .general:
                        self.generalContent
                    case .providers:
                        self.providersContent
                    case .about:
                        self.aboutContent
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    self.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    self.saveSettings()
                    self.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
    }

    // MARK: - General Tab

    private var generalContent: some View {
        VStack(spacing: 20) {
            self.settingsCard("Transcription") {
                self.settingsRow(
                    title: "Language",
                    description: "Optional language code (e.g. 'en', 'pt', 'es')")
                {
                    TextField("Auto-detect", text: self.$language)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }
            }

            self.settingsCard("Keyboard Shortcut") {
                self.settingsRow(
                    title: "Global Shortcut",
                    description: "Press to start/stop recording from any app")
                {
                    ShortcutInputView(keyCode: self.$shortcutKeyCode, modifiers: self.$shortcutModifierFlags)
                }
            }
        }
    }

    // MARK: - Providers Tab

    private var providersContent: some View {
        VStack(spacing: 20) {
            self.settingsCard("Transcription Provider") {
                VStack(spacing: 12) {
                    ForEach(TranscriptionProvider.allCases, id: \.self) { provider in
                        self.providerOption(provider)
                    }
                }
            }

            if self.selectedProvider == .openAI {
                self.openAISettings
            } else {
                self.localWhisperSettings
            }
        }
    }

    private func providerOption(_ provider: TranscriptionProvider) -> some View {
        Button(action: { self.selectedProvider = provider }) {
            HStack {
                Image(systemName: self.selectedProvider == provider ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(self.selectedProvider == provider ? .accentColor : .secondary)
                    .font(.title3)

                Image(systemName: provider.icon)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(provider.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if provider == .openAI, !self.apiKey.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else if provider == .localWhisper, self.modelManager.isModelDownloaded(self.selectedModel) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(self.selectedProvider == provider ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        self.selectedProvider == provider ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var openAISettings: some View {
        self.settingsCard("OpenAI API") {
            self.settingsRow(
                title: "API Key",
                description: "Your OpenAI API key for Whisper transcription")
            {
                SecureField("sk-...", text: self.$apiKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
            }

            if !self.apiKey.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API key configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }

    private var localWhisperSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Model Selection")
                    .font(.headline)

                Spacer()

                if self.modelManager.isLoadingModels {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Button(action: { self.modelManager.openModelsFolder() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text("Show in Finder")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 12) {
                // Recommended models (always shown)
                VStack(spacing: 8) {
                    ForEach(WhisperModel.allCases, id: \.self) { model in
                        self.modelOption(model)
                    }
                }

                // Toggle to show all models
                Divider()

                Button(action: { withAnimation { self.showAllModels.toggle() } }) {
                    HStack {
                        Text(self
                            .showAllModels ? "Hide additional models" :
                            "Show all \(self.modelManager.availableModels.count) models")
                            .font(.caption)
                        Image(systemName: self.showAllModels ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                // Additional models (from HuggingFace)
                if self.showAllModels {
                    VStack(spacing: 8) {
                        ForEach(self.additionalModels) { model in
                            self.dynamicModelOption(model)
                        }
                    }
                }

                if let error = currentModelError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(10)
        }
    }

    /// Models from HuggingFace that aren't in the recommended list
    private var additionalModels: [WhisperKitModel] {
        let recommendedIds = Set(WhisperModel.allCases.map(\.whisperKitName))
        return self.modelManager.availableModels.filter { !recommendedIds.contains($0.id) }
    }

    private var currentModelError: String? {
        if case let .error(message) = modelManager.getStatus(for: selectedModel) {
            return message
        }
        return nil
    }

    private func modelOption(_ model: WhisperModel) -> some View {
        let isSelected = self.selectedModelId == model.whisperKitName
        return Button(action: {
            self.selectedModel = model
            self.selectedModelId = model.whisperKitName
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(model.displayName)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(self.modelManager.getModelSizeDescription(model.whisperKitName))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(model.qualityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                self.modelActionButton(for: model.whisperKitName)
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dynamic Model Option (for HuggingFace models)

    private func dynamicModelOption(_ model: WhisperKitModel) -> some View {
        let isSelected = self.selectedModelId == model.id
        return Button(action: {
            self.selectedModelId = model.id
            // Clear enum selection since we're using a dynamic model
            self.selectedModel = .base // Reset to default, but we'll use selectedModelId
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(model.displayName)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(self.modelManager.getModelSizeDescription(model.id))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(model.qualityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                self.modelActionButton(for: model.id)
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    /// Unified action button for model download/delete operations.
    /// Works with both WhisperModel enum (via whisperKitName) and WhisperKitModel (via id).
    @ViewBuilder
    private func modelActionButton(for modelId: String) -> some View {
        let status = self.modelManager.getStatus(for: modelId)

        switch status {
        case .downloaded:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)

                Button(action: { try? self.modelManager.deleteModel(modelId) }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete model")
            }

        case let .downloading(progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 60)

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 32, alignment: .trailing)

                Button(action: { self.modelManager.cancelDownload() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel download")
            }

        case .notDownloaded:
            Button(action: { self.modelManager.downloadModel(modelId) }) {
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(self.modelManager.isDownloading)
            .opacity(self.modelManager.isDownloading ? 0.5 : 1)
            .help("Download model")

        case .error:
            Button(action: { self.modelManager.downloadModel(modelId) }) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .disabled(self.modelManager.isDownloading)
            .help("Retry download")
        }
    }

    // MARK: - About Tab

    private var aboutContent: some View {
        VStack(spacing: 20) {
            self.settingsCard("About OpenVoicy") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.linearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("OpenVoicy")
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

            self.settingsCard("Diagnostics") {
                VStack(alignment: .leading, spacing: 12) {
                    self.settingsRow(
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

                    self.settingsRow(
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

    // MARK: - Helper Views

    private func settingsCard(
        _ title: String,
        @ViewBuilder content: () -> some View) -> some View
    {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(10)
        }
    }

    private func settingsRow(
        title: String,
        description: String,
        @ViewBuilder content: () -> some View) -> some View
    {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            content()
        }
    }

    // MARK: - Settings Logic

    private func loadSettings() {
        self.apiKey = self.settings.apiKey
        self.language = self.settings.language ?? ""
        self.shortcutKeyCode = self.settings.shortcutKeyCode
        self.shortcutModifierFlags = self.settings.shortcutModifierFlags
        self.selectedProvider = self.settings.transcriptionProvider
        self.selectedModel = self.settings.selectedWhisperModel
        self.selectedModelId = self.settings.selectedModelId
    }

    private func saveSettings() {
        self.settings.apiKey = self.apiKey
        self.settings.language = self.language.isEmpty ? nil : self.language
        self.settings.transcriptionProvider = self.selectedProvider
        self.settings.selectedWhisperModel = self.selectedModel
        self.settings.selectedModelId = self.selectedModelId

        if self.settings.shortcutKeyCode != self.shortcutKeyCode ||
            self.settings.shortcutModifierFlags != self.shortcutModifierFlags
        {
            self.settings.shortcutKeyCode = self.shortcutKeyCode
            self.settings.shortcutModifierFlags = self.shortcutModifierFlags

            GlobalShortcutManager.shared.registerShortcut(
                key: self.shortcutKeyCode,
                modifiers: self.shortcutModifierFlags)
        }
    }
}
