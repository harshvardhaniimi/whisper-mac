import Cocoa
import Carbon

// Simple file logger for debugging
private func logToFile(_ message: String) {
    let logPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("whisper-hotkey.log")
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logPath.path) {
            if let handle = try? FileHandle(forWritingTo: logPath) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logPath)
        }
    }
}

@MainActor
class GlobalHotkeyManager: ObservableObject {
    @Published var isEnabled = true

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Hotkey: Cmd+Shift+Space
    private let keyCode: UInt32 = 49  // Space key
    private let modifiers: UInt32 = UInt32(cmdKey | shiftKey)  // Cmd+Shift

    var onHotkeyTriggered: (() -> Void)?

    // Static reference for the C callback
    private static var sharedInstance: GlobalHotkeyManager?

    init() {
        GlobalHotkeyManager.sharedInstance = self
        logToFile("GlobalHotkeyManager initialized (Cmd+Shift+Space)")
        print("GlobalHotkeyManager initialized (Cmd+Shift+Space)")
    }

    func startMonitoring() {
        guard isEnabled else {
            print("Hotkey monitoring disabled")
            return
        }

        // Don't register twice
        guard hotKeyRef == nil else {
            print("Hotkey already registered")
            return
        }

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                logToFile("🎉 Hotkey triggered!")
                // Trigger the callback on main thread
                Task { @MainActor in
                    GlobalHotkeyManager.sharedInstance?.onHotkeyTriggered?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else {
            print("Failed to install event handler: \(status)")
            return
        }

        // Register the hotkey
        let hotkeyID = EventHotKeyID(signature: OSType(0x574D4143), id: 1)  // 'WMAC'

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus == noErr {
            logToFile("✅ Global hotkey registered: Cmd+Shift+Space")
            print("✅ Global hotkey registered: Cmd+Shift+Space")
        } else {
            logToFile("Failed to register hotkey: \(registerStatus)")
            print("Failed to register hotkey: \(registerStatus)")
            // Clean up event handler if hotkey registration failed
            if let handler = eventHandler {
                RemoveEventHandler(handler)
                eventHandler = nil
            }
        }
    }

    func stopMonitoring() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
            print("Hotkey unregistered")
        }

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        // Note: Can't clear sharedInstance here due to actor isolation
        // The singleton pattern via AppState.shared ensures proper lifecycle
    }
}
