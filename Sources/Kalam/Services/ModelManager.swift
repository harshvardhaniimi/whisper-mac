import Foundation
import WhisperKit

@MainActor
class ModelManager: ObservableObject {
    @Published var downloadProgress: [WhisperModel: Double] = [:]
    @Published var installedModels: Set<WhisperModel> = []
    @Published var isDownloading = false

    private let modelRepo = "argmaxinc/whisperkit-coreml"
    private let pathsKey = "ModelManager.modelPaths"

    /// Persisted map of model raw value → actual folder path on disk
    private var modelPaths: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: pathsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: pathsKey) }
    }

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

    /// Scan for installed models using stored paths and HuggingFace cache
    func checkInstalledModels() {
        var found = Set<WhisperModel>()
        var paths = modelPaths

        for model in WhisperModel.allCases {
            // Check stored path first
            if let stored = paths[model.rawValue],
               FileManager.default.fileExists(atPath: stored) {
                found.insert(model)
                continue
            }

            // Fall back to scanning HuggingFace cache structure
            if let cachedURL = findModelInCache(model) {
                paths[model.rawValue] = cachedURL.path
                found.insert(model)
            }
        }

        modelPaths = paths
        installedModels = found
    }

    func getModelPath(_ model: WhisperModel) -> URL {
        if let stored = modelPaths[model.rawValue] {
            return URL(fileURLWithPath: stored)
        }
        // Fallback: scan HuggingFace cache
        if let cached = findModelInCache(model) {
            var paths = modelPaths
            paths[model.rawValue] = cached.path
            modelPaths = paths
            return cached
        }
        // Last resort (path won't exist, but callers check isModelInstalled first)
        return modelsDirectory.appendingPathComponent(model.folderName)
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
            let modelFolder = try await WhisperKit.download(
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

            // Store the actual path returned by WhisperKit
            var paths = modelPaths
            paths[model.rawValue] = modelFolder.path
            modelPaths = paths

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
        if let stored = modelPaths[model.rawValue],
           FileManager.default.fileExists(atPath: stored) {
            try FileManager.default.removeItem(atPath: stored)
        }
        var paths = modelPaths
        paths.removeValue(forKey: model.rawValue)
        modelPaths = paths
        installedModels.remove(model)
    }

    /// Search for a model in the HuggingFace hub cache structure
    private func findModelInCache(_ model: WhisperModel) -> URL? {
        let hubCacheDir = modelsDirectory
            .appendingPathComponent("models--argmaxinc--whisperkit-coreml")
            .appendingPathComponent("snapshots")

        guard let snapshots = try? FileManager.default.contentsOfDirectory(
            at: hubCacheDir,
            includingPropertiesForKeys: nil
        ) else { return nil }

        for snapshot in snapshots {
            let modelDir = snapshot.appendingPathComponent(model.folderName)
            if FileManager.default.fileExists(atPath: modelDir.path) {
                return modelDir
            }
        }
        return nil
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
