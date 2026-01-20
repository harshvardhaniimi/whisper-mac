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

⌨️ **Global Hotkey** - Press Ctrl twice to start/stop recording from anywhere. Text is automatically inserted at your cursor and copied to clipboard.

🚀 **Auto-Setup** - First launch automatically downloads the base model. No manual setup required - just install and use!

🔔 **Smart Notifications** - Audio/visual feedback when recording starts, stops, and transcription completes.

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

### Option 1: Quick Install (Recommended)

Run this in Terminal:
```bash
curl -sL https://raw.githubusercontent.com/harshvardhaniimi/whisper-mac/main/install.sh | bash
```

Then right-click the app in Applications and select "Open" (first time only).

### Option 2: Build from Source

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

### Option 3: Manual Download

1. **Download** the latest `WhisperMac.zip` from [Releases](https://github.com/harshvardhaniimi/whisper-mac/releases)
2. **Unzip** and move `WhisperMac.app` to your Applications folder
3. **Remove quarantine** (required for apps not notarized with Apple):
   ```bash
   xattr -cr /Applications/WhisperMac.app
   ```
4. **Open the app** - Right-click → Open (first time only)

## Quick Start

### First Launch

1. **Launch the app** - A waveform icon will appear in your menu bar
2. **Wait for auto-download** - The base model (142 MB) downloads automatically on first launch
3. **Grant permissions** - Allow Microphone and Accessibility access when prompted
4. **You're ready!** - Press Ctrl twice from anywhere to start recording

### Using the Global Hotkey (Recommended)

The fastest way to transcribe:

1. **Start recording** - Press Ctrl key twice quickly (anywhere in macOS)
2. **Speak** - Say what you want to transcribe
3. **Stop & transcribe** - Press Ctrl twice again
4. **Done!** - Text appears at your cursor and is copied to clipboard

**Example:** Writing an email? Click in the email body, press Ctrl+Ctrl, speak your message, press Ctrl+Ctrl again. The transcribed text appears in your email!

### Using the Menu Bar App

1. **Click the menu bar icon**
2. **Click "Record"** and speak
3. **Click "Stop Recording"** when done
4. **Copy to clipboard** to use the text elsewhere

### Transcribing Files

1. **Drag & drop** an audio file into the main window
2. **Wait** for processing (varies by file length and model size)
3. **Copy or export** the transcription

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

- **Ctrl+Ctrl** (anywhere in macOS) - Start/stop recording with auto-insert at cursor
- `⌘+C` - Copy transcription
- `⌘+,` - Settings (coming soon)
- `⌘+H` - Show history (coming soon)

### Global Hotkey Setup

The global hotkey (Ctrl+Ctrl) requires **Accessibility permissions**:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Enable **WhisperMac**
3. You may need to restart the app

Once enabled, you can:
- Record from any application
- Have text automatically inserted at your cursor
- Text is also copied to clipboard as backup

## Roadmap

- [x] Core transcription functionality
- [x] Menu bar app interface
- [x] Full window interface
- [x] Model management with auto-download
- [x] History with search
- [x] Export functionality
- [x] Global hotkey (Ctrl+Ctrl) for quick recording
- [x] Text insertion at cursor position
- [x] Audio/visual feedback notifications
- [ ] Streaming transcription (real-time results)
- [ ] Custom vocabulary support
- [ ] Speaker diarization
- [ ] Timestamp display
- [ ] Additional keyboard shortcuts
- [ ] Dark/light mode customization
- [ ] Configurable hotkey (currently Ctrl+Ctrl)
- [ ] App Store distribution

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for development setup.

## Troubleshooting

**App doesn't appear in menu bar:**
- Check that `LSUIElement` is set in Info.plist
- Restart the app

**Global hotkey (Ctrl+Ctrl) not working:**
- Enable Accessibility permissions: System Settings → Privacy & Security → Accessibility → Enable WhisperMac
- Make sure the hotkey is enabled in Settings
- Restart the app after granting permissions
- Check if another app is using the same hotkey

**Text not inserting at cursor:**
- Enable Accessibility permissions (see above)
- The text is always copied to clipboard as a backup - use Cmd+V to paste
- Make sure you're focused in a text input field

**Microphone not working:**
- System Settings → Privacy & Security → Microphone
- Enable permission for WhisperMac

**Model didn't auto-download on first launch:**
- Check internet connection
- Go to Settings and manually download the base model
- Check ~/Library/Application Support/WhisperMac/models/

**Poor transcription quality:**
- Try a larger model (small or medium)
- Ensure good audio quality (clear voice, minimal background noise)
- Check microphone input levels
- Speak clearly and avoid background noise

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
