import AppKit
import SwiftUI

class FloatingWindowController: NSObject {
    var overlayWindow: NSWindow?
    
    func showOverlay(appState: AppState) {
        if overlayWindow == nil {
            let overlayView = RecordingOverlayView(appState: appState)
            let hostingController = NSHostingController(rootView: overlayView)
            
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
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
                let x = screenRect.midX - windowRect.width / 2
                let y = screenRect.minY + 100 // Bottom area
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            overlayWindow = window
        }
        
        overlayWindow?.orderFront(nil)
    }
    
    func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }
}
