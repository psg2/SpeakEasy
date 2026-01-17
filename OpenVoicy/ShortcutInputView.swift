import SwiftUI

struct ShortcutInputView: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Global Shortcut")
                Spacer()
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }, label: {
                    Text(displayText)
                        .frame(minWidth: 100)
                        .padding(5)
                        .background(isRecording ? Color.accentColor : Color.secondary.opacity(0.2))
                        .foregroundColor(isRecording ? .white : .primary)
                        .cornerRadius(6)
                })
                .buttonStyle(PlainButtonStyle())
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private var displayText: String {
        if isRecording {
            return "Press keys..."
        }
        return KeyboardUtils.string(for: keyCode, modifiers: modifiers)
    }

    private func startRecording() {
        isRecording = true
        errorMessage = nil

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Ignore if just a modifier key is pressed (waiting for the actual key)
            if event.modifierFlags.contains(.command) ||
               event.modifierFlags.contains(.shift) ||
               event.modifierFlags.contains(.option) ||
               event.modifierFlags.contains(.control) {
               // Continue waiting
            }

            // Allow Escape to cancel recording
            if event.keyCode == 53 { // kVK_Escape
                stopRecording()
                return nil
            }

            let carbonModifiers = KeyboardUtils.carbonModifiers(from: event.modifierFlags)
            let carbonKey = Int(event.keyCode)

            // Validate
            let validation = ShortcutValidator.validate(keyCode: carbonKey, modifiers: carbonModifiers)

            switch validation {
            case .valid:
                self.keyCode = carbonKey
                self.modifiers = carbonModifiers
                stopRecording()
            case .invalid(let reason):
                self.errorMessage = reason
                // Keep recording? Or stop?
                // Usually user wants to try again immediately.
                // Let's keep recording but show error.
            }

            return nil // Consume event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
