import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedTranscription: Transcription?
    @State private var showExportDialog = false
    @State private var exportFormat: ExportFormat = .text

    private var filteredTranscriptions: [Transcription] {
        if searchText.isEmpty {
            return appState.transcriptionHistory
        } else {
            return appState.historyManager.search(query: searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            if appState.transcriptionHistory.isEmpty {
                emptyState
            } else {
                HSplitView {
                    // List
                    list

                    // Detail
                    if let transcription = selectedTranscription {
                        detail(for: transcription)
                    } else {
                        emptyDetail
                    }
                }
            }
        }
        .frame(width: 700, height: 600)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("History")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Spacer()

                // Clear all button
                if !appState.transcriptionHistory.isEmpty {
                    Button("Clear All") {
                        appState.historyManager.deleteAll()
                        appState.transcriptionHistory.removeAll()
                        selectedTranscription = nil
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                TextField("Search transcriptions...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.sm)
        }
        .padding(DesignSystem.Spacing.md)
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(filteredTranscriptions) { transcription in
                    HistoryItemView(
                        transcription: transcription,
                        isSelected: selectedTranscription?.id == transcription.id
                    )
                    .onTapGesture {
                        selectedTranscription = transcription
                    }
                    .contextMenu {
                        Button("Copy Text") {
                            copyToClipboard(transcription.text)
                        }

                        Button("Delete") {
                            appState.historyManager.delete(transcription)
                            appState.transcriptionHistory.removeAll { $0.id == transcription.id }
                            if selectedTranscription?.id == transcription.id {
                                selectedTranscription = nil
                            }
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .frame(minWidth: 250, idealWidth: 300)
    }

    // MARK: - Detail

    private var emptyDetail: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.3))

            Text("Select a transcription")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func detail(for transcription: Transcription) -> some View {
        VStack(spacing: 0) {
            // Detail header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(transcription.formattedDate)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    HStack(spacing: DesignSystem.Spacing.md) {
                        Label(transcription.formattedDuration, systemImage: "clock")
                        Label(transcription.language, systemImage: "globe")
                        if let sourceFile = transcription.sourceFile {
                            Label(sourceFile, systemImage: "doc")
                        }
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Export menu
                Menu {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(format.rawValue) {
                            exportTranscription(transcription, as: format)
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(IconButtonStyle())

                // Copy button
                Button(action: {
                    copyToClipboard(transcription.text)
                }) {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(IconButtonStyle())

                // Delete button
                Button(action: {
                    appState.historyManager.delete(transcription)
                    appState.transcriptionHistory.removeAll { $0.id == transcription.id }
                    selectedTranscription = nil
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(IconButtonStyle())
            }
            .padding(DesignSystem.Spacing.md)

            Divider()

            // Transcription text
            ScrollView {
                Text(transcription.text)
                    .font(DesignSystem.Typography.transcription)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .frame(minWidth: 350)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.3))

            Text("No transcription history")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Text("Your transcriptions will appear here")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func exportTranscription(_ transcription: Transcription, as format: ExportFormat) {
        let content = appState.historyManager.export(transcription: transcription, format: format)

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "transcription.\(fileExtension(for: format))"
        panel.allowedContentTypes = [contentType(for: format)]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func fileExtension(for format: ExportFormat) -> String {
        switch format {
        case .text: return "txt"
        case .markdown: return "md"
        case .json: return "json"
        case .srt: return "srt"
        }
    }

    private func contentType(for format: ExportFormat) -> UTType {
        switch format {
        case .text: return .plainText
        case .markdown: return UTType(filenameExtension: "md") ?? .plainText
        case .json: return .json
        case .srt: return UTType(filenameExtension: "srt") ?? .plainText
        }
    }
}

struct HistoryItemView: View {
    let transcription: Transcription
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(transcription.preview)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)

            HStack {
                Text(transcription.formattedDate)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Spacer()

                Text(transcription.formattedDuration)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            isSelected ?
                DesignSystem.Colors.accent.opacity(0.2) :
                Color.clear
        )
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

