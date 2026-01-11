import Foundation
import WhisperCpp

actor WhisperService {
    private var currentContext: OpaquePointer?
    private let modelManager = ModelManager()

    func transcribe(audioData: Data, model: WhisperModel, language: String? = nil) async throws -> String {
        // Ensure model is downloaded
        let modelPath = await modelManager.getModelPath(model)

        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw TranscriptionError.modelNotFound
        }

        // Initialize Whisper context if needed
        if currentContext == nil {
            currentContext = whisper_init_from_file(modelPath.path)
            guard currentContext != nil else {
                throw TranscriptionError.initializationFailed
            }
        }

        // Save audio data to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        try audioData.write(to: tempURL)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Process audio file
        return try await transcribeFile(url: tempURL, model: model, language: language)
    }

    func transcribeFile(url: URL, model: WhisperModel, language: String? = nil) async throws -> String {
        let modelPath = await modelManager.getModelPath(model)

        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw TranscriptionError.modelNotFound
        }

        // Initialize context if needed
        if currentContext == nil {
            currentContext = whisper_init_from_file(modelPath.path)
            guard currentContext != nil else {
                throw TranscriptionError.initializationFailed
            }
        }

        guard let context = currentContext else {
            throw TranscriptionError.contextNotInitialized
        }

        // Read audio file
        let audioSamples = try readAudioFile(url: url)

        // Set up parameters
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_progress = false
        params.print_timestamps = false
        params.print_realtime = false
        params.translate = false

        if let language = language {
            params.language = language.withCString { strdup($0) }
        } else {
            params.language = "auto".withCString { strdup($0) }
        }

        // Run transcription
        let result = audioSamples.withUnsafeBufferPointer { buffer in
            whisper_full(context, params, buffer.baseAddress, Int32(buffer.count))
        }

        guard result == 0 else {
            throw TranscriptionError.processingFailed
        }

        // Extract text
        let numSegments = whisper_full_n_segments(context)
        var transcription = ""

        for i in 0..<numSegments {
            if let cString = whisper_full_get_segment_text(context, i) {
                transcription += String(cString: cString)
            }
        }

        return transcription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func readAudioFile(url: URL) throws -> [Float] {
        // Read WAV file
        let data = try Data(contentsOf: url)

        // Skip WAV header (44 bytes)
        let headerSize = 44
        guard data.count > headerSize else {
            throw TranscriptionError.invalidAudioFile
        }

        let audioData = data.dropFirst(headerSize)

        // Convert Int16 samples to Float
        let int16Samples = audioData.withUnsafeBytes { buffer -> [Int16] in
            let int16Buffer = buffer.bindMemory(to: Int16.self)
            return Array(int16Buffer)
        }

        let floatSamples = int16Samples.map { Float($0) / Float(Int16.max) }
        return floatSamples
    }

    deinit {
        if let context = currentContext {
            whisper_free(context)
        }
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotFound
    case initializationFailed
    case contextNotInitialized
    case processingFailed
    case invalidAudioFile

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Whisper model not found. Please download it first."
        case .initializationFailed:
            return "Failed to initialize Whisper model."
        case .contextNotInitialized:
            return "Whisper context not initialized."
        case .processingFailed:
            return "Failed to process audio."
        case .invalidAudioFile:
            return "Invalid audio file format."
        }
    }
}
