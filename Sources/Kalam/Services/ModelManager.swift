import Foundation
import WhisperKit

@MainActor
class ModelManager: ObservableObject {
    @Published var downloadProgress: [WhisperModel: Double] = [:]
    @Published var installedModels: Set<WhisperModel> = []
    @Published var isDownloading = false

    private let modelRepo = "argmaxinc/whisperkit-coreml"

    /// Base directory for all WhisperKit models
    var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        let dir = appSupport
            .appendingPathComponent(AppBrand.appSupportDirectoryName, isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        checkInstalledModels()
    }

    /// Scan the models directory and update installedModels set
    func checkInstalledModels() {
        var found = Set<WhisperModel>()
        for model in WhisperModel.allCases {
            let modelPath = modelsDirectory.appendingPathComponent(model.folderName)
            if FileManager.default.fileExists(atPath: modelPath.path) {
                found.insert(model)
            }
        }
        installedModels = found
    }

    func getModelPath(_ model: WhisperModel) -> URL {
        modelsDirectory.appendingPathComponent(model.folderName)
    }

    func isModelInstalled(_ model: WhisperModel) -> Bool {
        installedModels.contains(model)
    }

    /// Download a model using WhisperKit's download API with progress tracking
    func downloadModel(_ model: WhisperModel) async throws {
        guard !isDownloading else {
            throw ModelError.downloadInProgress
        }

        isDownloading = true
        downloadProgress[model] = 0.0

        do {
            let _ = try await WhisperKit.download(
                variant: model.whisperKitModelName,
                downloadBase: modelsDirectory,
                useBackgroundSession: false,
                from: modelRepo,
                progressCallback: { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.downloadProgress[model] = progress.fractionCompleted
                    }
                }
            )

            installedModels.insert(model)
            downloadProgress.removeValue(forKey: model)
        } catch {
            downloadProgress.removeValue(forKey: model)
            isDownloading = false
            throw ModelError.downloadFailed
        }

        isDownloading = false
    }

    /// Delete a model's files from disk
    func deleteModel(_ model: WhisperModel) throws {
        let modelPath = getModelPath(model)
        if FileManager.default.fileExists(atPath: modelPath.path) {
            try FileManager.default.removeItem(at: modelPath)
        }
        installedModels.remove(model)
    }
}

enum ModelError: LocalizedError {
    case downloadFailed
    case downloadInProgress
    case modelNotFound

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download model. Check your internet connection."
        case .downloadInProgress:
            return "A model download is already in progress."
        case .modelNotFound:
            return "Model not found. Please download it first."
        }
    }
}
