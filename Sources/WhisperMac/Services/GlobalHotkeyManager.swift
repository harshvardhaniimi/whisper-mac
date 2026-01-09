import Cocoa
import Carbon

@MainActor
class GlobalHotkeyManager: ObservableObject {
    @Published var isEnabled = true

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastControlPressTime: Date?
    private let doublePressInterval: TimeInterval = 0.5 // 500ms window for double press

    var onHotkeyTriggered: (() -> Void)?

    init() {
        requestAccessibilityPermissions()
    }

    func startMonitoring() {
        guard isEnabled else { return }

        // Create event tap
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refcon).takeUnretainedValue()

                Task { @MainActor in
                    manager.handleEvent(event)
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = eventTap

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("Global hotkey monitoring started (Ctrl+Ctrl to record)")
    }

    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil

        print("Global hotkey monitoring stopped")
    }

    private func handleEvent(_ event: CGEvent) {
        let flags = event.flags

        // Check if Control key is pressed (and no other modifiers)
        let controlPressed = flags.contains(.maskControl)
        let noOtherModifiers = !flags.contains(.maskShift) &&
                               !flags.contains(.maskAlternate) &&
                               !flags.contains(.maskCommand)

        if controlPressed && noOtherModifiers {
            let now = Date()

            if let lastPress = lastControlPressTime {
                let interval = now.timeIntervalSince(lastPress)

                if interval <= doublePressInterval {
                    // Double press detected!
                    print("Hotkey triggered: Ctrl+Ctrl")
                    onHotkeyTriggered?()
                    lastControlPressTime = nil // Reset
                } else {
                    // Too slow, start new sequence
                    lastControlPressTime = now
                }
            } else {
                // First press
                lastControlPressTime = now
            }
        }
    }

    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Accessibility access not granted. Please enable in System Settings.")
        }
    }

    func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    deinit {
        stopMonitoring()
    }
}
