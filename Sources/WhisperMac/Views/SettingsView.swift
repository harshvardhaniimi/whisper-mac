import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var modelManager = ModelManager()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)

            Divider()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Hotkey section
                    hotkeySection

                    Divider()

                    // Models section
                    modelSection

                    Divider()

                    // Language section
                    languageSection

                    Divider()

                    // About section
                    aboutSection
                }
                .padding(DesignSystem.Spacing.md)
            }
        }
        .frame(width: 500, height: 500)
    }

    // MARK: - Hotkey Section

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Global Hotkey")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Toggle(isOn: $appState.globalHotkeyEnabled) {
                Text("Enable Ctrl+Ctrl hotkey")
                    .font(DesignSystem.Typography.body)
            }
            .onChange(of: appState.globalHotkeyEnabled) { _ in
                appState.toggleGlobalHotkey()
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("How it works:")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)

                Text("• Press Ctrl twice quickly to start recording")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Text("• Speak your message")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Text("• Press Ctrl twice again to stop and transcribe")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Text("• Text is automatically inserted at your cursor and copied to clipboard")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.accent.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.sm)

            if !appState.hotkeyManager.checkAccessibilityPermissions() {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("Accessibility access required. Please enable in System Settings → Privacy & Security → Accessibility")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.warning.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
    }

    // MARK: - Model Section

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Whisper Models")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text("Download and manage Whisper models. Larger models provide better accuracy but require more resources.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(WhisperModel.allCases) { model in
                    ModelRow(model: model, modelManager: modelManager, appState: appState)
                }
            }
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Default Language")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Picker("Language", selection: $appState.selectedLanguage) {
                Text("Auto Detect").tag("auto")
                Divider()
                Text("English").tag("en")
                Text("Spanish").tag("es")
                Text("French").tag("fr")
                Text("German").tag("de")
                Text("Italian").tag("it")
                Text("Portuguese").tag("pt")
                Text("Chinese").tag("zh")
                Text("Japanese").tag("ja")
                Text("Korean").tag("ko")
                Text("Russian").tag("ru")
                Text("Arabic").tag("ar")
                Text("Hindi").tag("hi")
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("About")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("Version:")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("1.0.0")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }

                HStack {
                    Text("Powered by:")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("OpenAI Whisper")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }

            Text("All processing happens locally on your device. Your audio never leaves your computer.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.top, DesignSystem.Spacing.xs)
        }
    }
}

struct ModelRow: View {
    let model: WhisperModel
    @ObservedObject var modelManager: ModelManager
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Model info
            VStack(alignment: .leading, spacing: 2) {
                Text(model.displayName)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("\(model.description) • \(model.fileSize)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            // Status/Actions
            if modelManager.isModelInstalled(model) {
                // Select button
                if appState.selectedModel == model {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.success)
                        Text("Selected")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                } else {
                    Button("Select") {
                        appState.selectedModel = model
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                // Delete button
                Button(action: {
                    try? modelManager.deleteModel(model)
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(IconButtonStyle())
                .help("Delete model")

            } else if let progress = modelManager.downloadProgress[model] {
                // Downloading
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ProgressView(value: progress)
                        .frame(width: 80)
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .monospacedDigit()
                }
            } else {
                // Download button
                Button("Download") {
                    Task {
                        try? await modelManager.downloadModel(model)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(modelManager.isDownloading)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

