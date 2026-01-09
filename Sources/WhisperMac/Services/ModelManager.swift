import Foundation

@MainActor
class ModelManager: ObservableObject {
    @Published var downloadProgress: [WhisperModel: Double] = [:]
    @Published var installedModels: Set<WhisperModel> = []
    @Published var isDownloading = false

    private let modelsDirectory: URL

    init() {
        // Set up models directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        modelsDirectory = appSupport.appendingPathComponent("WhisperMac/models", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

        // Check which models are installed
        checkInstalledModels()
    }

    func checkInstalledModels() {
        installedModels.removeAll()

        for model in WhisperModel.allCases {
            let modelPath = modelsDirectory.appendingPathComponent(model.filename)
            if FileManager.default.fileExists(atPath: modelPath.path) {
                installedModels.insert(model)
            }
        }
    }

    func getModelPath(_ model: WhisperModel) -> URL {
        return modelsDirectory.appendingPathComponent(model.filename)
    }

    func isModelInstalled(_ model: WhisperModel) -> Bool {
        return installedModels.contains(model)
    }

    func downloadModel(_ model: WhisperModel) async throws {
        guard !isModelInstalled(model) else { return }

        isDownloading = true
        downloadProgress[model] = 0.0

        defer {
            isDownloading = false
            downloadProgress[model] = nil
        }

        let url = model.downloadURL
        let destination = getModelPath(model)

        // Download with progress tracking
        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ModelError.downloadFailed
        }

        let expectedLength = Int(httpResponse.expectedContentLength)
        var receivedData = Data()
        receivedData.reserveCapacity(expectedLength)

        for try await byte in asyncBytes {
            receivedData.append(byte)

            // Update progress
            let progress = Double(receivedData.count) / Double(expectedLength)
            await MainActor.run {
                downloadProgress[model] = progress
            }
        }

        // Write to file
        try receivedData.write(to: destination)

        // Update installed models
        installedModels.insert(model)
    }

    func deleteModel(_ model: WhisperModel) throws {
        let modelPath = getModelPath(model)

        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            return
        }

        try FileManager.default.removeItem(at: modelPath)
        installedModels.remove(model)
    }

    func getModelSize(_ model: WhisperModel) -> String? {
        let modelPath = getModelPath(model)

        guard let attributes = try? FileManager.default.attributesOfItem(atPath: modelPath.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

enum ModelError: LocalizedError {
    case downloadFailed
    case modelNotFound

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download model. Please check your internet connection."
        case .modelNotFound:
            return "Model file not found. Please download it first."
        }
    }
}
