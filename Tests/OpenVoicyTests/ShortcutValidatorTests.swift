import Carbon
import Foundation
import Testing
@testable import OpenVoicyLib

@Suite("ShortcutValidator Tests")
struct ShortcutValidatorTests {

    // MARK: - Valid Shortcuts

    @Test("Valid shortcut with single modifier and key")
    func testValidShortcutWithSingleModifier() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_K, modifiers: cmdKey)

        if case .valid = result {
            // Success
        } else {
            Issue.record("Expected valid result, got \(result)")
        }
    }

    @Test("Valid shortcut with two modifiers")
    func testValidShortcutWithTwoModifiers() {
        let result = ShortcutValidator.validate(
            keyCode: kVK_ANSI_K,
            modifiers: cmdKey | shiftKey
        )

        if case .valid = result {
            // Success
        } else {
            Issue.record("Expected valid result, got \(result)")
        }
    }

    @Test("Invalid shortcut with three modifiers (exceeds 3-key limit)")
    func testInvalidShortcutWithThreeModifiers() {
        // 3 modifiers + 1 key = 4 keys total, exceeds 3-key limit
        let result = ShortcutValidator.validate(
            keyCode: kVK_ANSI_K,
            modifiers: cmdKey | shiftKey | optionKey
        )

        if case .invalid(let reason) = result {
            #expect(reason.contains("3 keys or fewer"))
        } else {
            Issue.record("Expected invalid result for 3 modifiers + key, got \(result)")
        }
    }

    @Test("Valid F-key without modifiers")
    func testValidFKeyWithoutModifiers() {
        let result = ShortcutValidator.validate(keyCode: kVK_F6, modifiers: 0)

        if case .valid = result {
            // Success
        } else {
            Issue.record("Expected valid result for F6 without modifiers, got \(result)")
        }
    }

    @Test("Valid special key without modifiers")
    func testValidSpecialKeyWithoutModifiers() {
        let result = ShortcutValidator.validate(keyCode: kVK_PageDown, modifiers: 0)

        if case .valid = result {
            // Success
        } else {
            Issue.record("Expected valid result for PageDown without modifiers, got \(result)")
        }
    }

    // MARK: - Invalid Shortcuts - Too Many Keys

    @Test("Invalid shortcut with four modifiers (too many keys)")
    func testInvalidShortcutWithFourModifiers() {
        let result = ShortcutValidator.validate(
            keyCode: kVK_ANSI_K,
            modifiers: cmdKey | shiftKey | optionKey | controlKey
        )

        if case .invalid(let reason) = result {
            #expect(reason.contains("3 keys or fewer"))
        } else {
            Issue.record("Expected invalid result for too many keys, got \(result)")
        }
    }

    // MARK: - Invalid Shortcuts - No Modifier or Special Key

    @Test("Invalid shortcut with regular key and no modifier")
    func testInvalidShortcutWithoutModifier() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_A, modifiers: 0)

        if case .invalid(let reason) = result {
            #expect(reason.contains("modifier") || reason.contains("special key"))
        } else {
            Issue.record("Expected invalid result for key without modifier, got \(result)")
        }
    }

    // MARK: - Reserved Shortcuts - macOS

    @Test("Reserved macOS shortcut: Cmd+C (Copy)")
    func testReservedMacOSCmdC() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_C, modifiers: cmdKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Cmd+C to be reserved, got \(result)")
        }
    }

    @Test("Reserved macOS shortcut: Cmd+V (Paste)")
    func testReservedMacOSCmdV() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_V, modifiers: cmdKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Cmd+V to be reserved, got \(result)")
        }
    }

    @Test("Reserved macOS shortcut: Cmd+Q (Quit)")
    func testReservedMacOSCmdQ() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_Q, modifiers: cmdKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Cmd+Q to be reserved, got \(result)")
        }
    }

    @Test("Reserved macOS shortcut: Cmd+Space (Spotlight)")
    func testReservedMacOSCmdSpace() {
        let result = ShortcutValidator.validate(keyCode: kVK_Space, modifiers: cmdKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Cmd+Space to be reserved, got \(result)")
        }
    }

    @Test("Reserved macOS shortcut: Cmd+Shift+Z (Redo)")
    func testReservedMacOSCmdShiftZ() {
        let result = ShortcutValidator.validate(
            keyCode: kVK_ANSI_Z,
            modifiers: cmdKey | shiftKey
        )

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Cmd+Shift+Z to be reserved, got \(result)")
        }
    }

    @Test("Reserved macOS shortcut: Cmd+, (Preferences)")
    func testReservedMacOSCmdComma() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_Comma, modifiers: cmdKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Cmd+, to be reserved, got \(result)")
        }
    }

    // MARK: - Reserved Shortcuts - Windows

    @Test("Reserved Windows shortcut: Ctrl+C (Copy)")
    func testReservedWindowsCtrlC() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_C, modifiers: controlKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Ctrl+C to be reserved, got \(result)")
        }
    }

    @Test("Reserved Windows shortcut: Ctrl+V (Paste)")
    func testReservedWindowsCtrlV() {
        let result = ShortcutValidator.validate(keyCode: kVK_ANSI_V, modifiers: controlKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Ctrl+V to be reserved, got \(result)")
        }
    }

    @Test("Reserved Windows shortcut: Alt+Tab")
    func testReservedWindowsAltTab() {
        let result = ShortcutValidator.validate(keyCode: kVK_Tab, modifiers: optionKey)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Alt+Tab to be reserved, got \(result)")
        }
    }

    @Test("Reserved Windows shortcut: F11 (Fullscreen)")
    func testReservedWindowsF11() {
        let result = ShortcutValidator.validate(keyCode: kVK_F11, modifiers: 0)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected F11 to be reserved, got \(result)")
        }
    }

    @Test("Reserved Windows shortcut: F5 (Refresh)")
    func testReservedWindowsF5() {
        let result = ShortcutValidator.validate(keyCode: kVK_F5, modifiers: 0)

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected F5 to be reserved, got \(result)")
        }
    }

    // MARK: - Edge Cases

    @Test("Non-reserved F-key with modifiers is valid")
    func testNonReservedFKeyWithModifiers() {
        let result = ShortcutValidator.validate(
            keyCode: kVK_F7,
            modifiers: cmdKey | optionKey
        )

        if case .valid = result {
            // Success
        } else {
            Issue.record("Expected F7 with modifiers to be valid, got \(result)")
        }
    }

    @Test("Arrow keys with modifiers are reserved on macOS")
    func testArrowKeysWithCmdReserved() {
        let result = ShortcutValidator.validate(
            keyCode: kVK_LeftArrow,
            modifiers: cmdKey
        )

        if case .invalid(let reason) = result {
            #expect(reason.contains("reserved"))
        } else {
            Issue.record("Expected Cmd+Left Arrow to be reserved, got \(result)")
        }
    }
}
