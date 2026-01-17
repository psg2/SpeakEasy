import AppKit
import SwiftUI

public class FloatingWindowController: NSObject {
    var overlayWindow: NSWindow?

    public override init() {
        super.init()
    }

    public func showOverlay(appState: AppState) {
        if self.overlayWindow == nil {
            let overlayView = RecordingOverlayView(appState: appState)
            let hostingController = NSHostingController(rootView: overlayView)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false)

            window.contentViewController = hostingController
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.ignoresMouseEvents = true // Let clicks pass through

            // Center roughly
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let windowRect = window.frame
                let xPos = screenRect.midX - windowRect.width / 2
                let yPos = screenRect.minY + 100 // Bottom area
                window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
            }

            self.overlayWindow = window
        }

        self.overlayWindow?.orderFront(nil)
    }

    public func hideOverlay() {
        self.overlayWindow?.orderOut(nil)
    }
}
