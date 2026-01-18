import AppKit
import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case snippets = "Snippets"
    case providers = "Providers"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .snippets: "text.badge.plus"
        case .providers: "server.rack"
        case .about: "info.circle"
        }
    }
}

struct WhisperLanguage: Identifiable, Hashable {
    let id: String // ISO 639-1 code
    let name: String
    let flag: String

    var displayText: String {
        "\(self.flag) \(self.name)"
    }

    func matches(_ query: String) -> Bool {
        let lowercasedQuery = query.lowercased()
        return self.name.lowercased().contains(lowercasedQuery) ||
            self.id.lowercased().contains(lowercasedQuery)
    }

    static let autoDetect = WhisperLanguage(id: "", name: "Auto-detect", flag: "🌐")

    static let allLanguages: [WhisperLanguage] = [
        WhisperLanguage(id: "en", name: "English", flag: "🇬🇧"),
        WhisperLanguage(id: "zh", name: "Chinese", flag: "🇨🇳"),
        WhisperLanguage(id: "de", name: "German", flag: "🇩🇪"),
        WhisperLanguage(id: "es", name: "Spanish", flag: "🇪🇸"),
        WhisperLanguage(id: "ru", name: "Russian", flag: "🇷🇺"),
        WhisperLanguage(id: "ko", name: "Korean", flag: "🇰🇷"),
        WhisperLanguage(id: "fr", name: "French", flag: "🇫🇷"),
        WhisperLanguage(id: "ja", name: "Japanese", flag: "🇯🇵"),
        WhisperLanguage(id: "pt", name: "Portuguese", flag: "🇵🇹"),
        WhisperLanguage(id: "tr", name: "Turkish", flag: "🇹🇷"),
        WhisperLanguage(id: "pl", name: "Polish", flag: "🇵🇱"),
        WhisperLanguage(id: "ca", name: "Catalan", flag: "🇪🇸"),
        WhisperLanguage(id: "nl", name: "Dutch", flag: "🇳🇱"),
        WhisperLanguage(id: "ar", name: "Arabic", flag: "🇸🇦"),
        WhisperLanguage(id: "sv", name: "Swedish", flag: "🇸🇪"),
        WhisperLanguage(id: "it", name: "Italian", flag: "🇮🇹"),
        WhisperLanguage(id: "id", name: "Indonesian", flag: "🇮🇩"),
        WhisperLanguage(id: "hi", name: "Hindi", flag: "🇮🇳"),
        WhisperLanguage(id: "fi", name: "Finnish", flag: "🇫🇮"),
        WhisperLanguage(id: "vi", name: "Vietnamese", flag: "🇻🇳"),
        WhisperLanguage(id: "he", name: "Hebrew", flag: "🇮🇱"),
        WhisperLanguage(id: "uk", name: "Ukrainian", flag: "🇺🇦"),
        WhisperLanguage(id: "el", name: "Greek", flag: "🇬🇷"),
        WhisperLanguage(id: "ms", name: "Malay", flag: "🇲🇾"),
        WhisperLanguage(id: "cs", name: "Czech", flag: "🇨🇿"),
        WhisperLanguage(id: "ro", name: "Romanian", flag: "🇷🇴"),
        WhisperLanguage(id: "da", name: "Danish", flag: "🇩🇰"),
        WhisperLanguage(id: "hu", name: "Hungarian", flag: "🇭🇺"),
        WhisperLanguage(id: "ta", name: "Tamil", flag: "🇮🇳"),
        WhisperLanguage(id: "no", name: "Norwegian", flag: "🇳🇴"),
        WhisperLanguage(id: "th", name: "Thai", flag: "🇹🇭"),
        WhisperLanguage(id: "ur", name: "Urdu", flag: "🇵🇰"),
        WhisperLanguage(id: "hr", name: "Croatian", flag: "🇭🇷"),
        WhisperLanguage(id: "bg", name: "Bulgarian", flag: "🇧🇬"),
        WhisperLanguage(id: "lt", name: "Lithuanian", flag: "🇱🇹"),
        WhisperLanguage(id: "la", name: "Latin", flag: "🇻🇦"),
        WhisperLanguage(id: "mi", name: "Maori", flag: "🇳🇿"),
        WhisperLanguage(id: "ml", name: "Malayalam", flag: "🇮🇳"),
        WhisperLanguage(id: "cy", name: "Welsh", flag: "🏴󠁧󠁢󠁷󠁬󠁳󠁿"),
        WhisperLanguage(id: "sk", name: "Slovak", flag: "🇸🇰"),
        WhisperLanguage(id: "te", name: "Telugu", flag: "🇮🇳"),
        WhisperLanguage(id: "fa", name: "Persian", flag: "🇮🇷"),
        WhisperLanguage(id: "lv", name: "Latvian", flag: "🇱🇻"),
        WhisperLanguage(id: "bn", name: "Bengali", flag: "🇧🇩"),
        WhisperLanguage(id: "sr", name: "Serbian", flag: "🇷🇸"),
        WhisperLanguage(id: "az", name: "Azerbaijani", flag: "🇦🇿"),
        WhisperLanguage(id: "sl", name: "Slovenian", flag: "🇸🇮"),
        WhisperLanguage(id: "kn", name: "Kannada", flag: "🇮🇳"),
        WhisperLanguage(id: "et", name: "Estonian", flag: "🇪🇪"),
        WhisperLanguage(id: "mk", name: "Macedonian", flag: "🇲🇰"),
        WhisperLanguage(id: "br", name: "Breton", flag: "🇫🇷"),
        WhisperLanguage(id: "eu", name: "Basque", flag: "🇪🇸"),
        WhisperLanguage(id: "is", name: "Icelandic", flag: "🇮🇸"),
        WhisperLanguage(id: "hy", name: "Armenian", flag: "🇦🇲"),
        WhisperLanguage(id: "ne", name: "Nepali", flag: "🇳🇵"),
        WhisperLanguage(id: "mn", name: "Mongolian", flag: "🇲🇳"),
        WhisperLanguage(id: "bs", name: "Bosnian", flag: "🇧🇦"),
        WhisperLanguage(id: "kk", name: "Kazakh", flag: "🇰🇿"),
        WhisperLanguage(id: "sq", name: "Albanian", flag: "🇦🇱"),
        WhisperLanguage(id: "sw", name: "Swahili", flag: "🇹🇿"),
        WhisperLanguage(id: "gl", name: "Galician", flag: "🇪🇸"),
        WhisperLanguage(id: "mr", name: "Marathi", flag: "🇮🇳"),
        WhisperLanguage(id: "pa", name: "Punjabi", flag: "🇮🇳"),
        WhisperLanguage(id: "si", name: "Sinhala", flag: "🇱🇰"),
        WhisperLanguage(id: "km", name: "Khmer", flag: "🇰🇭"),
        WhisperLanguage(id: "sn", name: "Shona", flag: "🇿🇼"),
        WhisperLanguage(id: "yo", name: "Yoruba", flag: "🇳🇬"),
        WhisperLanguage(id: "so", name: "Somali", flag: "🇸🇴"),
        WhisperLanguage(id: "af", name: "Afrikaans", flag: "🇿🇦"),
        WhisperLanguage(id: "oc", name: "Occitan", flag: "🇫🇷"),
        WhisperLanguage(id: "ka", name: "Georgian", flag: "🇬🇪"),
        WhisperLanguage(id: "be", name: "Belarusian", flag: "🇧🇾"),
        WhisperLanguage(id: "tg", name: "Tajik", flag: "🇹🇯"),
        WhisperLanguage(id: "sd", name: "Sindhi", flag: "🇵🇰"),
        WhisperLanguage(id: "gu", name: "Gujarati", flag: "🇮🇳"),
        WhisperLanguage(id: "am", name: "Amharic", flag: "🇪🇹"),
        WhisperLanguage(id: "yi", name: "Yiddish", flag: "🇮🇱"),
        WhisperLanguage(id: "lo", name: "Lao", flag: "🇱🇦"),
        WhisperLanguage(id: "uz", name: "Uzbek", flag: "🇺🇿"),
        WhisperLanguage(id: "fo", name: "Faroese", flag: "🇫🇴"),
        WhisperLanguage(id: "ht", name: "Haitian Creole", flag: "🇭🇹"),
        WhisperLanguage(id: "ps", name: "Pashto", flag: "🇦🇫"),
        WhisperLanguage(id: "tk", name: "Turkmen", flag: "🇹🇲"),
        WhisperLanguage(id: "nn", name: "Nynorsk", flag: "🇳🇴"),
        WhisperLanguage(id: "mt", name: "Maltese", flag: "🇲🇹"),
        WhisperLanguage(id: "sa", name: "Sanskrit", flag: "🇮🇳"),
        WhisperLanguage(id: "lb", name: "Luxembourgish", flag: "🇱🇺"),
        WhisperLanguage(id: "my", name: "Myanmar", flag: "🇲🇲"),
        WhisperLanguage(id: "bo", name: "Tibetan", flag: "🇨🇳"),
        WhisperLanguage(id: "tl", name: "Tagalog", flag: "🇵🇭"),
        WhisperLanguage(id: "mg", name: "Malagasy", flag: "🇲🇬"),
        WhisperLanguage(id: "as", name: "Assamese", flag: "🇮🇳"),
        WhisperLanguage(id: "tt", name: "Tatar", flag: "🇷🇺"),
        WhisperLanguage(id: "haw", name: "Hawaiian", flag: "🇺🇸"),
        WhisperLanguage(id: "ln", name: "Lingala", flag: "🇨🇩"),
        WhisperLanguage(id: "ha", name: "Hausa", flag: "🇳🇬"),
        WhisperLanguage(id: "ba", name: "Bashkir", flag: "🇷🇺"),
        WhisperLanguage(id: "jw", name: "Javanese", flag: "🇮🇩"),
        WhisperLanguage(id: "su", name: "Sundanese", flag: "🇮🇩"),
        WhisperLanguage(id: "yue", name: "Cantonese", flag: "🇭🇰"),
    ]
}

struct LanguageSearchField: View {
    @Binding var selectedLanguage: WhisperLanguage
    @State private var isShowingPopover: Bool = false

    var body: some View {
        Button(action: {
            self.isShowingPopover.toggle()
        }) {
            HStack(spacing: 8) {
                Text(self.selectedLanguage.flag)
                    .font(.title3)

                Text(self.selectedLanguage.name)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(self.isShowingPopover ? 180 : 0))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(width: 220)
        .popover(isPresented: self.$isShowingPopover, arrowEdge: .bottom) {
            LanguagePickerPopover(
                selectedLanguage: self.$selectedLanguage,
                isPresented: self.$isShowingPopover)
        }
    }
}

struct LanguagePickerPopover: View {
    @Binding var selectedLanguage: WhisperLanguage
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    @State private var highlightedIndex: Int = 0
    @State private var displayedLanguages: [WhisperLanguage] = []
    @FocusState private var isSearchFocused: Bool

    private static let allOptions: [WhisperLanguage] = [WhisperLanguage.autoDetect] + WhisperLanguage.allLanguages

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search language...", text: self.$searchText)
                    .textFieldStyle(.plain)
                    .focused(self.$isSearchFocused)
                    .onSubmit {
                        self.selectHighlightedLanguage()
                    }
                if !self.searchText.isEmpty {
                    Button(action: {
                        self.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(self.displayedLanguages.enumerated()), id: \.element.id) { index, language in
                            Button(action: {
                                self.selectLanguage(language)
                            }) {
                                HStack(spacing: 8) {
                                    Text(language.flag)
                                    Text(language.name)
                                        .lineLimit(1)
                                    Spacer()
                                    if language.id == self.selectedLanguage.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(index == self.highlightedIndex ? Color.accentColor.opacity(0.2) : Color
                                    .clear)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                }
                .onChange(of: self.highlightedIndex) {
                    withAnimation {
                        proxy.scrollTo(self.highlightedIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 240, height: 280)
        .onAppear {
            self.displayedLanguages = Self.allOptions
            self.isSearchFocused = true
        }
        .onChange(of: self.searchText) { _, newValue in
            self.filterLanguages(query: newValue)
        }
        .onKeyPress(.downArrow) {
            self.moveHighlight(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            self.moveHighlight(by: -1)
            return .handled
        }
        .onKeyPress(.escape) {
            self.isPresented = false
            return .handled
        }
    }

    private func filterLanguages(query: String) {
        self.highlightedIndex = 0
        if query.isEmpty {
            self.displayedLanguages = Self.allOptions
        } else {
            let lowercased = query.lowercased()
            self.displayedLanguages = Self.allOptions.filter { lang in
                lang.name.lowercased().contains(lowercased) || lang.id.lowercased().contains(lowercased)
            }
        }
    }

    private func moveHighlight(by offset: Int) {
        let newIndex = self.highlightedIndex + offset
        if newIndex >= 0, newIndex < self.displayedLanguages.count {
            self.highlightedIndex = newIndex
        }
    }

    private func selectHighlightedLanguage() {
        guard self.highlightedIndex < self.displayedLanguages.count else { return }
        self.selectLanguage(self.displayedLanguages[self.highlightedIndex])
    }

    private func selectLanguage(_ language: WhisperLanguage) {
        self.selectedLanguage = language
        self.isPresented = false
    }
}

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
    @State private var newSnippetKey: String = ""
    @State private var newSnippetValue: String = ""
    @State private var editingSnippetKey: String?
    @State private var showOverwriteConfirmation: Bool = false
    @State private var pendingSnippetKey: String = ""
    @State private var pendingSnippetValue: String = ""

    enum ApiKeyValidationResult {
        case success
        case failure(String)
    }

    private var canSave: Bool {
        // If OpenAI is selected and there's an API key, it must be validated successfully
        if self.selectedProvider == .openAI, !self.apiKey.isEmpty {
            if case .success = self.apiKeyValidationResult {
                return true
            }
            return false
        }
        return true
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
                    case .snippets:
                        self.snippetsContent
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
                .disabled(!self.canSave)
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
                    description: "Type to search or select from the list")
                {
                    LanguageSearchField(selectedLanguage: self.$selectedLanguage)
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

    // MARK: - Snippets Tab

    private var snippetsContent: some View {
        VStack(spacing: 20) {
            self.settingsCard("Text Snippets") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Snippets let you replace text in your transcriptions. When you say a snippet key, it will be automatically replaced with its value.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(spacing: 8) {
                        HStack {
                            Text("Add Snippet")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Key (what you say)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g., my email", text: self.$newSnippetKey)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Value (replacement)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g., foo@example.com", text: self.$newSnippetValue)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button(action: self.addSnippet) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .disabled(self.newSnippetKey.isEmpty || self.newSnippetValue.isEmpty)
                            .help("Add snippet")
                            .padding(.top, 18)
                        }
                    }

                    if !self.snippets.isEmpty {
                        Divider()

                        VStack(spacing: 8) {
                            ForEach(Array(self.snippets.keys.sorted()), id: \.self) { key in
                                self.snippetRow(key: key, value: self.snippets[key] ?? "")
                            }
                        }
                    }
                }
            }
        }
        .alert("Overwrite Snippet?", isPresented: self.$showOverwriteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Overwrite", role: .destructive) {
                self.confirmOverwrite()
            }
        } message: {
            Text("A snippet with key \"\(self.pendingSnippetKey)\" already exists. Do you want to overwrite it?")
        }
    }

    private func snippetRow(key: String, value: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(key)
                    .font(.body)
                    .fontWeight(.medium)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { self.deleteSnippet(key: key) }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete snippet")
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }

    private func addSnippet() {
        guard !self.newSnippetKey.isEmpty, !self.newSnippetValue.isEmpty else { return }

        if self.snippets[self.newSnippetKey] != nil {
            self.pendingSnippetKey = self.newSnippetKey
            self.pendingSnippetValue = self.newSnippetValue
            self.showOverwriteConfirmation = true
        } else {
            self.snippets[self.newSnippetKey] = self.newSnippetValue
            self.newSnippetKey = ""
            self.newSnippetValue = ""
        }
    }

    private func confirmOverwrite() {
        self.snippets[self.pendingSnippetKey] = self.pendingSnippetValue
        self.newSnippetKey = ""
        self.newSnippetValue = ""
        self.pendingSnippetKey = ""
        self.pendingSnippetValue = ""
    }

    private func deleteSnippet(key: String) {
        self.snippets.removeValue(forKey: key)
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
                HStack(spacing: 8) {
                    Group {
                        if self.showApiKey {
                            TextField("sk-...", text: self.$apiKey)
                        } else {
                            SecureField("sk-...", text: self.$apiKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .onChange(of: self.apiKey) {
                        self.apiKeyValidationResult = nil
                    }

                    Button(action: { self.showApiKey.toggle() }) {
                        Image(systemName: self.showApiKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(self.showApiKey ? "Hide API key" : "Show API key")
                }
            }

            if !self.apiKey.isEmpty {
                HStack {
                    if let result = self.apiKeyValidationResult {
                        switch result {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connection successful")
                                .font(.caption)
                                .foregroundColor(.green)
                        case let .failure(message):
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("API key not validated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if self.isValidatingApiKey {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Validating...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button(action: self.validateApiKey) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield")
                                Text("Validate")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func validateApiKey() {
        self.isValidatingApiKey = true
        self.apiKeyValidationResult = nil

        Task {
            do {
                try await OpenAIClient.shared.validateApiKey(self.apiKey)
                await MainActor.run {
                    self.isValidatingApiKey = false
                    self.apiKeyValidationResult = .success
                }
            } catch {
                await MainActor.run {
                    self.isValidatingApiKey = false
                    self.apiKeyValidationResult = .failure(error.localizedDescription)
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
    }

    private func saveSettings() {
        self.settings.apiKey = self.apiKey

        // Save language to settings (nil if auto-detect)
        self.settings.language = self.selectedLanguage.id.isEmpty ? nil : self.selectedLanguage.id

        self.settings.transcriptionProvider = self.selectedProvider
        self.settings.selectedWhisperModel = self.selectedModel
        self.settings.selectedModelId = self.selectedModelId
        self.settings.snippets = self.snippets

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
