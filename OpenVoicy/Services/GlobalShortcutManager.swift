import Carbon
import Foundation

class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    var onShortcutTriggered: (() -> Void)?
    var onEscapeTriggered: (() -> Void)?

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var escapeKeyRef: EventHotKeyRef?

    private let mainHotKeyID = EventHotKeyID(signature: OSType(0x1111), id: 1)
    private let escapeHotKeyID = EventHotKeyID(signature: OSType(0x2222), id: 2)

    init() {
        self.installEventHandler()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ in
            var hotKeyID = EventHotKeyID()
            _ = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID)

            DispatchQueue.main.async {
                if hotKeyID.signature == OSType(0x1111), hotKeyID.id == 1 {
                    GlobalShortcutManager.shared.onShortcutTriggered?()
                } else if hotKeyID.signature == OSType(0x2222), hotKeyID.id == 2 {
                    GlobalShortcutManager.shared.onEscapeTriggered?()
                }
            }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &self.eventHandler)
    }

    func registerShortcut(key: Int, modifiers: Int) {
        if let currentRef = hotKeyRef {
            UnregisterEventHotKey(currentRef)
        }

        RegisterEventHotKey(
            UInt32(key),
            UInt32(modifiers),
            self.mainHotKeyID,
            GetApplicationEventTarget(),
            0,
            &self.hotKeyRef)
    }

    func registerEscapeShortcut() {
        if self.escapeKeyRef != nil { return } // Already registered

        // Escape key code is 53 (kVK_Escape)
        // No modifiers (0)
        RegisterEventHotKey(
            UInt32(kVK_Escape),
            0,
            self.escapeHotKeyID,
            GetApplicationEventTarget(),
            0,
            &self.escapeKeyRef)
    }

    func unregisterEscapeShortcut() {
        if let ref = escapeKeyRef {
            UnregisterEventHotKey(ref)
            self.escapeKeyRef = nil
        }
    }
}
