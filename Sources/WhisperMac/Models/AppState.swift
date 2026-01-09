import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    // Recording state
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var isProcessing = false

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

    // Services
    let audioService: AudioCaptureService
    let whisperService: WhisperService
    let modelManager: ModelManager
    let historyManager: HistoryManager

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.audioService = AudioCaptureService()
        self.whisperService = WhisperService()
        self.modelManager = ModelManager()
        self.historyManager = HistoryManager()

        setupBindings()
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

    func startRecording() async throws {
        currentTranscription = ""
        try await audioService.startRecording()
        isRecording = true
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
}
