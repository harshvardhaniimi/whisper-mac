import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Main content
            if appState.isProcessing {
                processingView
            } else if !appState.currentTranscription.isEmpty {
                transcriptionView
            } else {
                emptyStateView
            }

            Divider()

            // Waveform
            if appState.isRecording {
                WaveformView(audioLevel: appState.audioLevel)
                    .frame(height: 60)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)

                Divider()
            }

            // Controls
            controls
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.accent)

            Text("Whisper")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Spacer()

            Button(action: { showHistory.toggle() }) {
                Image(systemName: "clock")
            }
            .buttonStyle(IconButtonStyle())
            .popover(isPresented: $showHistory) {
                HistoryView()
                    .environmentObject(appState)
                    .frame(width: 500, height: 600)
            }

            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(IconButtonStyle())
            .popover(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appState)
                    .frame(width: 500, height: 400)
            }
        }
        .padding(DesignSystem.Spacing.md)
    }

    // MARK: - Content Views

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "mic.circle")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.primary.opacity(0.3))

            Text("Ready to transcribe")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Text("Click record to start")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var processingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Transcribing...")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var transcriptionView: some View {
        ScrollView {
            Text(appState.currentTranscription)
                .font(DesignSystem.Typography.transcription)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Record button
            Button(action: {
                Task {
                    if appState.isRecording {
                        await appState.stopRecording()
                    } else {
                        try? await appState.startRecording()
                    }
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if appState.isRecording {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 20))
                        Text("Stop Recording")
                    } else {
                        Image(systemName: "record.circle")
                            .font(.system(size: 20))
                        Text("Record")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(appState.isProcessing)

            // Copy button (only show when there's transcription)
            if !appState.currentTranscription.isEmpty {
                Button(action: {
                    appState.copyToClipboard()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Copy to Clipboard")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            // Status bar
            statusBar
        }
        .padding(DesignSystem.Spacing.md)
    }

    private var statusBar: some View {
        HStack {
            // Model info
            Text("Model: \(appState.selectedModel.displayName)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Spacer()

            // Language
            Text("Language: \(appState.selectedLanguage)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Spacer()

            // Duration
            if appState.isRecording {
                Text(formatDuration(appState.recordingDuration))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.recordingRed)
                    .monospacedDigit()
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
}
