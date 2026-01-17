import SwiftUI

@main
struct OpenVoicyApp: App {
    @StateObject private var appState = AppState()
    private let overlayController = FloatingWindowController()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: self.appState)
                .onChange(of: self.appState.state) { newState in
                    if newState == .idle {
                        self.overlayController.hideOverlay()
                    } else {
                        self.overlayController.showOverlay(appState: self.appState)
                    }
                }
        }
    }
}
