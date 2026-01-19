# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WhisperMac is a native macOS menu bar app for speech-to-text transcription. It uses Apple's Speech framework (SFSpeechRecognizer) for transcription. All processing is local.

## Build Commands

```bash
# Initial setup (clones whisper.cpp, copies sources, fixes C++ compatibility)
./setup.sh

# Build standalone .app bundle (recommended)
./build-app.sh

# Run the app bundle
./WhisperMac.app/Contents/MacOS/WhisperMac

# Or open the app normally
open WhisperMac.app

# Build from command line (debug)
swift build

# Fix build errors (Invalid Exclude, C++ compilation issues)
./fix-build.sh
```

In Xcode: `open Package.swift`, then ⌘+B to build, ⌘+R to run.

## Architecture

### App Entry Point
- `WhisperMacApp.swift` - Main app with `AppDelegate` that creates the menu bar status item and popover
- The app is a menu bar app (LSUIElement=true in Info.plist) - no Dock icon

### Central State
- `AppState.swift` - Singleton (`AppState.shared`) that coordinates all services and holds published state for UI binding. Manages recording lifecycle, transcription flow, and service initialization.

### Services (Sources/WhisperMac/Services/)
- `AudioCaptureService` - Records via AVAudioEngine, resamples to 16kHz WAV, calculates audio levels
- `WhisperService` - Wraps SFSpeechRecognizer for transcription
- `GlobalHotkeyManager` - Detects Ctrl+Ctrl double-press via CGEvent tap (requires Accessibility permissions)
- `TextInsertionService` - Inserts transcribed text at cursor via clipboard + simulated Cmd+V paste
- `ModelManager` - Model management (currently no-op since using Apple Speech)
- `HistoryManager` - Persists transcription history
- `NotificationService` - Audio feedback and system notifications

### Views (Sources/WhisperMac/Views/)
- `MainView` - Popover content (recording button, waveform, transcription display, quit button)
- `MainWindowView` - Full window interface with drag-drop file transcription
- `SettingsView` - Model selection, language, hotkey toggle
- `WaveformView` - Real-time audio level visualization
- `HistoryView` - Past transcriptions with search
- `RecordingIndicatorWindow` - Floating overlay that appears near cursor during recording (pulsing mic icon)

### Models (Sources/WhisperMac/Models/)
- `Transcription` - Transcription record (text, date, duration, language, source file)
- `WhisperModel` - Enum of model sizes (tiny/base/small/medium/large)

### Key Flows
1. **Hotkey Recording**: GlobalHotkeyManager detects Ctrl+Ctrl → AppState.handleHotkeyPress → RecordingIndicatorWindow.show() → AudioCaptureService records → WhisperService transcribes → TextInsertionService pastes at cursor
2. **UI Recording**: MainView record button → AppState.startRecording/stopRecording → same transcription flow
3. **File Transcription**: Drop file in MainWindowView → AppState.transcribeFile → WhisperService.transcribeFile

## Required Permissions
- **Microphone**: Recording audio
- **Accessibility**: Global hotkey (Ctrl+Ctrl) and text insertion at cursor
- **Speech Recognition**: SFSpeechRecognizer authorization

Grant Accessibility permissions in: System Settings → Privacy & Security → Accessibility → Enable WhisperMac

## Data Storage
- Models: `~/Library/Application Support/WhisperMac/models/`
- History: Managed by HistoryManager

## Frameworks Used
- SwiftUI for UI
- AVFoundation for audio capture
- Speech framework for transcription
- Carbon for global hotkey event tap
- ApplicationServices for text insertion via Accessibility API
- UserNotifications for system notifications (when available)
