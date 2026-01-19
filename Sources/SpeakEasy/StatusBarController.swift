import AppKit
import SwiftData
import SwiftUI

@MainActor
public class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?

    private let appState: AppState
    private let modelContainer: ModelContainer

    public init(appState: AppState, modelContainer: ModelContainer) {
        self.appState = appState
        self.modelContainer = modelContainer
        super.init()
        self.setupStatusItem()
        self.setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.showSettings),
            name: .showSettings,
            object: nil)
    }

    private func setupStatusItem() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = self.statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "waveform",
                accessibilityDescription: "SpeakEasy")
            button.image?.isTemplate = true
        }

        self.setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let historyItem = NSMenuItem(
            title: "Show History",
            action: #selector(self.showHistory),
            keyEquivalent: "h")
        historyItem.keyEquivalentModifierMask = [.command]
        historyItem.target = self
        menu.addItem(historyItem)

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(self.showSettings),
            keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit SpeakEasy",
            action: #selector(self.quitApp),
            keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem?.menu = menu
    }

    @objc private func showHistory() {
        if self.historyWindow == nil {
            let historyView = HistoryView(appState: self.appState)
                .modelContainer(self.modelContainer)

            let hostingController = NSHostingController(rootView: historyView)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false)

            window.contentViewController = hostingController
            window.title = "SpeakEasy"
            window.isReleasedWhenClosed = false
            window.center()
            window.setFrameAutosaveName("HistoryWindow")
            window.delegate = self

            self.historyWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        self.historyWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showSettings() {
        let isNewWindow = self.settingsWindow == nil

        if isNewWindow {
            let settingsView = SettingsView()

            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false)

            window.contentViewController = hostingController
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.center()
            window.setFrameAutosaveName("SettingsWindow")
            window.delegate = self

            self.settingsWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        self.settingsWindow?.makeKeyAndOrderFront(nil)

        if isNewWindow {
            // Delay activation slightly for new windows to ensure they're fully ready
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func updateActivationPolicy() {
        let hasVisibleWindow = (self.historyWindow?.isVisible == true) ||
            (self.settingsWindow?.isVisible == true)

        if hasVisibleWindow {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - NSWindowDelegate

extension StatusBarController: NSWindowDelegate {
    public func windowWillClose(_: Notification) {
        // Delay the check slightly to allow window state to update
        DispatchQueue.main.async {
            self.updateActivationPolicy()
        }
    }
}
