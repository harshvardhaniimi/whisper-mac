import Cocoa
import ApplicationServices

class TextInsertionService {
    static let shared = TextInsertionService()

    private init() {}

    /// Insert text at the current cursor position in the focused application
    func insertTextAtCursor(_ text: String) {
        // First, copy to clipboard
        copyToClipboard(text)

        // Small delay to ensure clipboard is set
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Simulate Cmd+V to paste
            self.simulatePaste()
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func simulatePaste() {
        // Check if there's a frontmost application
        guard NSWorkspace.shared.frontmostApplication != nil else {
            print("No frontmost application")
            return
        }

        // Create Cmd+V key event
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down for Command
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand

        // Key down for V
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand

        // Key up for V
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand

        // Key up for Command
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        // Post events
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        print("Simulated paste (Cmd+V)")
    }

    /// Alternative method using Accessibility API (more precise but requires more permissions)
    func insertTextUsingAccessibility(_ text: String) {
        let systemWideElement = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let focusedElement = focusedElement else {
            print("Could not get focused element, falling back to paste")
            insertTextAtCursor(text)
            return
        }

        let element = focusedElement as! AXUIElement

        // Try to set the selected text
        var selectedRange: CFTypeRef?
        AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRange
        )

        // Insert text at selection
        AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        print("Inserted text using Accessibility API")
    }

    func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
}
