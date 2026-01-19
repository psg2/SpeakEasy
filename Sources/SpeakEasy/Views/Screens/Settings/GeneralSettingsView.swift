import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @Binding var selectedLanguage: WhisperLanguage
    @Binding var whisperPrompt: String
    @Binding var shortcutKeyCode: Int
    @Binding var shortcutModifierFlags: Int

    var body: some View {
        VStack(spacing: 20) {
            SettingsCard("Transcription") {
                SettingsRow(
                    title: "Language",
                    description: "Type to search or select from the list")
                {
                    LanguageSearchField(selectedLanguage: self.$selectedLanguage)
                }
            }

            SettingsCard("Whisper Prompt") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Provide context or custom words to improve transcription accuracy. Limited to ~224 tokens.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: self.$whisperPrompt)
                        .font(.body)
                        .frame(height: 80)
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1))

                    HStack {
                        Text("\(self.whisperPrompt.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if self.whisperPrompt.count > 800 {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Prompt may be truncated")
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                }
            }

            SettingsCard("Keyboard Shortcut") {
                SettingsRow(
                    title: "Global Shortcut",
                    description: "Press to start/stop recording from any app")
                {
                    ShortcutInputView(keyCode: self.$shortcutKeyCode, modifiers: self.$shortcutModifierFlags)
                }
            }
        }
    }
}
