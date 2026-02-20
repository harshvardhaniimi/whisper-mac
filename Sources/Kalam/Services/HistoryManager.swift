import Foundation

class HistoryManager: ObservableObject {
    @Published var transcriptions: [Transcription] = []

    private let historyFileURL: URL

    init() {
        // Set up history file in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDirectory = appSupport.appendingPathComponent(AppBrand.appSupportDirectoryName, isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        historyFileURL = appDirectory.appendingPathComponent("history.json")

        // Load existing history
        loadHistory()
    }

    func save(_ transcription: Transcription) {
        transcriptions.insert(transcription, at: 0)
        saveHistory()
    }

    func delete(_ transcription: Transcription) {
        transcriptions.removeAll { $0.id == transcription.id }
        saveHistory()
    }

    func deleteAll() {
        transcriptions.removeAll()
        saveHistory()
    }

    func search(query: String) -> [Transcription] {
        guard !query.isEmpty else {
            return transcriptions
        }

        return transcriptions.filter { transcription in
            transcription.text.localizedCaseInsensitiveContains(query)
        }
    }

    func export(transcription: Transcription, format: ExportFormat) -> String {
        switch format {
        case .text:
            return transcription.text

        case .markdown:
            var output = "# Transcription\n\n"
            output += "**Date:** \(transcription.formattedDate)\n"
            output += "**Duration:** \(transcription.formattedDuration)\n"
            output += "**Language:** \(transcription.language)\n"
            if let sourceFile = transcription.sourceFile {
                output += "**Source:** \(sourceFile)\n"
            }
            output += "\n---\n\n"
            output += transcription.text
            return output

        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(transcription),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return ""

        case .srt:
            // Simple SRT format (subtitle format)
            var output = "1\n"
            output += "00:00:00,000 --> 00:00:\(String(format: "%02d", Int(transcription.duration))),000\n"
            output += transcription.text
            return output
        }
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            transcriptions = try decoder.decode([Transcription].self, from: data)
        } catch {
            print("Error loading history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(transcriptions)
            try data.write(to: historyFileURL)
        } catch {
            print("Error saving history: \(error)")
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case text = "Text"
    case markdown = "Markdown"
    case json = "JSON"
    case srt = "SRT (Subtitles)"
}
