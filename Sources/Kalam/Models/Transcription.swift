import Foundation

struct Transcription: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date
    let duration: TimeInterval
    let language: String
    let sourceFile: String?

    init(
        id: UUID = UUID(),
        text: String,
        date: Date,
        duration: TimeInterval,
        language: String,
        sourceFile: String? = nil
    ) {
        self.id = id
        self.text = text
        self.date = date
        self.duration = duration
        self.language = language
        self.sourceFile = sourceFile
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var preview: String {
        let maxLength = 100
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }
}
