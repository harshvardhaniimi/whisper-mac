import Foundation

enum WhisperModel: String, CaseIterable, Identifiable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    case medium = "medium"
    case large = "large"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    /// WhisperKit CoreML model identifier for downloading from HuggingFace.
    var whisperKitModelName: String {
        switch self {
        case .tiny:   return "openai_whisper-tiny"
        case .base:   return "openai_whisper-base"
        case .small:  return "openai_whisper-small"
        case .medium: return "openai_whisper-medium"
        case .large:  return "openai_whisper-large-v3"
        }
    }

    /// Directory name where this model is stored locally.
    var folderName: String {
        whisperKitModelName
    }

    var fileSize: String {
        switch self {
        case .tiny:   return "~70 MB"
        case .base:   return "~140 MB"
        case .small:  return "~470 MB"
        case .medium: return "~1.5 GB"
        case .large:  return "~3.1 GB"
        }
    }

    var description: String {
        switch self {
        case .tiny:   return "Fast, lower accuracy"
        case .base:   return "Balanced - recommended"
        case .small:  return "Better accuracy"
        case .medium: return "High accuracy"
        case .large:  return "Best accuracy (large-v3)"
        }
    }
}
