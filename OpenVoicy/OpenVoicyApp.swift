import Combine
import OpenVoicyLib
import SwiftData
import SwiftUI

@main
struct OpenVoicyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState!
    private var modelContainer: ModelContainer!
    private var overlayController: FloatingWindowController!
    private var statusBarController: StatusBarController!
    private var stateObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_: Notification) {
        self.setupModelContainer()
        self.setupAppState()
        self.setupOverlayController()
        self.setupStatusBar()
    }

    private func setupModelContainer() {
        let schema = Schema([TranscriptionRecord.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false)

        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func setupAppState() {
        let context = self.modelContainer.mainContext
        self.appState = AppState(modelContext: context)
    }

    private func setupOverlayController() {
        self.overlayController = FloatingWindowController()

        // Observe state changes using Combine
        Task { @MainActor in
            for await state in self.appState.$state.values {
                if state == .idle {
                    self.overlayController.hideOverlay()
                } else {
                    self.overlayController.showOverlay(appState: self.appState)
                }
            }
        }
    }

    private func setupStatusBar() {
        self.statusBarController = StatusBarController(
            appState: self.appState,
            modelContainer: self.modelContainer)
    }
}
