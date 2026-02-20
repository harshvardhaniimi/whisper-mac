import SwiftUI
import Combine
import UserNotifications

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
        #if !APP_STORE_BUILD
        setupHotkeyHandler()
        #endif
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

    #if !APP_STORE_BUILD
    private func setupHotkeyHandler() {
        hotkeyManager.onHotkeyTriggered = { [weak self] in
            Task { @MainActor in
                await self?.handleHotkeyPress()
            }
        }
    }
    #endif

    func initialize() async {
        guard !isInitialSetupComplete else { return }

        // Auto-download default model if not installed
        if !modelManager.isModelInstalled(selectedModel) {
            isDownloadingModel = true
            do {
                try await modelManager.downloadModel(selectedModel)
            } catch {
                print("Failed to download default model: \(error)")
            }
            isDownloadingModel = false
        }

        // Pre-load the selected model into WhisperKit
        if modelManager.isModelInstalled(selectedModel) {
            let modelPath = modelManager.getModelPath(selectedModel)
            do {
                try await whisperService.loadModel(selectedModel, modelPath: modelPath)
            } catch {
                print("Failed to pre-load model: \(error)")
            }
        }

        #if !APP_STORE_BUILD
        // Start hotkey monitoring
        if globalHotkeyEnabled {
            hotkeyManager.startMonitoring()
        }
        #endif

        // Show ready notification (only if we have a bundle)
        if Bundle.main.bundleIdentifier != nil {
            let content = UNMutableNotificationContent()
            content.title = "\(AppBrand.displayName) Ready!"
            #if APP_STORE_BUILD
            content.body = "Click the menu bar icon to start recording"
            #else
            content.body = "Press Cmd+Shift+Space to start recording"
            #endif
            content.sound = .default
            let request = UNNotificationRequest(identifier: "ready", content: content, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)
        } else {
            print("\(AppBrand.displayName) Ready!")
        }

        isInitialSetupComplete = true
    }

    #if !APP_STORE_BUILD
    private func handleHotkeyPress() async {
        // Toggle recording
        if isRecording {
            await stopRecordingAndTranscribe()
        } else if !isProcessing && !isDownloadingModel {
            await startRecordingWithFeedback()
        }
    }
    #endif

    func startRecording() async throws {
        guard modelManager.isModelInstalled(selectedModel) else {
            throw TranscriptionError.modelNotFound
        }
        currentTranscription = ""
        try await audioService.startRecording()
        isRecording = true
    }

    func startRecordingWithFeedback() async {
        do {
            guard modelManager.isModelInstalled(selectedModel) else {
                notificationService.showError("Model not downloaded. Please download a model in Settings.")
                return
            }
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

        guard let audioSamples = await audioService.stopRecordingAndGetSamples() else {
            isRecording = false
            return
        }

        isRecording = false
        isProcessing = true

        do {
            let modelPath = modelManager.getModelPath(selectedModel)
            let result = try await whisperService.transcribe(
                audioSamples: audioSamples,
                model: selectedModel,
                modelPath: modelPath,
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

        guard let audioSamples = await audioService.stopRecordingAndGetSamples() else {
            isRecording = false
            return
        }

        isRecording = false
        notificationService.showRecordingStopped()
        isProcessing = true

        do {
            let modelPath = modelManager.getModelPath(selectedModel)
            let result = try await whisperService.transcribe(
                audioSamples: audioSamples,
                model: selectedModel,
                modelPath: modelPath,
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

            // Insert at cursor (direct distribution) or just copy to clipboard (App Store)
            #if APP_STORE_BUILD
            copyToClipboard()
            #else
            textInsertionService.insertTextAtCursor(result)
            #endif
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
        guard modelManager.isModelInstalled(selectedModel) else {
            throw TranscriptionError.modelNotFound
        }

        isProcessing = true
        defer { isProcessing = false }

        let modelPath = modelManager.getModelPath(selectedModel)
        let result = try await whisperService.transcribeFile(
            url: url,
            model: selectedModel,
            modelPath: modelPath,
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
        #if !APP_STORE_BUILD
        globalHotkeyEnabled.toggle()

        if globalHotkeyEnabled {
            hotkeyManager.startMonitoring()
        } else {
            hotkeyManager.stopMonitoring()
        }
        #endif
    }
}
