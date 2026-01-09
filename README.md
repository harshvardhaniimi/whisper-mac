# Whisper Mac 🎤

A beautiful, native macOS app for speech-to-text transcription using OpenAI's Whisper model. Completely local, private, and free.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

✨ **Completely Local** - All processing happens on your Mac. No cloud, no subscriptions, no data leaves your computer.

🎨 **Beautiful Native UI** - Retro-inspired design with modern refinement, featuring a menu bar app and full window interface.

🎙️ **Real-time Recording** - Record directly from your microphone with live audio level visualization.

📁 **File Transcription** - Drag & drop audio files (MP3, WAV, M4A, etc.) for batch transcription.

🌍 **Multi-language Support** - Transcribe in 50+ languages including English, Spanish, French, German, Chinese, Japanese, and more.

📊 **Multiple Model Sizes** - Choose from 5 model sizes (tiny to large) based on your needs and hardware capabilities.

💾 **History & Search** - Automatic history saving with full-text search across all transcriptions.

📤 **Export Options** - Export as Text, Markdown, JSON, or SRT subtitle format.

⚡ **Apple Silicon Optimized** - Leverages Metal and Accelerate frameworks for blazing-fast performance on M1/M2/M3 Macs.

## Screenshots

*(Menu Bar App)*
```
┌─────────────────────────────────────┐
│ 🎤 Whisper              🕐 ⚙️       │
├─────────────────────────────────────┤
│                                     │
│   Ready to transcribe               │
│   Click record to start             │
│                                     │
│   [Waveform Visualization]          │
│                                     │
│        ● Record                     │
│                                     │
│   Model: Base • Language: Auto      │
└─────────────────────────────────────┘
```

## Installation

### Option 1: Build from Source (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/whisper-mac.git
   cd whisper-mac
   ```

2. **Run the setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Open in Xcode:**
   ```bash
   open Package.swift
   ```

4. **Build and run** (⌘+R)

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for detailed build instructions.

### Option 2: Download Pre-built App

*(Coming soon - releases will be available on GitHub)*

## Quick Start

1. **Launch the app** - A waveform icon will appear in your menu bar

2. **Download a model:**
   - Click the menu bar icon → Settings (⚙️)
   - Download at least one model (Base recommended for first-time users)
   - Models are 75 MB - 2.9 GB depending on size

3. **Start transcribing:**
   - Click the menu bar icon
   - Click "Record" and speak
   - Click "Stop Recording" when done
   - Wait a few seconds for transcription

4. **Or transcribe a file:**
   - Drag & drop an audio file into the app window
   - Wait for processing

## Model Selection Guide

| Model  | Size   | Speed  | Accuracy | Best For                    |
|--------|--------|--------|----------|-----------------------------|
| Tiny   | 75 MB  | ⚡⚡⚡⚡  | ⭐⭐     | Quick notes, older hardware |
| Base   | 142 MB | ⚡⚡⚡   | ⭐⭐⭐    | General use (recommended)   |
| Small  | 466 MB | ⚡⚡    | ⭐⭐⭐⭐   | Better accuracy             |
| Medium | 1.5 GB | ⚡     | ⭐⭐⭐⭐⭐  | High accuracy, good hardware|
| Large  | 2.9 GB | ⚡     | ⭐⭐⭐⭐⭐⭐ | Best accuracy, powerful Macs|

**Recommendation:**
- **M1/M2/M3 Macs**: Start with Base or Small
- **Intel Macs**: Start with Tiny or Base
- **Quick notes**: Tiny or Base
- **Important transcriptions**: Small or Medium

## System Requirements

- **macOS 13.0 (Ventura) or later**
- **RAM:**
  - 8 GB minimum (for tiny/base models)
  - 16 GB recommended (for small/medium models)
  - 32 GB for large model
- **Storage:** 100 MB - 3 GB per model
- **Microphone** (for recording)

**Performance Notes:**
- Apple Silicon (M1/M2/M3) provides ~10x better performance than Intel
- Base model on M1: ~6 seconds to transcribe 1 minute of audio
- Real-time transcription possible on Apple Silicon with small models

## Privacy

🔒 **Your privacy is paramount:**

- ✅ All processing happens locally on your Mac
- ✅ No internet connection required (except for model downloads)
- ✅ No data collection or telemetry
- ✅ No cloud services or external APIs
- ✅ Audio never leaves your device
- ✅ Transcription history stored locally only
- ✅ You have full control over all data

Models are downloaded once from Hugging Face and stored locally:
```
~/Library/Application Support/WhisperMac/models/
```

## Technical Details

**Architecture:**
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Audio**: AVFoundation
- **ML Backend**: whisper.cpp (optimized C++ implementation)
- **Acceleration**: Metal + Accelerate frameworks

**Design Philosophy:**
- Native macOS design patterns
- Retro-inspired but modern aesthetic
- Clean, minimal interface
- Keyboard-first workflow
- Subtle, purposeful animations

## Keyboard Shortcuts

*(Coming in future updates)*

- `⌘+R` - Start/Stop recording
- `⌘+C` - Copy transcription
- `⌘+,` - Settings
- `⌘+H` - Show history

## Roadmap

- [x] Core transcription functionality
- [x] Menu bar app interface
- [x] Full window interface
- [x] Model management
- [x] History with search
- [x] Export functionality
- [ ] Global hotkey for quick recording
- [ ] Streaming transcription (real-time results)
- [ ] Custom vocabulary support
- [ ] Speaker diarization
- [ ] Timestamp display
- [ ] Keyboard shortcuts
- [ ] Dark/light mode customization
- [ ] App Store distribution

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for development setup.

## Troubleshooting

**App doesn't appear in menu bar:**
- Check that `LSUIElement` is set in Info.plist
- Restart the app

**Microphone not working:**
- System Settings → Privacy & Security → Microphone
- Enable permission for WhisperMac

**Poor transcription quality:**
- Try a larger model (small or medium)
- Ensure good audio quality (clear voice, minimal background noise)
- Check microphone input levels

**Slow performance:**
- Use a smaller model (tiny or base)
- Close resource-intensive apps
- Check Activity Monitor for CPU/RAM usage

**Model download fails:**
- Check internet connection
- Try again (downloads can be large)
- Manually download from Hugging Face if needed

## Credits

- **OpenAI Whisper** - The incredible speech recognition model: https://github.com/openai/whisper
- **whisper.cpp** - Efficient C++ implementation: https://github.com/ggerganov/whisper.cpp
- **Design inspiration** - Apple HIG, Claude.ai, classic Mac apps

## License

MIT License - see LICENSE file for details.

This project uses OpenAI's Whisper model, which is also licensed under MIT.

## Support

- 📖 Read the [Build Instructions](BUILD_INSTRUCTIONS.md)
- 📖 Read the [Implementation Plan](IMPLEMENTATION_PLAN.md)
- 🐛 Report issues on GitHub
- ⭐ Star the project if you find it useful!

## Author

Built with ❤️ for the Mac community.

---

**Note**: This app is not affiliated with OpenAI. Whisper is an open-source model created by OpenAI.
