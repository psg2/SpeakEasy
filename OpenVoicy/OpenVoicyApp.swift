import SwiftData
import SwiftUI

@main
struct OpenVoicyApp: App {
    @StateObject private var appState: AppState
    private let overlayController = FloatingWindowController()

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([TranscriptionRecord.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let context = modelContainer.mainContext
        _appState = StateObject(wrappedValue: AppState(modelContext: context))
    }

    var body: some Scene {
        WindowGroup {
            HistoryView(appState: self.appState)
                .modelContainer(modelContainer)
                .onChange(of: self.appState.state) { _, newState in
                    if newState == .idle {
                        self.overlayController.hideOverlay()
                    } else {
                        self.overlayController.showOverlay(appState: self.appState)
                    }
                }
        }
    }
}
