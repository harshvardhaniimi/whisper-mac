import Foundation
import Speech
import AVFoundation

@MainActor
class WhisperService: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?

    init() {
        // Initialize with the default locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func transcribe(audioData: Data, model: WhisperModel, language: String? = nil) async throws -> String {
        // Set up recognizer for the specified language
        let locale: Locale
        if let language = language, language != "auto" {
            locale = Locale(identifier: language)
        } else {
            locale = Locale.current
        }

        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.initializationFailed
        }

        // Check authorization
        let authorized = await requestAuthorization()
        guard authorized else {
            throw TranscriptionError.permissionDenied
        }

        // Save audio data to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        try audioData.write(to: tempURL)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Transcribe the file
        return try await transcribeFile(url: tempURL, model: model, language: language)
    }

    func transcribeFile(url: URL, model: WhisperModel, language: String? = nil) async throws -> String {
        // Set up recognizer for the specified language
        let locale: Locale
        if let language = language, language != "auto" {
            locale = Locale(identifier: language)
        } else {
            locale = Locale.current
        }

        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.initializationFailed
        }

        // Check authorization
        let authorized = await requestAuthorization()
        guard authorized else {
            throw TranscriptionError.permissionDenied
        }

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        // Perform recognition
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if error != nil {
                    continuation.resume(throwing: TranscriptionError.processingFailed)
                    return
                }

                guard let result = result, result.isFinal else {
                    return
                }

                let transcription = result.bestTranscription.formattedString
                continuation.resume(returning: transcription)
            }
        }
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotFound
    case initializationFailed
    case contextNotInitialized
    case processingFailed
    case invalidAudioFile
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Speech recognition not available."
        case .initializationFailed:
            return "Failed to initialize speech recognizer."
        case .contextNotInitialized:
            return "Speech recognizer not initialized."
        case .processingFailed:
            return "Failed to process audio."
        case .invalidAudioFile:
            return "Invalid audio file format."
        case .permissionDenied:
            return "Speech recognition permission denied. Please enable in System Settings."
        }
    }
}
