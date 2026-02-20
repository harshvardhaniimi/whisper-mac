import SwiftUI
import AppKit

@main
struct KalamApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Hidden main window (we use menu bar instead)
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var mainWindow: NSWindow?
    private var flashTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: AppBrand.displayName)
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MainView()
                .environmentObject(AppState.shared)
        )

        // Set up notification observer for flashing icon
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(flashIcon),
            name: NSNotification.Name("FlashMenuBarIcon"),
            object: nil
        )

        // Initialize app state (downloads model if needed, starts hotkey monitoring)
        Task {
            await AppState.shared.initialize()
        }
    }

    @objc func flashIcon() {
        guard let button = statusItem?.button else { return }

        var flashCount = 0
        flashTimer?.invalidate()

        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            flashCount += 1

            if flashCount % 2 == 0 {
                button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: AppBrand.displayName)
            } else {
                button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Recording")
            }

            if flashCount >= 6 {
                timer.invalidate()
                button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: AppBrand.displayName)
            }
        }
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Activate the app
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }

    @MainActor @objc func showMainWindow() {
        if mainWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = AppBrand.displayName
            window.contentView = NSHostingView(
                rootView: MainWindowView()
                    .environmentObject(AppState.shared)
            )
            mainWindow = window
        }

        mainWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
