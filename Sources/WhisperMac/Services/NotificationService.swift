import UserNotifications
import AppKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    private init() {
        requestPermission()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            print("Notification permission granted: \(granted)")
        }
    }

    func showRecordingStarted() {
        // Play system sound
        NSSound.beep()

        // Show notification
        let content = UNMutableNotificationContent()
        content.title = "Recording Started"
        content.body = "Speak now... Press Ctrl+Ctrl again to stop"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "recording-started",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }

        // Visual feedback - flash menu bar icon
        flashMenuBarIcon()
    }

    func showRecordingStopped() {
        // Play different sound
        NSSound(named: "Pop")?.play()

        // Show notification
        let content = UNMutableNotificationContent()
        content.title = "Recording Stopped"
        content.body = "Transcribing..."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "recording-stopped",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    func showTranscriptionComplete(text: String) {
        let content = UNMutableNotificationContent()
        content.title = "Transcription Complete"
        content.body = String(text.prefix(100)) + (text.count > 100 ? "..." : "")
        content.sound = UNNotificationSound(named: UNNotificationSoundName("Glass"))

        let request = UNNotificationRequest(
            identifier: "transcription-complete",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    func showError(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Whisper Error"
        content.body = message
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: "error-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func flashMenuBarIcon() {
        // This will be called from AppDelegate to flash the menu bar icon
        NotificationCenter.default.post(name: NSNotification.Name("FlashMenuBarIcon"), object: nil)
    }
}
