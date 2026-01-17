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

            if selectedProvider == .openAI {
                self.openAISettings
            } else {
                self.localWhisperSettings
            }
        }
    }

    private func providerOption(_ provider: TranscriptionProvider) -> some View {
        Button(action: { selectedProvider = provider }) {
            HStack {
                Image(systemName: selectedProvider == provider ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedProvider == provider ? .accentColor : .secondary)
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

                if provider == .openAI && !apiKey.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else if provider == .localWhisper && modelManager.isModelDownloaded(selectedModel) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(selectedProvider == provider ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedProvider == provider ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
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

            if !apiKey.isEmpty {
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
        VStack(spacing: 20) {
            self.settingsCard("Model Selection") {
                VStack(spacing: 8) {
                    ForEach(WhisperModel.allCases, id: \.self) { model in
                        self.modelOption(model)
                    }
                }
            }

            if !modelManager.isModelDownloaded(selectedModel) {
                self.modelDownloadCard
            } else {
                self.modelReadyCard
            }
        }
    }

    private func modelOption(_ model: WhisperModel) -> some View {
        Button(action: { selectedModel = model }) {
            HStack {
                Image(systemName: selectedModel == model ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedModel == model ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(model.displayName)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(model.sizeDescription)
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

                if modelManager.isModelDownloaded(model) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else if case .downloading(let progress) = modelManager.downloadStatus[model] {
                    ProgressView(value: progress)
                        .frame(width: 60)
                }
            }
            .padding(10)
            .background(selectedModel == model ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var modelDownloadCard: some View {
        self.settingsCard("Download Model") {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Download \(selectedModel.displayName) Model")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Size: \(selectedModel.sizeDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                if case .downloading(let progress) = modelManager.downloadStatus[selectedModel] {
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                        HStack {
                            Text("Downloading... \(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Cancel") {
                                modelManager.cancelDownload()
                            }
                            .font(.caption)
                        }
                    }
                } else if case .error(let message) = modelManager.downloadStatus[selectedModel] {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                        Spacer()
                    }

                    Button("Retry Download") {
                        modelManager.downloadModel(selectedModel)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Download Model") {
                        modelManager.downloadModel(selectedModel)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var modelReadyCard: some View {
        self.settingsCard("Model Status") {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedModel.displayName) model ready")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Local transcription is available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Delete") {
                    try? modelManager.deleteModel(selectedModel)
                }
                .foregroundColor(.red)
            }
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

                    Text("A simple, open-source voice transcription app for macOS using OpenAI's Whisper API or local Whisper models.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
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
    }

    private func saveSettings() {
        self.settings.apiKey = self.apiKey
        self.settings.language = self.language.isEmpty ? nil : self.language
        self.settings.transcriptionProvider = self.selectedProvider
        self.settings.selectedWhisperModel = self.selectedModel

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
