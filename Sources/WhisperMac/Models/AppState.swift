import SwiftUI
import Combine
import UserNotifications
import Speech

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    // Recording state
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var isProcessing = false
    @Published var isDownloadingModel = false

    // Audio
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0

    // Transcription
    @Published var currentTranscription: String = ""
    @Published var transcriptionHistory: [Transcription] = []

    // Settings
    @Published var selectedModel: WhisperModel = .base
    @Published var selectedLanguage: String = "auto"
    @Published var selectedAudioDevice: String?
    @Published var globalHotkeyEnabled = true

    // Services
    let audioService: AudioCaptureService
    let whisperService: WhisperService
    let modelManager: ModelManager
    let historyManager: HistoryManager
    let hotkeyManager: GlobalHotkeyManager
    let notificationService: NotificationService
    let textInsertionService = TextInsertionService.shared

    private var cancellables = Set<AnyCancellable>()
    private var isInitialSetupComplete = false

    init() {
        self.audioService = AudioCaptureService()
        self.whisperService = WhisperService()
        self.modelManager = ModelManager()
        self.historyManager = HistoryManager()
        self.hotkeyManager = GlobalHotkeyManager()
        self.notificationService = NotificationService.shared

        setupBindings()
        setupHotkeyHandler()
    }

    private func setupBindings() {
        // Bind audio level
        audioService.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)

        // Bind recording duration
        audioService.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingDuration)
    }

    private func setupHotkeyHandler() {
        hotkeyManager.onHotkeyTriggered = { [weak self] in
            Task { @MainActor in
                await self?.handleHotkeyPress()
            }
        }
    }

    func initialize() async {
        guard !isInitialSetupComplete else { return }

        // Request speech recognition authorization
        let authorized = await whisperService.requestAuthorization()
        if !authorized {
            print("Speech recognition not authorized")
        }

        // Start hotkey monitoring
        if globalHotkeyEnabled {
            hotkeyManager.startMonitoring()
        }

        // Show ready notification (only if we have a bundle)
        if Bundle.main.bundleIdentifier != nil {
            let content = UNMutableNotificationContent()
            content.title = "Speech to Text Ready!"
            content.body = "Press Ctrl twice to start recording"
            content.sound = .default
            let request = UNNotificationRequest(identifier: "ready", content: content, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)
        } else {
            print("Speech to Text Ready! Press Ctrl twice to start recording")
        }

        isInitialSetupComplete = true
    }

    private func handleHotkeyPress() async {
        // Toggle recording
        if isRecording {
            await stopRecordingAndTranscribe()
        } else if !isProcessing && !isDownloadingModel {
            await startRecordingWithFeedback()
        }
    }

    func startRecording() async throws {
        currentTranscription = ""
        try await audioService.startRecording()
        isRecording = true
    }

    func startRecordingWithFeedback() async {
        do {
            currentTranscription = ""
            try await audioService.startRecording()
            isRecording = true

            // Show visual indicator at cursor
            RecordingIndicatorWindow.shared.show()

            // Show feedback
            notificationService.showRecordingStarted()
        } catch {
            print("Failed to start recording: \(error)")
            notificationService.showError("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() async {
        // Hide recording indicator
        RecordingIndicatorWindow.shared.hide()

        guard let audioData = await audioService.stopRecording() else {
            isRecording = false
            return
        }

        isRecording = false
        isProcessing = true

        do {
            let result = try await whisperService.transcribe(
                audioData: audioData,
                model: selectedModel,
                language: selectedLanguage == "auto" ? nil : selectedLanguage
            )

            currentTranscription = result

            // Save to history
            let transcription = Transcription(
                text: result,
                date: Date(),
                duration: recordingDuration,
                language: selectedLanguage
            )
            historyManager.save(transcription)
            transcriptionHistory.insert(transcription, at: 0)

        } catch {
            print("Transcription error: \(error)")
            currentTranscription = "Error: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    func stopRecordingAndTranscribe() async {
        // Hide recording indicator
        RecordingIndicatorWindow.shared.hide()

        guard let audioData = await audioService.stopRecording() else {
            isRecording = false
            return
        }

        isRecording = false
        notificationService.showRecordingStopped()
        isProcessing = true

        do {
            let result = try await whisperService.transcribe(
                audioData: audioData,
                model: selectedModel,
                language: selectedLanguage == "auto" ? nil : selectedLanguage
            )

            currentTranscription = result

            // Save to history
            let transcription = Transcription(
                text: result,
                date: Date(),
                duration: recordingDuration,
                language: selectedLanguage
            )
            historyManager.save(transcription)
            transcriptionHistory.insert(transcription, at: 0)

            // Insert at cursor and copy to clipboard
            textInsertionService.insertTextAtCursor(result)
            notificationService.showTranscriptionComplete(text: result)

        } catch {
            print("Transcription error: \(error)")
            let errorMessage = "Error: \(error.localizedDescription)"
            currentTranscription = errorMessage
            notificationService.showError(errorMessage)
        }

        isProcessing = false
    }

    func transcribeFile(url: URL) async throws {
        isProcessing = true
        defer { isProcessing = false }

        let result = try await whisperService.transcribeFile(
            url: url,
            model: selectedModel,
            language: selectedLanguage == "auto" ? nil : selectedLanguage
        )

        currentTranscription = result

        let transcription = Transcription(
            text: result,
            date: Date(),
            duration: 0,
            language: selectedLanguage,
            sourceFile: url.lastPathComponent
        )
        historyManager.save(transcription)
        transcriptionHistory.insert(transcription, at: 0)
    }

    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentTranscription, forType: .string)
    }

    func toggleGlobalHotkey() {
        globalHotkeyEnabled.toggle()

        if globalHotkeyEnabled {
            hotkeyManager.startMonitoring()
        } else {
            hotkeyManager.stopMonitoring()
        }
    }
}
