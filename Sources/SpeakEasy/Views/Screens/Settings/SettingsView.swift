import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var modelManager = WhisperModelManager.shared

    @State private var selectedTab: SettingsTab = .general
    @State private var apiKey: String = ""
    @State private var selectedLanguage: WhisperLanguage = .autoDetect
    @State private var shortcutKeyCode: Int = 49
    @State private var shortcutModifierFlags: Int = 2048
    @State private var selectedProvider: TranscriptionProvider = .openAI
    @State private var selectedModel: WhisperModel = .base
    @State private var selectedModelId: String = "openai_whisper-base"
    @State private var showAllModels: Bool = false
    @State private var showApiKey: Bool = false
    @State private var isValidatingApiKey: Bool = false
    @State private var apiKeyValidationResult: ApiKeyValidationResult?
    @State private var snippets: [String: String] = [:]
    @State private var whisperPrompt: String = ""

    private var canSave: Bool {
        guard self.selectedProvider == .openAI, !self.apiKey.isEmpty else {
            return true
        }
        if case .success = self.apiKeyValidationResult {
            return true
        }
        return false
    }

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

            Text("SpeakEasy v1.0")
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
                        GeneralSettingsView(
                            selectedLanguage: self.$selectedLanguage,
                            whisperPrompt: self.$whisperPrompt,
                            shortcutKeyCode: self.$shortcutKeyCode,
                            shortcutModifierFlags: self.$shortcutModifierFlags)
                    case .snippets:
                        SnippetsSettingsView(snippets: self.$snippets)
                    case .providers:
                        ProvidersSettingsView(
                            modelManager: self.modelManager,
                            selectedProvider: self.$selectedProvider,
                            apiKey: self.$apiKey,
                            selectedModel: self.$selectedModel,
                            selectedModelId: self.$selectedModelId,
                            showAllModels: self.$showAllModels,
                            showApiKey: self.$showApiKey,
                            isValidatingApiKey: self.$isValidatingApiKey,
                            apiKeyValidationResult: self.$apiKeyValidationResult)
                    case .about:
                        AboutSettingsView()
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
                .disabled(!self.canSave)
            }
            .padding(16)
        }
    }

    // MARK: - Settings Logic

    private func loadSettings() {
        self.apiKey = self.settings.apiKey

        // Load language from settings
        if let languageCode = self.settings.language {
            self.selectedLanguage = WhisperLanguage.allLanguages.first(where: { $0.id == languageCode })
                ?? WhisperLanguage.autoDetect
        } else {
            self.selectedLanguage = WhisperLanguage.autoDetect
        }

        self.shortcutKeyCode = self.settings.shortcutKeyCode
        self.shortcutModifierFlags = self.settings.shortcutModifierFlags
        self.selectedProvider = self.settings.transcriptionProvider
        self.selectedModel = self.settings.selectedWhisperModel
        self.selectedModelId = self.settings.selectedModelId
        self.snippets = self.settings.snippets
        self.whisperPrompt = self.settings.whisperPrompt
    }

    private func saveSettings() {
        self.settings.apiKey = self.apiKey

        // Save language to settings (nil if auto-detect)
        self.settings.language = self.selectedLanguage.id.isEmpty ? nil : self.selectedLanguage.id

        self.settings.transcriptionProvider = self.selectedProvider
        self.settings.selectedWhisperModel = self.selectedModel
        self.settings.selectedModelId = self.selectedModelId
        self.settings.snippets = self.snippets
        self.settings.whisperPrompt = self.whisperPrompt

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
