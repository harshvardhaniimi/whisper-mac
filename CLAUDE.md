# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kalam is a native macOS menu bar app for speech-to-text transcription. It uses Apple's Speech framework (SFSpeechRecognizer) for transcription. All processing is local.

## Build Commands

```bash
# Build standalone .app bundle (recommended)
./build-app.sh

# Run the app bundle
open Kalam.app

# Build from command line (debug)
swift build

# Build App Store variant (sandbox-compatible, no global hotkey/text insertion)
./build-appstore.sh
```

In Xcode: `open Package.swift`, then ⌘+B to build, ⌘+R to run.

## Architecture

### App Entry Point
- `KalamApp.swift` - Main app with `AppDelegate` that creates the menu bar status item and popover
- The app is a menu bar app (LSUIElement=true in Info.plist) - no Dock icon

### Central State
- `AppState.swift` - Singleton (`AppState.shared`) that coordinates all services and holds published state for UI binding. Manages recording lifecycle, transcription flow, and service initialization.

### Services (Sources/Kalam/Services/)
- `AudioCaptureService` - Records via AVAudioEngine, resamples to 16kHz WAV, calculates audio levels
- `WhisperService` - Wraps SFSpeechRecognizer for transcription
- `GlobalHotkeyManager` - Registers Cmd+Shift+Space global hotkey via Carbon RegisterEventHotKey API (no Accessibility permissions needed for hotkey). Disabled in App Store build via `#if !APP_STORE_BUILD`.
- `TextInsertionService` - Inserts transcribed text at cursor via clipboard + simulated Cmd+V paste. Clipboard-only in App Store build via `#if !APP_STORE_BUILD`.
- `ModelManager` - Model management (currently no-op since using Apple Speech)
- `HistoryManager` - Persists transcription history
- `NotificationService` - Audio feedback and system notifications

### Views (Sources/Kalam/Views/)
- `MainView` - Popover content (recording button, waveform, transcription display, quit button)
- `MainWindowView` - Full window interface with drag-drop file transcription
- `SettingsView` - Model selection, language, hotkey toggle
- `WaveformView` - Real-time audio level visualization
- `HistoryView` - Past transcriptions with search
- `RecordingIndicatorWindow` - Floating overlay that appears near cursor during recording (pulsing mic icon)

### Models (Sources/Kalam/Models/)
- `Transcription` - Transcription record (text, date, duration, language, source file)
- `WhisperModel` - Enum of model sizes (tiny/base/small/medium/large)

### Key Flows
1. **Hotkey Recording**: GlobalHotkeyManager receives Cmd+Shift+Space → AppState.handleHotkeyPress → RecordingIndicatorWindow.show() → AudioCaptureService records → WhisperService transcribes → TextInsertionService pastes at cursor
2. **UI Recording**: MainView record button → AppState.startRecording/stopRecording → same transcription flow
3. **File Transcription**: Drop file in MainWindowView → AppState.transcribeFile → WhisperService.transcribeFile

## Dual Build System
- **Direct distribution** (`./build-app.sh`): Full features including global hotkey and text insertion at cursor
- **App Store** (`./build-appstore.sh`): Sandbox-compatible build with `-DAPP_STORE_BUILD` flag. Global hotkey and CGEvent text insertion are disabled. Users use clipboard copy/paste instead.

## Required Permissions
- **Microphone**: Recording audio
- **Accessibility**: Text insertion at cursor (optional - the hotkey itself does NOT require this; not used in App Store build)
- **Speech Recognition**: SFSpeechRecognizer authorization

Grant Accessibility permissions in: System Settings → Privacy & Security → Accessibility → Enable Kalam (only needed for auto-inserting text at cursor)

## Data Storage
- Models: `~/Library/Application Support/Kalam/models/`
- History: Managed by HistoryManager

## Frameworks Used
- SwiftUI for UI
- AVFoundation for audio capture
- Speech framework for transcription
- Carbon for global hotkey registration (RegisterEventHotKey) — direct distribution only
- ApplicationServices for text insertion via Accessibility API — direct distribution only
- UserNotifications for system notifications (when available)
