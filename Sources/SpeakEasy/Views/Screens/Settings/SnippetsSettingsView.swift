import SwiftUI

struct SnippetsSettingsView: View {
    @Binding var snippets: [String: String]
    @State private var newSnippetKey: String = ""
    @State private var newSnippetValue: String = ""
    @State private var showOverwriteConfirmation: Bool = false
    @State private var pendingSnippetKey: String = ""
    @State private var pendingSnippetValue: String = ""

    var body: some View {
        VStack(spacing: 20) {
            SettingsCard("Text Snippets") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(
                        "Snippets let you replace text in your transcriptions. When you say a snippet key, it will be automatically replaced with its value.")
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
}
