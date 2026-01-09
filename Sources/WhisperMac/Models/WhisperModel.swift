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

    var fileSize: String {
        switch self {
        case .tiny: return "75 MB"
        case .base: return "142 MB"
        case .small: return "466 MB"
        case .medium: return "1.5 GB"
        case .large: return "2.9 GB"
        }
    }

    var description: String {
        switch self {
        case .tiny: return "Fast, lower accuracy"
        case .base: return "Balanced - recommended"
        case .small: return "Better accuracy"
        case .medium: return "High accuracy"
        case .large: return "Best accuracy"
        }
    }

    var downloadURL: URL {
        let baseURL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
        return URL(string: "\(baseURL)/ggml-\(rawValue).bin")!
    }

    var filename: String {
        "ggml-\(rawValue).bin"
    }
}
