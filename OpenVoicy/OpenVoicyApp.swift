import SwiftUI

@main
struct OpenVoicyApp: App {
    @StateObject private var appState = AppState()
    private let overlayController = FloatingWindowController()
    
    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .onChange(of: appState.state) { newState in
                    if newState == .idle {
                        overlayController.hideOverlay()
                    } else {
                        overlayController.showOverlay(appState: appState)
                    }
                }
        }
    }
}
