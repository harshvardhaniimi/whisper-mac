import Cocoa
import Carbon

@MainActor
class GlobalHotkeyManager: ObservableObject {
    @Published var isEnabled = true

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastControlReleaseTime: Date?
    private var controlWasPressed = false
    private let doublePressInterval: TimeInterval = 0.4 // 400ms window for double press

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

                // Handle synchronously to avoid timing issues
                let flags = event.flags
                let controlPressed = flags.contains(.maskControl)
                let noOtherModifiers = !flags.contains(.maskShift) &&
                                       !flags.contains(.maskAlternate) &&
                                       !flags.contains(.maskCommand)

                if noOtherModifiers {
                    Task { @MainActor in
                        manager.handleControlKey(isPressed: controlPressed)
                    }
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap - check Accessibility permissions")
            return
        }

        self.eventTap = eventTap

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("✅ Global hotkey monitoring started (Ctrl+Ctrl to record)")
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

    private func handleControlKey(isPressed: Bool) {
        if isPressed && !controlWasPressed {
            // Control key just pressed down
            controlWasPressed = true
        } else if !isPressed && controlWasPressed {
            // Control key just released
            controlWasPressed = false
            let now = Date()

            if let lastRelease = lastControlReleaseTime {
                let interval = now.timeIntervalSince(lastRelease)

                if interval <= doublePressInterval {
                    // Double press detected!
                    lastControlReleaseTime = nil
                    onHotkeyTriggered?()
                    return
                }
            }

            lastControlReleaseTime = now
        }
    }

    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️  Accessibility access not granted. Please enable in System Settings.")
        } else {
            print("✅ Accessibility access granted")
        }
    }

    func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    deinit {
        // Clean up event tap directly since we can't call async methods from deinit
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
}
