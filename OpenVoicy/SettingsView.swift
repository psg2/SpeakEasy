import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Settings")) {
                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Language (Optional, e.g. 'en')", text: Binding(
                    get: { settings.language ?? "" },
                    set: { settings.language = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section(header: Text("Shortcuts")) {
                TextField("Global Shortcut", text: $settings.shortcut)
                    .help("Example: Option+Space")
                Text("Changes require app restart or re-registration logic.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Behavior")) {
                Picker("Recording Mode", selection: $settings.recordingMode) {
                    Text("Press to Toggle").tag("pressToToggle")
                    Text("Hold to Record").tag("holdToRecord")
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
