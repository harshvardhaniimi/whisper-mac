import SwiftUI
import Combine
import UserNotifications
import AppKit

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

        // Check if any models are installed
        if modelManager.installedModels.isEmpty {
            print("No models found. Auto-downloading base model...")
            await autoDownloadBaseModel()
        }

        // Start hotkey monitoring
        if globalHotkeyEnabled {
            hotkeyManager.startMonitoring()
        }

        isInitialSetupComplete = true
    }

    private func autoDownloadBaseModel() async {
        isDownloadingModel = true

        do {
            print("Downloading base model (142 MB)...")

            // Show initial notification
            let content = UNMutableNotificationContent()
            content.title = "Whisper Mac"
            content.body = "Downloading Whisper model... This may take a moment."
            let request = UNNotificationRequest(identifier: "download-start", content: content, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)

            try await modelManager.downloadModel(.base)

            print("Base model downloaded successfully")

            // Show success notification
            let successContent = UNMutableNotificationContent()
            successContent.title = "Whisper Ready!"
            successContent.body = "Press Ctrl twice to start recording"
            successContent.sound = .default
            let successRequest = UNNotificationRequest(identifier: "download-complete", content: successContent, trigger: nil)
            try? await UNUserNotificationCenter.current().add(successRequest)

        } catch {
            print("Failed to download base model: \(error)")
            notificationService.showError("Failed to download model. Please check Settings.")
        }

        isDownloadingModel = false
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

            // Show feedback
            notificationService.showRecordingStarted()
        } catch {
            print("Failed to start recording: \(error)")
            notificationService.showError("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() async {
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
        guard let audioData = await audioService.stopRecording() else {
            isRecording = false
            return
        }

        isRecording = false
        notificationService.showRecordingStopped()
        isProcessing = true

        do {
            // Check if model is installed
            if !modelManager.isModelInstalled(selectedModel) {
                throw TranscriptionError.modelNotFound
            }

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
