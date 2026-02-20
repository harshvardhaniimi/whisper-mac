import Foundation
import Speech

@MainActor
class ModelManager: ObservableObject {
    @Published var downloadProgress: [WhisperModel: Double] = [:]
    @Published var installedModels: Set<WhisperModel> = []
    @Published var isDownloading = false

    init() {
        // All models are "installed" since we use Apple Speech
        checkInstalledModels()
    }

    func checkInstalledModels() {
        // With Apple Speech, all models are always available
        installedModels = Set(WhisperModel.allCases)
    }

    func getModelPath(_ model: WhisperModel) -> URL {
        // Not used with Apple Speech, but kept for compatibility
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("\(AppBrand.appSupportDirectoryName)/models/\(model.filename)")
    }

    func isModelInstalled(_ model: WhisperModel) -> Bool {
        // All models are available with Apple Speech
        return true
    }

    func downloadModel(_ model: WhisperModel) async throws {
        // No download needed with Apple Speech
        // Just mark as complete
        installedModels.insert(model)
    }

    func deleteModel(_ model: WhisperModel) throws {
        // No-op for Apple Speech
    }

    func getModelSize(_ model: WhisperModel) -> String? {
        // Apple Speech models are built-in
        return "Built-in"
    }
}

enum ModelError: LocalizedError {
    case downloadFailed
    case modelNotFound

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to initialize speech recognition."
        case .modelNotFound:
            return "Speech recognition not available."
        }
    }
}
