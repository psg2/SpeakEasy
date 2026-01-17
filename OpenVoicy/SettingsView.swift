import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = SettingsManager.shared

    @State private var selectedTab: SettingsTab = .general
    @State private var apiKey: String = ""
    @State private var language: String = ""
    @State private var shortcutKeyCode: Int = 49
    @State private var shortcutModifierFlags: Int = 2048

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
            // Content header
            HStack {
                Text(self.selectedTab.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(20)

            Divider()

            // Content body
            ScrollView {
                VStack(spacing: 20) {
                    switch self.selectedTab {
                    case .general:
                        self.generalContent
                    case .about:
                        self.aboutContent
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer with buttons
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
            self.settingsCard("OpenAI API") {
                self.settingsRow(
                    title: "API Key",
                    description: "Your OpenAI API key for Whisper transcription")
                {
                    SecureField("sk-...", text: self.$apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                Divider()

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

                    Text("A simple, open-source voice transcription app for macOS using OpenAI's Whisper API.")
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
    }

    private func saveSettings() {
        self.settings.apiKey = self.apiKey
        self.settings.language = self.language.isEmpty ? nil : self.language

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
