import Foundation
import AppKit
import Carbon

class KeyboardUtils {

    static func carbonModifiers(from nsModifiers: NSEvent.ModifierFlags) -> Int {
        var carbonModifiers: Int = 0
        if nsModifiers.contains(.command) { carbonModifiers |= cmdKey }
        if nsModifiers.contains(.option) { carbonModifiers |= optionKey }
        if nsModifiers.contains(.control) { carbonModifiers |= controlKey }
        if nsModifiers.contains(.shift) { carbonModifiers |= shiftKey }
        return carbonModifiers
    }

    static func string(for key: Int, modifiers: Int) -> String {
        var string = ""

        // Modifiers
        // Check Carbon flags
        if (modifiers & cmdKey) != 0 { string += "⌘" }
        if (modifiers & shiftKey) != 0 { string += "⇧" }
        if (modifiers & optionKey) != 0 { string += "⌥" }
        if (modifiers & controlKey) != 0 { string += "⌃" }

        // Key Code to String
        if let keyString = keyToString(CGKeyCode(key)) {
            string += keyString.uppercased()
        } else {
             string += "?"
        }

        return string
    }

    static func keyToString(_ keyCode: CGKeyCode) -> String? {
        // Special cases for common keys
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "Esc"
        default: break
        }

        // Use TIS to convert key code to string
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }

        let dataRef = unsafeBitCast(layoutData, to: CFData.self)

        guard let keyLayout = CFDataGetBytePtr(dataRef)?
            .withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1, { $0 }) else {
            return nil
        }

        var keysDown: UInt32 = 0
        var chars: [UniChar] = [0, 0, 0, 0]
        var realLength: Int = 0

        let result = UCKeyTranslate(
            keyLayout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &keysDown,
            4,
            &realLength,
            &chars
        )

        if result == noErr && realLength > 0 {
            return String(utf16CodeUnits: chars, count: realLength)
        }

        return nil
    }
}
