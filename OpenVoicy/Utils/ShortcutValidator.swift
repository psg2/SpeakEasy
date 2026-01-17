import AppKit
import Carbon
import Foundation

enum ShortcutValidator {
    enum ValidationResult {
        case valid
        case invalid(reason: String)
    }

    static func validate(keyCode: Int, modifiers: Int) -> ValidationResult {
        // Rule 1: Max 3 keys
        if self.countKeys(modifiers: modifiers) > 3 {
            return .invalid(reason: "Shortcut must use 3 keys or fewer.")
        }

        // Rule 2: Include at least one modifier or non-alphanumeric key
        if !self.isModifierPresent(modifiers), !self.isNonAlphanumeric(keyCode) {
            return .invalid(reason: "Shortcut must include a modifier or be a special key.")
        }

        // Rule 3: Check reserved shortcuts
        if self.isReserved(keyCode: keyCode, modifiers: modifiers) {
            return .invalid(reason: "This shortcut is reserved by the system.")
        }

        return .valid
    }

    private static func countKeys(modifiers: Int) -> Int {
        var count = 1 // The main key
        if (modifiers & cmdKey) != 0 { count += 1 }
        if (modifiers & shiftKey) != 0 { count += 1 }
        if (modifiers & optionKey) != 0 { count += 1 }
        if (modifiers & controlKey) != 0 { count += 1 }
        return count
    }

    private static func isModifierPresent(_ modifiers: Int) -> Bool {
        modifiers != 0
    }

    private static func isNonAlphanumeric(_ keyCode: Int) -> Bool {
        self.isFKey(keyCode) || self.isSpecialKey(keyCode)
    }

    private static func isFKey(_ keyCode: Int) -> Bool {
        let fKeys = [
            kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
            kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20,
        ]
        return fKeys.contains(keyCode)
    }

    private static func isSpecialKey(_ keyCode: Int) -> Bool {
        let special = [
            kVK_PageUp, kVK_PageDown, kVK_Home, kVK_End, kVK_LeftArrow, kVK_RightArrow,
            kVK_UpArrow, kVK_DownArrow, kVK_ForwardDelete, kVK_Delete, kVK_Escape,
            kVK_Tab, kVK_Return, kVK_Space,
        ]
        return special.contains(keyCode)
    }

    private static func isReserved(keyCode: Int, modifiers: Int) -> Bool {
        self.isMacOSReserved(keyCode: keyCode, modifiers: modifiers) ||
            self.isWindowsReserved(keyCode: keyCode, modifiers: modifiers)
    }

    private static func isMacOSReserved(keyCode: Int, modifiers: Int) -> Bool {
        let cmd = cmdKey
        let cmdShift = cmdKey | shiftKey
        let cmdOpt = cmdKey | optionKey
        let cmdCtrl = cmdKey | controlKey

        // Common Cmd-based
        let reservedCmd = [
            kVK_ANSI_C, kVK_ANSI_V, kVK_ANSI_X, kVK_ANSI_Z, kVK_ANSI_A, kVK_ANSI_Q,
            kVK_ANSI_W, kVK_ANSI_R, kVK_ANSI_T, kVK_ANSI_S, kVK_ANSI_P, kVK_ANSI_N,
            kVK_ANSI_M, kVK_ANSI_H, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_B, kVK_ANSI_I, kVK_ANSI_U,
        ]
        if modifiers == cmd, reservedCmd.contains(keyCode) { return true }

        if modifiers == cmdShift, [kVK_ANSI_Z, kVK_ANSI_G, kVK_ANSI_T, kVK_ANSI_F, kVK_ANSI_Q].contains(keyCode) {
            return true
        }

        if modifiers == cmd, keyCode == kVK_ANSI_Comma { return true }

        // Navigation & Control
        let arrows = [kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow]
        if modifiers == cmd || modifiers == cmdShift, arrows.contains(keyCode) { return true }

        if modifiers == cmdCtrl, keyCode == kVK_ANSI_F { return true }
        if modifiers == cmd, keyCode == kVK_Space { return true }
        if modifiers == cmdOpt, [kVK_Space, kVK_Escape, kVK_ANSI_D, kVK_ANSI_F].contains(keyCode) { return true }

        if modifiers == cmdShift, [kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5].contains(keyCode) { return true }
        if modifiers == cmd || modifiers == cmdShift, keyCode == kVK_Delete { return true }
        if modifiers == cmd, [kVK_ANSI_Equal, kVK_ANSI_Minus].contains(keyCode) { return true }

        return false
    }

    private static func isWindowsReserved(keyCode: Int, modifiers: Int) -> Bool {
        let ctrl = controlKey
        let alt = optionKey

        let reservedCtrl = [
            kVK_ANSI_C, kVK_ANSI_V, kVK_ANSI_X, kVK_ANSI_Z, kVK_ANSI_Y, kVK_ANSI_R,
            kVK_ANSI_A, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_O, kVK_ANSI_S, kVK_ANSI_P,
            kVK_ANSI_N, kVK_ANSI_T, kVK_ANSI_W, kVK_ANSI_K,
        ]
        if modifiers == ctrl, reservedCtrl.contains(keyCode) { return true }

        if modifiers == ctrl, [kVK_Home, kVK_End, kVK_Delete, kVK_ForwardDelete].contains(keyCode) { return true }
        if modifiers == (ctrl | alt), [kVK_ForwardDelete, kVK_Delete].contains(keyCode) { return true }
        if modifiers == (ctrl | shiftKey), keyCode == kVK_Escape { return true }

        if modifiers == alt, [kVK_Tab, kVK_F4].contains(keyCode) { return true }
        if modifiers == 0, [kVK_F5, kVK_F11].contains(keyCode) { return true }

        return false
    }
}
