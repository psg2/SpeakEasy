import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    // Local state for editing
    @State private var apiKey: String = ""
    @State private var language: String = ""
    @State private var shortcutKeyCode: Int = 49 // Space
    @State private var shortcutModifierFlags: Int = 2048 // Option
    @State private var recordingMode: String = "pressToToggle"

    var body: some View {
        Form {
            Section(header: Text("OpenAI Settings")) {
                SecureField("API Key", text: self.$apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Language (Optional, e.g. 'en')", text: self.$language)
            }

            Section(header: Text("Shortcuts")) {
                ShortcutInputView(keyCode: self.$shortcutKeyCode, modifiers: self.$shortcutModifierFlags)
            }

            Section(header: Text("Behavior")) {
                Picker("Recording Mode", selection: self.$recordingMode) {
                    Text("Press to Toggle").tag("pressToToggle")
                    Text("Hold to Record").tag("holdToRecord")
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear {
            self.loadSettings()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    self.dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    self.saveSettings()
                    self.dismiss()
                }
            }
        }
    }

    private func loadSettings() {
        let settings = SettingsManager.shared
        self.apiKey = settings.apiKey
        self.language = settings.language ?? ""
        self.shortcutKeyCode = settings.shortcutKeyCode
        self.shortcutModifierFlags = settings.shortcutModifierFlags
        self.recordingMode = settings.recordingMode
    }

    private func saveSettings() {
        let settings = SettingsManager.shared
        settings.apiKey = self.apiKey
        settings.language = self.language.isEmpty ? nil : self.language

        // Update shortcut only if changed
        if settings.shortcutKeyCode != self.shortcutKeyCode ||
            settings.shortcutModifierFlags != self.shortcutModifierFlags
        {
            settings.shortcutKeyCode = self.shortcutKeyCode
            settings.shortcutModifierFlags = self.shortcutModifierFlags

            // Re-register
            GlobalShortcutManager.shared.registerShortcut(
                key: self.shortcutKeyCode,
                modifiers: self.shortcutModifierFlags)
        }

        settings.recordingMode = self.recordingMode
    }
}
