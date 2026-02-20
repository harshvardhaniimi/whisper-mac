# Local Kalam App - Implementation Plan

## Project Overview
Build a native macOS speech-to-text application using OpenAI's open-source Whisper model, running entirely locally with no cloud dependencies. The app should have a sophisticated, retro-inspired design with native macOS aesthetics similar to Apple's first-party apps or Claude's refined interface.

## Design Philosophy
- **Retro but sophisticated**: Think classic Mac apps from the mid-2000s with modern refinement
- **Not cartoonish**: Avoid skeuomorphism; use subtle textures and refined typography
- **Native feel**: Leverage macOS design patterns (SF Symbols, system fonts, native controls)
- **Unique personality**: Subtle animations, thoughtful color palette, distinctive but not distracting
- **Claude-inspired**: Clean whitespace, clear hierarchy, conversational interface elements

## Technical Stack Recommendation

### Option A: Native Swift/SwiftUI (RECOMMENDED)
**Pros:**
- Best performance and native feel
- Access to all macOS APIs (Metal, Core Audio, etc.)
- Smaller app size, better battery life
- True native design integration

**Stack:**
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI for modern declarative UI
- **Whisper Integration**: whisper.cpp via Swift bridging
- **Audio**: AVFoundation for capture
- **GPU Acceleration**: Metal Performance Shaders for Apple Silicon optimization

### Option B: Tauri + Rust (Alternative)
**Pros:**
- Cross-platform potential
- Rust performance for whisper.cpp integration
- Web technologies for UI flexibility

**Stack:**
- **Frontend**: SvelteKit/React with TypeScript
- **Backend**: Rust + Tauri
- **Whisper**: whisper.cpp Rust bindings

## Architecture Design

```
┌─────────────────────────────────────────┐
│         SwiftUI Interface Layer         │
│  (Menu Bar + Main Window + Settings)   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│       Application Layer (Swift)         │
│  • TranscriptionManager                 │
│  • AudioCaptureManager                  │
│  • ModelManager                         │
│  • HistoryManager                       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Core Services (Swift/C++)          │
│  • whisper.cpp bridge                   │
│  • Metal GPU acceleration               │
│  • Core Audio integration               │
└─────────────────────────────────────────┘
```

## Key Features

### Phase 1: Core Functionality
1. **Audio Capture**
   - Record from system microphone
   - Real-time audio level visualization
   - Support for different input devices
   - Audio quality presets

2. **Whisper Integration**
   - Download and manage Whisper models (tiny, base, small, medium, large)
   - Automatic model selection based on device capabilities
   - Offline transcription processing
   - Support for multiple languages

3. **Basic UI**
   - Menu bar icon with quick access
   - Main transcription window
   - Recording controls (start/stop)
   - Live transcription display
   - Copy to clipboard functionality

### Phase 2: Enhanced Features
1. **File Transcription**
   - Drag & drop audio files
   - Support for common formats (MP3, M4A, WAV, etc.)
   - Batch processing

2. **Advanced UI**
   - Transcription history
   - Search through past transcriptions
   - Export options (TXT, MD, JSON, SRT)
   - Dark/light mode with accent color customization
   - Settings panel for model selection, language, etc.

3. **System Integration**
   - Global hotkey for quick recording
   - System-wide services integration
   - Notification center updates
   - Spotlight integration for history search

### Phase 3: Polish & Optimization
1. **Performance**
   - Streaming transcription (show results as they come)
   - Background processing
   - Efficient memory management
   - Model caching

2. **UX Enhancements**
   - Keyboard shortcuts for everything
   - Custom timestamps
   - Speaker diarization (if feasible)
   - Punctuation and formatting options
   - Confidence indicators

## UI/UX Design Specifications

### Color Palette
- **Primary**: Soft blue-gray (#6B7280) with subtle warmth
- **Accent**: Adaptive - follows system accent or custom (e.g., muted purple #8B7FA8)
- **Background Light**: Warm white (#FAFAF9)
- **Background Dark**: Rich dark (#1C1C1E)
- **Text**: System-native with proper contrast
- **Status Colors**: Green (#34C759), Orange (#FF9500), Red (#FF3B30)

### Typography
- **Primary**: SF Pro (system font)
- **Monospace**: SF Mono for transcription text
- **Sizes**: Follow Apple's HIG - Title 1 (28pt), Title 2 (22pt), Body (17pt), etc.

### UI Components

#### Menu Bar Icon
- Custom SF Symbol-style icon (waveform or microphone)
- Animated when recording (subtle pulse)
- Color changes based on state (idle/recording/processing)

#### Main Window
```
┌────────────────────────────────────────────┐
│  🎤 Whisper                    ⚙️  📁  🔍    │  ← Toolbar
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │                                      │ │
│  │     [Transcription appears here]    │ │  ← Main content area
│  │     with nice typography and         │ │     (scrollable)
│  │     subtle fade-in animation         │ │
│  │                                      │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌────────────────────────────────────┐   │
│  │     [Audio waveform visualization] │   │  ← Waveform
│  └────────────────────────────────────┘   │
│                                            │
│       ●  Record    ⏸  Pause    ⎘  Copy    │  ← Controls
│                                            │
│  Model: Small • Language: Auto • 00:42    │  ← Status bar
└────────────────────────────────────────────┘
```

#### Settings Window
- Grouped preferences (General, Audio, Models, Advanced)
- Native macOS settings style
- Live previews where applicable

### Animation & Motion
- **Recording start**: Gentle scale + opacity fade-in
- **Transcription**: Words appear with subtle fade-in
- **Processing**: Elegant spinner or progress indicator
- **Transitions**: 0.3s ease-in-out for most transitions
- **Microphone level**: Real-time waveform with smooth interpolation

## Step-by-Step Implementation Tasks

### Setup & Foundation
- [ ] Initialize Xcode project with SwiftUI + Swift Package Manager
- [ ] Set up project structure and folder organization
- [ ] Add whisper.cpp as dependency (via SPM or manual integration)
- [ ] Create basic app architecture (managers, models, views)
- [ ] Set up Core Audio permission handling

### Whisper Integration
- [ ] Create Swift bridge to whisper.cpp
- [ ] Implement model downloader with progress tracking
- [ ] Add model management (list, download, delete, switch)
- [ ] Create transcription service wrapper
- [ ] Test with sample audio files
- [ ] Optimize for Apple Silicon (Metal acceleration)

### Audio Capture
- [ ] Implement AVAudioEngine-based recording
- [ ] Add microphone permission flow
- [ ] Create audio device selector
- [ ] Implement real-time audio level monitoring
- [ ] Add audio format conversion pipeline
- [ ] Handle audio interruptions gracefully

### Core UI - Menu Bar
- [ ] Create menu bar app with NSStatusItem
- [ ] Design and implement menu bar icon
- [ ] Add popover or window presentation
- [ ] Implement quick recording from menu bar
- [ ] Add status indicators (idle/recording/processing)

### Core UI - Main Window
- [ ] Create main SwiftUI window structure
- [ ] Implement recording controls
- [ ] Add transcription text display with proper styling
- [ ] Create audio waveform visualization
- [ ] Add copy to clipboard functionality
- [ ] Implement keyboard shortcuts

### Settings & Preferences
- [ ] Create settings window with native macOS style
- [ ] Add model selection interface
- [ ] Implement language selection
- [ ] Add audio input device selector
- [ ] Create custom accent color picker
- [ ] Add keyboard shortcut customization

### History & Storage
- [ ] Design data model for transcription history
- [ ] Implement Core Data or SwiftData storage
- [ ] Create history view with list/grid layouts
- [ ] Add search functionality
- [ ] Implement export options (TXT, MD, JSON, SRT)
- [ ] Add history management (delete, clear all)

### File Transcription
- [ ] Add drag & drop support for audio files
- [ ] Implement file format detection and conversion
- [ ] Create batch processing queue
- [ ] Add progress tracking for file transcription
- [ ] Implement cancel/pause operations

### Advanced Features
- [ ] Implement global hotkey for quick recording
- [ ] Add system services integration
- [ ] Create notification center updates
- [ ] Add streaming transcription (real-time results)
- [ ] Implement confidence score display
- [ ] Add custom vocabulary/prompt support

### Polish & Optimization
- [ ] Implement dark/light mode
- [ ] Add smooth animations and transitions
- [ ] Optimize memory usage (especially for large models)
- [ ] Add error handling and user feedback
- [ ] Implement logging and diagnostics
- [ ] Create onboarding flow for first-time users
- [ ] Add help documentation and tooltips

### Testing & Distribution
- [ ] Write unit tests for core logic
- [ ] Test on different Mac hardware (Intel vs Apple Silicon)
- [ ] Test with various audio inputs and quality levels
- [ ] Performance profiling and optimization
- [ ] Code signing and notarization setup
- [ ] Create DMG installer with custom design
- [ ] Write comprehensive README with screenshots

## Technical Considerations

### Model Selection Strategy
- **Tiny (75MB)**: Fast, lower accuracy - good for quick notes
- **Base (142MB)**: Balanced - recommended default
- **Small (466MB)**: Better accuracy - good for most users
- **Medium (1.5GB)**: High accuracy - for capable machines
- **Large (2.9GB)**: Best accuracy - for power users with good hardware

Auto-detect based on:
- Available RAM
- CPU/GPU capabilities (Apple Silicon vs Intel)
- User preference

### Performance Optimization
1. **Model Loading**: Lazy load and cache models in memory
2. **Audio Processing**: Use ring buffers for efficient capture
3. **Metal Acceleration**: Leverage Apple Silicon GPU for inference
4. **Threading**: Run transcription on background queue
5. **Memory**: Implement proper cleanup and memory warnings

### Privacy & Security
- All processing happens locally (no network calls except model downloads)
- Clear privacy policy in app
- Sandbox compliance
- Secure storage for transcription history
- Option to disable history entirely

### Error Handling
- Graceful fallbacks for permission denials
- Clear error messages for users
- Recovery strategies for failed transcriptions
- Network error handling for model downloads
- Low disk space warnings

## Dependencies

### Swift Packages
```swift
dependencies: [
    .package(url: "https://github.com/ggerganov/whisper.cpp", branch: "master"),
    // Audio visualization
    .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.0"),
]
```

### System Frameworks
- SwiftUI
- AVFoundation
- Core Audio
- Metal
- Core Data / SwiftData
- AppKit (for menu bar)

## Project Structure

```
Kalam/
├── Kalam.xcodeproj
├── Kalam/
│   ├── App/
│   │   ├── KalamApp.swift               # App entry point
│   │   └── AppDelegate.swift            # App delegate for menu bar
│   ├── Models/
│   │   ├── Transcription.swift          # Data models
│   │   ├── WhisperModel.swift
│   │   └── AppSettings.swift
│   ├── Services/
│   │   ├── WhisperService.swift         # Whisper integration
│   │   ├── AudioCaptureService.swift    # Recording
│   │   ├── ModelManager.swift           # Model downloads
│   │   └── HistoryManager.swift         # Storage
│   ├── Views/
│   │   ├── MainWindow/
│   │   │   ├── MainWindowView.swift
│   │   │   ├── TranscriptionView.swift
│   │   │   ├── WaveformView.swift
│   │   │   └── ControlsView.swift
│   │   ├── MenuBar/
│   │   │   ├── MenuBarView.swift
│   │   │   └── MenuBarIconView.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── GeneralSettings.swift
│   │   │   ├── AudioSettings.swift
│   │   │   └── ModelSettings.swift
│   │   └── History/
│   │       ├── HistoryView.swift
│   │       └── HistoryItemView.swift
│   ├── ViewModels/
│   │   ├── MainViewModel.swift
│   │   ├── SettingsViewModel.swift
│   │   └── HistoryViewModel.swift
│   ├── Utilities/
│   │   ├── AudioConverter.swift
│   │   ├── FileExporter.swift
│   │   └── HotkeyManager.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Info.plist
│   └── Bridge/
│       ├── WhisperBridge.h              # C++ bridge header
│       └── WhisperBridge.mm             # C++ bridge implementation
├── KalamTests/
└── README.md
```

## Timeline Estimate (for Claude Code execution)

**Phase 1 (Core)**: ~50 tasks
- Project setup and Whisper integration
- Basic audio capture
- Simple UI with menu bar and main window
- Basic transcription functionality

**Phase 2 (Enhanced)**: ~30 tasks
- File transcription support
- History and search
- Settings panel
- Export functionality

**Phase 3 (Polish)**: ~20 tasks
- Advanced features (hotkeys, streaming, etc.)
- UI/UX refinement
- Performance optimization
- Testing and distribution prep

## Success Criteria

- [ ] App launches and shows menu bar icon
- [ ] Can record audio from microphone with visual feedback
- [ ] Successfully transcribes audio using Whisper model
- [ ] Displays transcription with good typography and layout
- [ ] Can copy transcription to clipboard
- [ ] Settings allow model and language selection
- [ ] History saves and retrieves past transcriptions
- [ ] App feels native and responsive
- [ ] Uses < 200MB RAM when idle, < 2GB when processing (medium model)
- [ ] Transcription latency < 10s for 1min audio (on M1/M2 Macs)

## Design Inspirations

1. **Apple Native Apps**: Look at Voice Memos, Notes, Reminders for UI patterns
2. **Claude.ai**: Clean layout, thoughtful spacing, conversational elements
3. **Retro Mac Apps**: Classic Mac apps like iTunes (pre-redesign), iPhoto for that nostalgic feel
4. **Modern Minimalism**: Avoid clutter, every element should have purpose

## Additional Notes

- Start with the simplest possible version that works
- Prioritize performance on Apple Silicon (M1/M2/M3)
- Keep the design clean and uncluttered
- Make keyboard shortcuts powerful and intuitive
- Consider accessibility from the start (VoiceOver support)
- Document code as you go for future maintenance

## Getting Started Command for Claude Code

```
Start by setting up the Xcode project structure, integrating whisper.cpp,
and creating a basic SwiftUI app with menu bar icon. Then implement audio
recording and basic transcription. Focus on making it work first, then
refine the design to match our aesthetic goals.
```

---

**Good luck! This should be a fun project that creates a genuinely useful tool.** 🎤✨
