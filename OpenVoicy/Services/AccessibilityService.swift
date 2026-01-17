import Foundation
import ApplicationServices
import AppKit

class AccessibilityService {
    static let shared = AccessibilityService()

    func checkPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func typeText(_ text: String) {
        let src = CGEventSource(stateID: .hidSystemState)

        for char in text {
            if let eventDown = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true),
               let eventUp = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false) {

                var charCode = Array(String(char).utf16)[0]
                eventDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charCode)
                eventUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charCode)

                eventDown.post(tap: .cghidEventTap)
                eventUp.post(tap: .cghidEventTap)
            }
        }
    }
}
